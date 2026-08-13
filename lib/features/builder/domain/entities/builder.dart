import 'package:equatable/equatable.dart';

class BuilderForm extends Equatable {
  const BuilderForm({
    required this.id,
    required this.title,
    this.description,
    this.fields = const <BuilderFormField>[],
    this.status = 'DRAFT',
    this.version = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final List<BuilderFormField> fields;
  final String status;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => <Object?>[
        id, title, description, fields, status, version, createdAt, updatedAt,
      ];
}

class BuilderFormField extends Equatable {
  const BuilderFormField({
    required this.id,
    required this.label,
    required this.fieldType,
    this.required = false,
    this.placeholder,
    this.options = const <String>[],
    this.defaultValue,
    this.order = 0,
  });

  final String id;
  final String label;
  final String fieldType;
  final bool required;
  final String? placeholder;
  final List<String> options;
  final String? defaultValue;
  final int order;

  @override
  List<Object?> get props => <Object?>[
        id, label, fieldType, required, placeholder, options, defaultValue, order,
      ];
}

class BuilderPage extends Equatable {
  const BuilderPage({
    required this.id,
    required this.title,
    this.slug,
    this.layout = 'default',
    this.sections = const <BuilderPageSection>[],
    this.status = 'DRAFT',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? slug;
  final String layout;
  final List<BuilderPageSection> sections;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => <Object?>[
        id, title, slug, layout, sections, status, createdAt, updatedAt,
      ];
}

class BuilderPageSection extends Equatable {
  const BuilderPageSection({
    required this.id,
    required this.type,
    this.title,
    this.content,
    this.order = 0,
  });

  final String id;
  final String type;
  final String? title;
  final String? content;
  final int order;

  @override
  List<Object?> get props => <Object?>[id, type, title, content, order];
}

class BuilderWorkflow extends Equatable {
  const BuilderWorkflow({
    required this.id,
    required this.name,
    this.description,
    this.steps = const <BuilderWorkflowStep>[],
    this.status = 'DRAFT',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final List<BuilderWorkflowStep> steps;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => <Object?>[
        id, name, description, steps, status, createdAt, updatedAt,
      ];
}

class BuilderWorkflowStep extends Equatable {
  const BuilderWorkflowStep({
    required this.id,
    required this.name,
    this.type = 'approval',
    this.assigneeRole,
    this.order = 0,
  });

  final String id;
  final String name;
  final String type;
  final String? assigneeRole;
  final int order;

  @override
  List<Object?> get props => <Object?>[id, name, type, assigneeRole, order];
}

class BuilderTemplate extends Equatable {
  const BuilderTemplate({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.content,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? category;
  final String? description;
  final String? content;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => <Object?>[
        id, name, category, description, content, status, createdAt, updatedAt,
      ];
}

// ── Form runtime (published page-registry) ──────────────────────────────────
//
// Distinct from [BuilderForm] above: [BuilderForm] is the developer-side
// metadata record edited in the form builder; [FormRuntimeDefinition] is the
// *published* form a tenant end user fills out, fetched from
// `GET /builder/page-registries/:module/:slug`. Its `layout` JSON carries a
// flat `fields` array plus, in this phase, `pages` (wizard steps) and
// `conditions` (show/hide/enable/disable/require rules).

/// One data-entry field in a published form's flat `fields` array.
class FormRuntimeField extends Equatable {
  const FormRuntimeField({
    required this.id,
    required this.name,
    required this.type,
    required this.label,
    this.required = false,
    this.options = const <String>[],
  });

  final String id;

  /// The key this field's value is submitted under.
  final String name;

  /// text | number | select | date | checkbox | textarea (and unknown types
  /// fall back to a plain text field).
  final String type;
  final String label;
  final bool required;
  final List<String> options;

  @override
  List<Object?> get props => <Object?>[id, name, type, label, required, options];
}

/// One step of a multi-step form wizard. `fieldIds` reference [FormRuntimeField.id].
class FormRuntimeStep extends Equatable {
  const FormRuntimeStep({
    required this.id,
    required this.title,
    this.order = 0,
    this.fieldIds = const <String>[],
  });

  final String id;
  final String title;
  final int order;
  final List<String> fieldIds;

  @override
  List<Object?> get props => <Object?>[id, title, order, fieldIds];
}

/// A conditional-logic rule: when [fieldId]'s current value satisfies
/// [operator] against [value], apply [action] to [targetFieldId].
class FormRuntimeCondition extends Equatable {
  const FormRuntimeCondition({
    required this.fieldId,
    required this.operator,
    required this.value,
    required this.action,
    required this.targetFieldId,
  });

  /// The field whose current value is evaluated. References [FormRuntimeField.id].
  final String fieldId;

  /// equals | notEquals | contains | greaterThan | lessThan | isEmpty
  final String operator;
  final Object? value;

  /// show | hide | enable | disable | require
  final String action;

  /// The field the [action] applies to. References [FormRuntimeField.id].
  final String targetFieldId;

  @override
  List<Object?> get props =>
      <Object?>[fieldId, operator, value, action, targetFieldId];
}

class FormRuntimeDefinition extends Equatable {
  const FormRuntimeDefinition({
    required this.id,
    required this.module,
    required this.slug,
    required this.title,
    this.schemaId,
    this.fields = const <FormRuntimeField>[],
    this.steps = const <FormRuntimeStep>[],
    this.conditions = const <FormRuntimeCondition>[],
    this.status = 'DRAFT',
  });

  final String id;

  /// The backing SchemaRegistry id — submissions POST to
  /// `/builder/custom-records/:schemaId`. Null if the page has never been
  /// published with a data model behind it.
  final String? schemaId;
  final String module;
  final String slug;
  final String title;
  final List<FormRuntimeField> fields;

  /// Wizard steps. Empty means single-page: render [fields] in order.
  final List<FormRuntimeStep> steps;
  final List<FormRuntimeCondition> conditions;
  final String status;

  @override
  List<Object?> get props => <Object?>[
        id, schemaId, module, slug, title, fields, steps, conditions, status,
      ];
}