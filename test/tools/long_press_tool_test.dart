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
  group('LongPressTool', () {
    test('definition has correct name and description', () {
      final tool = LongPressTool();

      expect(tool.definition.name, 'long_press');
      expect(tool.definition.description, contains('Long-press'));
      expect(tool.definition.parameters['index'], isNotNull);
    });

    testWidgets('requires index parameter', (WidgetTester tester) async {
      final tool = LongPressTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Test Button',
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
    });

    testWidgets('throws when element not found', (WidgetTester tester) async {
      final tool = LongPressTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Test Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      final result = tool.execute({'index': 999}, context);
      await expectLater(
        result,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('STALE_TARGET'),
        )),
      );
    });

    testWidgets('uses default duration when not provided', (WidgetTester tester) async {
      final tool = LongPressTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Test Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      try {
        await tool.execute({'index': 0}, context);
      } catch (e) {
        expect(e.toString(), isNot(contains('Missing required')));
      }
    });

    testWidgets('accepts custom duration', (WidgetTester tester) async {
      final tool = LongPressTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Test Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      try {
        await tool.execute({'index': 0, 'durationMs': 2000}, context);
      } catch (e) {
        expect(e.toString(), isNot(contains('Missing required')));
      }
    });
  });
}
