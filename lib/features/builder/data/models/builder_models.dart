import '../../../../core/error/exceptions.dart';
import '../../domain/entities/builder.dart';

double asDouble(Object? value) => switch (value) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v) ?? 0,
      _ => 0,
    };

int asInt(Object? value) => switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

List<T> _parseItems<T>(List<dynamic>? list, T Function(Map<String, dynamic>) fromJson) =>
    list?.map((e) => fromJson(e as Map<String, dynamic>)).toList(growable: false) ?? const [];

class BuilderFormModel extends BuilderForm {
  const BuilderFormModel({
    required super.id,
    required super.title,
    super.description,
    super.fields = const <BuilderFormField>[],
    super.status = 'DRAFT',
    super.version = 1,
    super.createdAt,
    super.updatedAt,
  });

  factory BuilderFormModel.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id is! String) throw const ParseException('BuilderForm missing id');
    return BuilderFormModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      fields: _parseItems(json['fields'] as List<dynamic>?, BuilderFormFieldModel.fromJson),
      status: json['status'] as String? ?? 'DRAFT',
      version: asInt(json['version']),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'version': version,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class BuilderFormFieldModel extends BuilderFormField {
  const BuilderFormFieldModel({
    required super.id,
    required super.label,
    required super.fieldType,
    super.required = false,
    super.placeholder,
    super.options = const <String>[],
    super.defaultValue,
    super.order = 0,
  });

  factory BuilderFormFieldModel.fromJson(Map<String, dynamic> json) =>
      BuilderFormFieldModel(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        fieldType: json['fieldType'] as String? ?? 'text',
        required: json['required'] as bool? ?? false,
        placeholder: json['placeholder'] as String?,
        options: (json['options'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList(growable: false) ??
            const [],
        defaultValue: json['defaultValue'] as String?,
        order: asInt(json['order']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'fieldType': fieldType,
        'required': required,
        'placeholder': placeholder,
        'options': options,
        'defaultValue': defaultValue,
        'order': order,
      };
}

class BuilderPageModel extends BuilderPage {
  const BuilderPageModel({
    required super.id,
    required super.title,
    super.slug,
    super.layout = 'default',
    super.sections = const <BuilderPageSection>[],
    super.status = 'DRAFT',
    super.createdAt,
    super.updatedAt,
  });

  factory BuilderPageModel.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id is! String) throw const ParseException('BuilderPage missing id');
    return BuilderPageModel(
      id: id,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String?,
      layout: json['layout'] as String? ?? 'default',
      sections: _parseItems(json['sections'] as List<dynamic>?, BuilderPageSectionModel.fromJson),
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'slug': slug,
        'layout': layout,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class BuilderPageSectionModel extends BuilderPageSection {
  const BuilderPageSectionModel({
    required super.id,
    required super.type,
    super.title,
    super.content,
    super.order = 0,
  });

  factory BuilderPageSectionModel.fromJson(Map<String, dynamic> json) =>
      BuilderPageSectionModel(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'content',
        title: json['title'] as String?,
        content: json['content'] as String?,
        order: asInt(json['order']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'title': title,
        'content': content,
        'order': order,
      };
}

class BuilderWorkflowModel extends BuilderWorkflow {
  const BuilderWorkflowModel({
    required super.id,
    required super.name,
    super.description,
    super.steps = const <BuilderWorkflowStep>[],
    super.status = 'DRAFT',
    super.createdAt,
    super.updatedAt,
  });

  factory BuilderWorkflowModel.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id is! String) throw const ParseException('BuilderWorkflow missing id');
    return BuilderWorkflowModel(
      id: id,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      steps: _parseItems(json['steps'] as List<dynamic>?, BuilderWorkflowStepModel.fromJson),
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class BuilderWorkflowStepModel extends BuilderWorkflowStep {
  const BuilderWorkflowStepModel({
    required super.id,
    required super.name,
    super.type = 'approval',
    super.assigneeRole,
    super.order = 0,
  });

  factory BuilderWorkflowStepModel.fromJson(Map<String, dynamic> json) =>
      BuilderWorkflowStepModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'approval',
        assigneeRole: json['assigneeRole'] as String?,
        order: asInt(json['order']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type,
        'assigneeRole': assigneeRole,
        'order': order,
      };
}

class BuilderTemplateModel extends BuilderTemplate {
  const BuilderTemplateModel({
    required super.id,
    required super.name,
    super.category,
    super.description,
    super.content,
    super.status = 'ACTIVE',
    super.createdAt,
    super.updatedAt,
  });

  factory BuilderTemplateModel.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id is! String) throw const ParseException('BuilderTemplate missing id');
    return BuilderTemplateModel(
      id: id,
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      description: json['description'] as String?,
      content: json['content'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'content': content,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

// ── Form runtime (published page-registry) ──────────────────────────────────

List<String> _asStringOptions(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .map((dynamic e) {
        if (e is String) return e;
        if (e is Map<String, dynamic>) {
          final Object? v = e['label'] ?? e['value'] ?? e['name'];
          return v?.toString() ?? '';
        }
        return e.toString();
      })
      .where((String s) => s.isNotEmpty)
      .toList(growable: false);
}

class FormRuntimeFieldModel extends FormRuntimeField {
  const FormRuntimeFieldModel({
    required super.id,
    required super.name,
    required super.type,
    required super.label,
    super.required = false,
    super.options = const <String>[],
  });

  factory FormRuntimeFieldModel.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String? ?? '';
    return FormRuntimeFieldModel(
      id: id,
      name: json['name'] as String? ?? id,
      // The field JSON may come from either the runtime `layout.fields`
      // shape (`type`) or, if a caller reuses admin field JSON, `fieldType`.
      type: (json['type'] as String?) ?? (json['fieldType'] as String?) ?? 'text',
      label: json['label'] as String? ?? '',
      required: json['required'] as bool? ?? false,
      options: _asStringOptions(json['options']),
    );
  }
}

class FormRuntimeStepModel extends FormRuntimeStep {
  const FormRuntimeStepModel({
    required super.id,
    required super.title,
    super.order = 0,
    super.fieldIds = const <String>[],
  });

  factory FormRuntimeStepModel.fromJson(Map<String, dynamic> json) =>
      FormRuntimeStepModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        order: asInt(json['order']),
        fieldIds: (json['fieldIds'] as List<dynamic>?)
                ?.map((dynamic e) => e.toString())
                .toList(growable: false) ??
            const <String>[],
      );
}

class FormRuntimeConditionModel extends FormRuntimeCondition {
  const FormRuntimeConditionModel({
    required super.fieldId,
    required super.operator,
    required super.value,
    required super.action,
    required super.targetFieldId,
  });

  factory FormRuntimeConditionModel.fromJson(Map<String, dynamic> json) =>
      FormRuntimeConditionModel(
        fieldId: json['fieldId'] as String? ?? '',
        operator: json['operator'] as String? ?? 'equals',
        value: json['value'],
        action: json['action'] as String? ?? 'show',
        targetFieldId: json['targetFieldId'] as String? ?? '',
      );
}

class FormRuntimeDefinitionModel extends FormRuntimeDefinition {
  const FormRuntimeDefinitionModel({
    required super.id,
    required super.module,
    required super.slug,
    required super.title,
    super.schemaId,
    super.fields = const <FormRuntimeField>[],
    super.steps = const <FormRuntimeStep>[],
    super.conditions = const <FormRuntimeCondition>[],
    super.status = 'DRAFT',
  });

  /// `json` is a PageRegistry row: `{ id, schemaId, module, slug, title,
  /// layout: { fields, pages, conditions, settings }, status, ... }`.
  factory FormRuntimeDefinitionModel.fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    if (id is! String) throw const ParseException('Published form missing id');

    final Object? rawLayout = json['layout'];
    final Map<String, dynamic> layout =
        rawLayout is Map<String, dynamic> ? rawLayout : const <String, dynamic>{};

    return FormRuntimeDefinitionModel(
      id: id,
      schemaId: json['schemaId'] as String?,
      module: json['module'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      fields: _parseItems(
        layout['fields'] as List<dynamic>?,
        FormRuntimeFieldModel.fromJson,
      ),
      steps: _parseItems(
        layout['pages'] as List<dynamic>?,
        FormRuntimeStepModel.fromJson,
      ),
      conditions: _parseItems(
        layout['conditions'] as List<dynamic>?,
        FormRuntimeConditionModel.fromJson,
      ),
    );
  }
}