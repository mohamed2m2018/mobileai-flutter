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
  group('PickerTool', () {
    test('definition has correct name and description', () {
      final tool = PickerTool();

      expect(tool.definition.name, 'select_picker');
      expect(tool.definition.description, contains('picker'));
      expect(tool.definition.parameters['index'], isNotNull);
      expect(tool.definition.parameters['value'], isNotNull);
    });

    testWidgets('requires index and value parameters', (WidgetTester tester) async {
      final tool = PickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.picker,
          label: 'Country Picker',
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
      final tool = PickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.picker,
          label: 'Country Picker',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      final result = tool.execute({'index': 999, 'value': 'Egypt'}, context);
      await expectLater(
        result,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('STALE_TARGET'),
        )),
      );
    });

    testWidgets('throws for empty value', (WidgetTester tester) async {
      final tool = PickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.picker,
          label: 'Country Picker',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      expect(
        () => tool.execute({'index': 0, 'value': ''}, context),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('cannot be empty'),
        )),
      );
    });

    testWidgets('accepts valid value parameter', (WidgetTester tester) async {
      final tool = PickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.picker,
          label: 'Country Picker',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      try {
        await tool.execute({'index': 0, 'value': 'Egypt'}, context);
      } catch (e) {
        expect(e.toString(), isNot(contains('cannot be empty')));
      }
    });
  });
}
