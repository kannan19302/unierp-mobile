import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/result.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/builder.dart';
import '../providers/builder_providers.dart';

/// Fetches a published form ([FormRuntimeDefinition]) by (module, slug) and
/// renders it for data entry, POSTing the completed submission on success.
///
/// This is the *runtime* renderer — as opposed to [BuilderFormDetailPage],
/// which is the admin metadata viewer for a form's own builder record.
class FormRuntimePage extends ConsumerWidget {
  const FormRuntimePage({required this.module, required this.slug, super.key});

  static const String routeName = 'builder-form-runtime';
  static const String routePath = 'run/:module/:slug';

  final String module;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({String module, String slug}) key = (module: module, slug: slug);
    final AsyncValue<FormRuntimeDefinition> defAsync =
        ref.watch(publishedFormProvider(key));

    return Scaffold(
      appBar: AppBar(
        title: Text(defAsync.valueOrNull?.title ?? 'Fill out form'),
      ),
      body: defAsync.when(
        loading: () => const LoadingView(),
        error: (Object error, StackTrace _) => FailureView(
          failure: error is Failure
              ? error
              : const ServerFailure('Could not load form.'),
          onRetry: () => ref.invalidate(publishedFormProvider(key)),
        ),
        data: (FormRuntimeDefinition definition) => FormRuntimeView(
          definition: definition,
          onSubmit: (Map<String, dynamic> data) {
            final String? schemaId = definition.schemaId;
            if (schemaId == null || schemaId.isEmpty) {
              return Future<Result<void>>.value(
                const Result<void>.err(
                  ValidationFailure(
                    'This form is not linked to a data model yet.',
                  ),
                ),
              );
            }
            return ref
                .read(builderRepositoryProvider)
                .submitFormRecord(schemaId, data);
          },
        ),
      ),
    );
  }
}

/// Internal per-field condition state, recomputed on every value change.
class _FieldRuntimeState {
  bool hidden = false;
  bool disabled = false;
  bool forcedRequired = false;
}

/// Renders a [FormRuntimeDefinition] as a real, usable data-entry form:
///
///  * one Flutter form field per declared type, honoring `required`;
///  * a single-page list when `definition.steps` is empty, or a multi-step
///    wizard (Next/Back, per-page validation) when it isn't;
///  * `definition.conditions` re-evaluated on every keystroke/selection —
///    `hide` removes the field from the tree, `disable` renders it
///    non-interactive, `require` adds it to the validation set even when the
///    field itself isn't statutorily required.
///
/// Exposed (not private) so it can be pumped directly in widget tests without
/// wiring the network/provider layer.
class FormRuntimeView extends StatefulWidget {
  const FormRuntimeView({
    required this.definition,
    required this.onSubmit,
    this.initialData = const <String, dynamic>{},
    super.key,
  });

  final FormRuntimeDefinition definition;
  final Future<Result<void>> Function(Map<String, dynamic> data) onSubmit;
  final Map<String, dynamic> initialData;

  @override
  State<FormRuntimeView> createState() => _FormRuntimeViewState();
}

class _FormRuntimeViewState extends State<FormRuntimeView> {
  late Map<String, dynamic> _formData;
  int _currentStep = 0;
  final Set<String> _errorFieldIds = <String>{};
  bool _isSubmitting = false;
  String? _submitError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _formData = <String, dynamic>{...widget.initialData};
  }

  List<FormRuntimeStep> get _steps {
    if (widget.definition.steps.isEmpty) {
      return <FormRuntimeStep>[
        FormRuntimeStep(
          id: '_single',
          title: widget.definition.title,
          fieldIds: widget.definition.fields
              .map((FormRuntimeField f) => f.id)
              .toList(),
        ),
      ];
    }
    final List<FormRuntimeStep> sorted =
        List<FormRuntimeStep>.of(widget.definition.steps)
          ..sort(
            (FormRuntimeStep a, FormRuntimeStep b) =>
                a.order.compareTo(b.order),
          );
    return sorted;
  }

  bool get _isMultiStep => widget.definition.steps.isNotEmpty;

  FormRuntimeField? _fieldById(String id) {
    for (final FormRuntimeField f in widget.definition.fields) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<FormRuntimeField> _fieldsForStep(FormRuntimeStep step) => step.fieldIds
      .map(_fieldById)
      .whereType<FormRuntimeField>()
      .toList(growable: false);

  /// Evaluates every condition against the current form values and returns
  /// the resulting show/enable/require state for each field, keyed by field id.
  Map<String, _FieldRuntimeState> _evaluateConditions() {
    final Map<String, _FieldRuntimeState> states = <String, _FieldRuntimeState>{
      for (final FormRuntimeField f in widget.definition.fields)
        f.id: _FieldRuntimeState(),
    };
    for (final FormRuntimeCondition condition in widget.definition.conditions) {
      final FormRuntimeField? trigger = _fieldById(condition.fieldId);
      final _FieldRuntimeState? target = states[condition.targetFieldId];
      if (trigger == null || target == null) continue;
      final Object? currentValue = _formData[trigger.name];
      if (!_matches(currentValue, condition.operator, condition.value)) {
        continue;
      }
      switch (condition.action) {
        case 'hide':
          target.hidden = true;
          break;
        case 'disable':
          target.disabled = true;
          break;
        case 'require':
          target.forcedRequired = true;
          break;
        case 'show':
        case 'enable':
          // The default state; nothing to flip unless another condition
          // already flipped it, and last-write-wins for conflicting rules on
          // the same target is an acceptable trade-off.
          break;
      }
    }
    return states;
  }

  static bool _matches(Object? current, String operator, Object? expected) {
    switch (operator) {
      case 'equals':
        return _stringOf(current) == _stringOf(expected);
      case 'notEquals':
        return _stringOf(current) != _stringOf(expected);
      case 'contains':
        return current != null &&
            _stringOf(current).contains(_stringOf(expected));
      case 'greaterThan':
        final double? a = double.tryParse(_stringOf(current));
        final double? b = double.tryParse(_stringOf(expected));
        return a != null && b != null && a > b;
      case 'lessThan':
        final double? a = double.tryParse(_stringOf(current));
        final double? b = double.tryParse(_stringOf(expected));
        return a != null && b != null && a < b;
      case 'isEmpty':
        return current == null || _stringOf(current).trim().isEmpty;
      default:
        return false;
    }
  }

  static String _stringOf(Object? value) => value?.toString() ?? '';

  void _onFieldChanged(String name, Object? value) {
    setState(() {
      _formData[name] = value;
      _errorFieldIds.clear();
      _submitError = null;
    });
  }

  bool _isEmpty(Object? value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }

  /// Validates [fields] against their current condition state; visible
  /// fields that are required (statutorily or via a `require` condition) and
  /// empty are collected into [_errorFieldIds]. Returns whether it passed.
  bool _validate(
    List<FormRuntimeField> fields,
    Map<String, _FieldRuntimeState> states,
  ) {
    final Set<String> invalid = <String>{};
    for (final FormRuntimeField field in fields) {
      final _FieldRuntimeState state = states[field.id]!;
      if (state.hidden) continue;
      final bool isRequired = field.required || state.forcedRequired;
      if (!isRequired) continue;
      if (_isEmpty(_formData[field.name])) invalid.add(field.id);
    }
    setState(() {
      _errorFieldIds
        ..clear()
        ..addAll(invalid);
    });
    return invalid.isEmpty;
  }

  void _handleNext(
    List<FormRuntimeField> currentFields,
    Map<String, _FieldRuntimeState> states,
  ) {
    if (!_validate(currentFields, states)) return;
    final List<FormRuntimeStep> steps = _steps;
    if (_currentStep < steps.length - 1) {
      setState(() => _currentStep += 1);
    } else {
      unawaited(_handleSubmit(states));
    }
  }

  void _handleBack() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  Future<void> _handleSubmit(Map<String, _FieldRuntimeState> states) async {
    // Validate every non-hidden field across the whole form (not just the
    // current page) so a `require` condition targeting a field on an earlier
    // page still blocks submission.
    if (!_validate(widget.definition.fields, states)) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    final Result<void> result =
        await widget.onSubmit(Map<String, dynamic>.from(_formData));
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      result.fold(
        (Failure failure) => _submitError = failure.message,
        (_) => _submitted = true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Palette t = context.tokens;
    final Map<String, _FieldRuntimeState> states = _evaluateConditions();

    if (widget.definition.fields.isEmpty) {
      return const EmptyView(
        title: 'This form has no fields',
        message: 'Ask the form owner to add fields in Builder Studio.',
      );
    }

    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.x8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.check_circle_outline,
                size: Spacing.x12,
                color: t.success,
              ),
              const SizedBox(height: Spacing.x4),
              Text('Submitted', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return _isMultiStep
        ? _buildWizard(context, states)
        : _buildSinglePage(context, states);
  }

  Widget _buildSinglePage(
    BuildContext context,
    Map<String, _FieldRuntimeState> states,
  ) {
    final List<FormRuntimeField> fields = widget.definition.fields;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.x4),
            children: <Widget>[
              for (final FormRuntimeField field in fields)
                _fieldSlot(context, field, states[field.id]!),
            ],
          ),
        ),
        _buildFooter(
          context,
          isLast: true,
          onPrimary: _isSubmitting ? null : () => _handleSubmit(states),
        ),
      ],
    );
  }

  Widget _buildWizard(
    BuildContext context,
    Map<String, _FieldRuntimeState> states,
  ) {
    final Palette t = context.tokens;
    final List<FormRuntimeStep> steps = _steps;
    final FormRuntimeStep step = steps[_currentStep];
    final List<FormRuntimeField> fields = _fieldsForStep(step);
    final bool isLast = _currentStep == steps.length - 1;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.x4,
            Spacing.x4,
            Spacing.x4,
            Spacing.x2,
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < steps.length; i++) ...<Widget>[
                CircleAvatar(
                  key: ValueKey<String>('step-indicator-$i'),
                  radius: 12,
                  backgroundColor: i <= _currentStep ? t.primary : t.bgSunken,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: TypeScale.xs,
                      color: i <= _currentStep ? t.onPrimary : t.textSecondary,
                    ),
                  ),
                ),
                if (i != steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < _currentStep ? t.primary : t.border,
                    ),
                  ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.x4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Step ${_currentStep + 1} of ${steps.length} — ${step.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey<int>(_currentStep),
            padding: const EdgeInsets.all(Spacing.x4),
            children: <Widget>[
              for (final FormRuntimeField field in fields)
                _fieldSlot(context, field, states[field.id]!),
            ],
          ),
        ),
        _buildFooter(
          context,
          isLast: isLast,
          onBack: _currentStep > 0 && !_isSubmitting ? _handleBack : null,
          onPrimary: _isSubmitting ? null : () => _handleNext(fields, states),
        ),
      ],
    );
  }

  Widget _fieldSlot(
    BuildContext context,
    FormRuntimeField field,
    _FieldRuntimeState state,
  ) {
    if (state.hidden) return const SizedBox.shrink();
    return Padding(
      key: ValueKey<String>('field-${field.id}'),
      padding: const EdgeInsets.only(bottom: Spacing.x3),
      child: _buildField(field, state),
    );
  }

  Widget _buildField(FormRuntimeField field, _FieldRuntimeState state) {
    final bool isRequired = field.required || state.forcedRequired;
    final bool enabled = !state.disabled;
    final String? errorText =
        _errorFieldIds.contains(field.id) ? 'This field is required' : null;

    switch (field.type) {
      case 'select':
        return UiDropdownField<String>(
          items: field.options,
          itemLabel: (String o) => o,
          selectedItem: _formData[field.name] as String?,
          label: field.label,
          errorText: errorText,
          isRequired: isRequired,
          enabled: enabled,
          onChanged: (String? v) => _onFieldChanged(field.name, v),
        );
      case 'date':
        return UiDatePickerField(
          selectedDate: _formData[field.name] as DateTime?,
          label: field.label,
          errorText: errorText,
          isRequired: isRequired,
          enabled: enabled,
          onChanged: (DateTime? v) => _onFieldChanged(field.name, v),
        );
      case 'checkbox':
        return UiSwitchField(
          label: field.label,
          value: (_formData[field.name] as bool?) ?? false,
          enabled: enabled,
          onChanged: (bool v) => _onFieldChanged(field.name, v),
        );
      case 'textarea':
        return UiTextAreaField(
          label: field.label,
          errorText: errorText,
          isRequired: isRequired,
          enabled: enabled,
          onChanged: (String v) => _onFieldChanged(field.name, v),
        );
      case 'number':
        return UiNumberField(
          label: field.label,
          errorText: errorText,
          isRequired: isRequired,
          enabled: enabled,
          onChanged: (String v) => _onFieldChanged(field.name, v),
        );
      default: // 'text' and any unrecognised type fall back to plain text.
        return UiTextField(
          label: field.label,
          errorText: errorText,
          isRequired: isRequired,
          enabled: enabled,
          onChanged: (String v) => _onFieldChanged(field.name, v),
        );
    }
  }

  Widget _buildFooter(
    BuildContext context, {
    required bool isLast,
    VoidCallback? onPrimary,
    VoidCallback? onBack,
  }) {
    final Palette t = context.tokens;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_submitError != null) ...<Widget>[
              Text(_submitError!, style: TextStyle(color: t.danger)),
              const SizedBox(height: Spacing.x2),
            ],
            Row(
              children: <Widget>[
                if (onBack != null) ...<Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: Spacing.x3),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimary,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLast ? 'Submit' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
