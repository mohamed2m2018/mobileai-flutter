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
  group('DatePickerTool', () {
    test('definition has correct name and description', () {
      final tool = DatePickerTool();

      expect(tool.definition.name, 'set_date');
      expect(tool.definition.description, contains('date'));
      expect(tool.definition.description, contains('ISO 8601'));
      expect(tool.definition.parameters['index'], isNotNull);
      expect(tool.definition.parameters['date'], isNotNull);
    });

    testWidgets('requires index and date parameters', (WidgetTester tester) async {
      final tool = DatePickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.datePicker,
          label: 'Birth Date',
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
      final tool = DatePickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.datePicker,
          label: 'Birth Date',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      final result = tool.execute({'index': 999, 'date': '2025-03-25'}, context);
      await expectLater(
        result,
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('STALE_TARGET'),
        )),
      );
    });

    testWidgets('accepts valid ISO 8601 date formats', (WidgetTester tester) async {
      final tool = DatePickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.datePicker,
          label: 'Birth Date',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      final validDates = [
        '2025-03-25',
        '2025-03-25T14:30:00',
        '2025-03-25T14:30:00Z',
        '2025-12-31',
      ];

      for (final date in validDates) {
        try {
          await tool.execute({'index': 0, 'date': date}, context);
        } catch (e) {
          // Should not be a format error
          expect(e.toString(), isNot(contains('Invalid date format')));
        }
      }
    });

    testWidgets('throws for invalid date formats', (WidgetTester tester) async {
      final tool = DatePickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.datePicker,
          label: 'Birth Date',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      final invalidDates = [
        'not-a-date',
        '2025-13-01', // Invalid month
        '2025-02-30', // Invalid day
        '25-03-2025', // Wrong format
      ];

      for (final date in invalidDates) {
        expect(
          () => tool.execute({'index': 0, 'date': date}, context),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid date format'),
          )),
        );
      }
    });

    testWidgets('throws for empty date string', (WidgetTester tester) async {
      final tool = DatePickerTool();
      final testContext = await _pumpContext(tester);
      final testElements = [
        InteractiveElement(
          index: 0,
          type: ElementType.datePicker,
          label: 'Birth Date',
          element: null,
        ),
      ];
      final context = ToolContext(
        rootContext: testContext,
        lastElements: testElements,
      );

      expect(
        () => tool.execute({'index': 0, 'date': ''}, context),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('cannot be empty'),
        )),
      );
    });
  });
}
