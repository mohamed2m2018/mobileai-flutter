import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileai_flutter/mobileai_flutter.dart';

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
  group('SliderTool', () {
    test('definition has correct name and description', () {
      final tool = SliderTool();

      expect(tool.definition.name, 'adjust_slider');
      expect(tool.definition.description, contains('slider'));
      expect(tool.definition.parameters['index'], isNotNull);
      expect(tool.definition.parameters['value'], isNotNull);
    });

    testWidgets('requires index and value parameters', (WidgetTester tester) async {
      final tool = SliderTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.slider,
          label: 'Volume Slider',
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
      final tool = SliderTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.slider,
          label: 'Volume Slider',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      final result = tool.execute({'index': 999, 'value': 0.5}, context);
      await expectLater(
        result,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('STALE_TARGET'),
        )),
      );
    });

    testWidgets('throws for wrong element type', (WidgetTester tester) async {
      final tool = SliderTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Button',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      expect(
        () => tool.execute({'index': 0, 'value': 0.5}, context),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('not a slider'),
        )),
      );
    });

    testWidgets('accepts valid value range', (WidgetTester tester) async {
      final tool = SliderTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.slider,
          label: 'Volume Slider',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      for (final value in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        try {
          await tool.execute({'index': 0, 'value': value}, context);
        } catch (e) {
          expect(e.toString(), isNot(contains('Missing required')));
        }
      }
    });

    testWidgets('clamps value to 0-1 range', (WidgetTester tester) async {
      final tool = SliderTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.slider,
          label: 'Volume Slider',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      try {
        await tool.execute({'index': 0, 'value': -0.5}, context);
      } catch (e) {
        expect(e.toString(), isNot(contains('Missing required')));
      }

      try {
        await tool.execute({'index': 0, 'value': 1.5}, context);
      } catch (e) {
        expect(e.toString(), isNot(contains('Missing required')));
      }
    });
  });
}
