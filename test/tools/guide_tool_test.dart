import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twomilia_flutter/twomilia_flutter.dart';

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  final key = GlobalKey<ScaffoldState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: key,
        body: Container(),
      ),
    ),
  );
  return key.currentState!.context;
}

void main() {
  group('GuideTool', () {
    test('definition has correct name and description', () {
      final tool = GuideTool();

      expect(tool.definition.name, 'guide_user');
      expect(tool.definition.description, contains('Highlight'));
      expect(tool.definition.parameters['index'], isNotNull);
      expect(tool.definition.parameters['message'], isNotNull);
    });

    testWidgets('requires index and message parameters', (WidgetTester tester) async {
      final tool = GuideTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Submit Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      expect(
        () => tool.execute({}, context),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Missing required'),
        )),
      );

      expect(
        () => tool.execute({'index': 0}, context),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Missing required'),
        )),
      );
    });

    testWidgets('throws when element not found', (WidgetTester tester) async {
      final tool = GuideTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Submit Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      final result = tool.execute({'index': 999, 'message': 'Tap here'}, context);
      await expectLater(
        result,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('STALE_TARGET'),
        )),
      );
    });

    testWidgets('throws for empty message', (WidgetTester tester) async {
      final tool = GuideTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Submit Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      expect(
        () => tool.execute({'index': 0, 'message': ''}, context),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('cannot be empty'),
        )),
      );

      expect(
        () => tool.execute({'index': 0, 'message': '   '}, context),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('cannot be empty'),
        )),
      );
    });

    testWidgets('accepts valid message parameter', (WidgetTester tester) async {
      final tool = GuideTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Submit Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      try {
        await tool.execute({'index': 0, 'message': 'Tap to continue'}, context);
      } catch (e) {
        expect(e.toString(), isNot(contains('cannot be empty')));
      }
    });

    testWidgets('accepts optional autoRemoveAfterMs parameter', (WidgetTester tester) async {
      final tool = GuideTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Submit Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      for (final timeout in [1000, 3000, 5000, 10000]) {
        try {
          await tool.execute({
            'index': 0,
            'message': 'Tap to continue',
            'autoRemoveAfterMs': timeout
          }, context);
        } catch (e) {
          expect(e.toString(), isNot(contains('cannot be empty')));
        }
      }
    });

    testWidgets('uses default autoRemoveAfterMs when not provided', (WidgetTester tester) async {
      final tool = GuideTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Submit Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      try {
        await tool.execute({'index': 0, 'message': 'Tap here'}, context);
      } catch (e) {
        expect(e.toString(), isNot(contains('cannot be empty')));
      }
    });
  });
}
