import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unerp_mobile/app/theme/app_theme.dart';
import 'package:unerp_mobile/core/error/failures.dart';
import 'package:unerp_mobile/core/usecase/result.dart';
import 'package:unerp_mobile/features/builder/domain/entities/builder.dart';
import 'package:unerp_mobile/features/builder/presentation/pages/form_runtime_page.dart';

/// Pumps a [FormRuntimeView] directly (no network/provider layer) so these
/// tests exercise the actual rendering + condition-evaluation + wizard logic
/// against a hand-built [FormRuntimeDefinition].
Future<void> _pump(
  WidgetTester tester, {
  required FormRuntimeDefinition definition,
  required Future<Result<void>> Function(Map<String, dynamic>) onSubmit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: FormRuntimeView(definition: definition, onSubmit: onSubmit),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enterText(
  WidgetTester tester,
  String fieldId,
  String text,
) async {
  final Finder field = find.descendant(
    of: find.byKey(ValueKey<String>('field-$fieldId')),
    matching: find.byType(TextFormField),
  );
  await tester.enterText(field, text);
  await tester.pump();
}

void main() {
  group('FormRuntimeView — conditions', () {
    testWidgets('a hide condition removes the target field from the tree', (
      WidgetTester tester,
    ) async {
      const FormRuntimeDefinition definition = FormRuntimeDefinition(
        id: 'f1',
        module: 'custom',
        slug: 'demo',
        title: 'Demo',
        fields: <FormRuntimeField>[
          FormRuntimeField(id: 'a', name: 'a', type: 'text', label: 'A'),
          FormRuntimeField(id: 'b', name: 'b', type: 'text', label: 'B'),
        ],
        conditions: <FormRuntimeCondition>[
          FormRuntimeCondition(
            fieldId: 'a',
            operator: 'equals',
            value: 'hide-b',
            action: 'hide',
            targetFieldId: 'b',
          ),
        ],
      );

      await _pump(
        tester,
        definition: definition,
        onSubmit: (_) async => const Result<void>.ok(null),
      );

      expect(find.byKey(const ValueKey<String>('field-b')), findsOneWidget);

      await _enterText(tester, 'a', 'hide-b');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('field-b')), findsNothing);
    });
  });

  group('FormRuntimeView — multi-step wizard', () {
    const FormRuntimeDefinition wizardDefinition = FormRuntimeDefinition(
      id: 'f2',
      module: 'custom',
      slug: 'wizard',
      title: 'Wizard',
      fields: <FormRuntimeField>[
        FormRuntimeField(
          id: 'x',
          name: 'x',
          type: 'text',
          label: 'X',
          required: true,
        ),
        FormRuntimeField(id: 'y', name: 'y', type: 'text', label: 'Y'),
      ],
      steps: <FormRuntimeStep>[
        FormRuntimeStep(
          id: 's1',
          title: 'Step 1',
          order: 0,
          fieldIds: <String>['x'],
        ),
        FormRuntimeStep(
          id: 's2',
          title: 'Step 2',
          order: 1,
          fieldIds: <String>['y'],
        ),
      ],
    );

    testWidgets(
        'Next is blocked when a required field on the current page is empty', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        definition: wizardDefinition,
        onSubmit: (_) async => const Result<void>.ok(null),
      );

      expect(find.byKey(const ValueKey<String>('field-y')), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Still on step 1: step 2's field never entered the tree, and the
      // empty required field is flagged.
      expect(find.byKey(const ValueKey<String>('field-y')), findsNothing);
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('Next advances to page 2 once the required field is filled', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        definition: wizardDefinition,
        onSubmit: (_) async => const Result<void>.ok(null),
      );

      await _enterText(tester, 'x', 'hello');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('field-y')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('field-x')), findsNothing);
    });
  });

  group('FormRuntimeView — submit', () {
    testWidgets('submit is blocked when a require-conditioned field is empty', (
      WidgetTester tester,
    ) async {
      const FormRuntimeDefinition definition = FormRuntimeDefinition(
        id: 'f3',
        module: 'custom',
        slug: 'require-demo',
        title: 'Require demo',
        fields: <FormRuntimeField>[
          FormRuntimeField(
            id: 'trigger',
            name: 'trigger',
            type: 'text',
            label: 'Trigger',
          ),
          FormRuntimeField(
            id: 'target',
            name: 'target',
            type: 'text',
            label: 'Target',
          ),
        ],
        conditions: <FormRuntimeCondition>[
          FormRuntimeCondition(
            fieldId: 'trigger',
            operator: 'equals',
            value: 'need',
            action: 'require',
            targetFieldId: 'target',
          ),
        ],
      );

      bool submitted = false;
      await _pump(
        tester,
        definition: definition,
        onSubmit: (Map<String, dynamic> data) async {
          submitted = true;
          return const Result<void>.ok(null);
        },
      );

      await _enterText(tester, 'trigger', 'need');
      // 'target' stays empty — it is not statutorily required, only made
      // required by the condition above.
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('submit succeeds once the require-conditioned field is filled',
        (
      WidgetTester tester,
    ) async {
      const FormRuntimeDefinition definition = FormRuntimeDefinition(
        id: 'f3',
        module: 'custom',
        slug: 'require-demo',
        title: 'Require demo',
        fields: <FormRuntimeField>[
          FormRuntimeField(
            id: 'trigger',
            name: 'trigger',
            type: 'text',
            label: 'Trigger',
          ),
          FormRuntimeField(
            id: 'target',
            name: 'target',
            type: 'text',
            label: 'Target',
          ),
        ],
        conditions: <FormRuntimeCondition>[
          FormRuntimeCondition(
            fieldId: 'trigger',
            operator: 'equals',
            value: 'need',
            action: 'require',
            targetFieldId: 'target',
          ),
        ],
      );

      Map<String, dynamic>? submittedData;
      await _pump(
        tester,
        definition: definition,
        onSubmit: (Map<String, dynamic> data) async {
          submittedData = data;
          return const Result<void>.ok(null);
        },
      );

      await _enterText(tester, 'trigger', 'need');
      await _enterText(tester, 'target', 'filled');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['trigger'], 'need');
      expect(submittedData!['target'], 'filled');
      expect(find.text('Submitted'), findsOneWidget);
    });

    testWidgets('surfaces a failure message when the repository submit fails', (
      WidgetTester tester,
    ) async {
      const FormRuntimeDefinition definition = FormRuntimeDefinition(
        id: 'f4',
        module: 'custom',
        slug: 'fail-demo',
        title: 'Fail demo',
        fields: <FormRuntimeField>[
          FormRuntimeField(id: 'a', name: 'a', type: 'text', label: 'A'),
        ],
      );

      await _pump(
        tester,
        definition: definition,
        onSubmit: (_) async =>
            const Result<void>.err(ServerFailure('Something went wrong.')),
      );

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong.'), findsOneWidget);
    });
  });
}
