import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileai_flutter/src/core/types.dart';
import 'package:mobileai_flutter/src/tools/types.dart';

void main() {
  group('stale target guard', () {
    Future<ToolContext> buildContext(
      WidgetTester tester, {
      required List<InteractiveElement> observed,
      Future<List<InteractiveElement>> Function()? getCurrentElements,
      String observedScreenName = 'Home',
      String currentScreenName = 'Home',
    }) async {
      const rootKey = Key('root');
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: rootKey),
        ),
      );

      return ToolContext(
        rootContext: tester.element(find.byKey(rootKey)),
        config: AgentConfig(),
        lastElements: observed,
        observedScreenName: observedScreenName,
        getCurrentElements: getCurrentElements,
        getCurrentScreenName: () => currentScreenName,
        getRouteNames: () => const <String>[],
      );
    }

    InteractiveElement element({
      required int index,
      required String label,
      ElementType type = ElementType.pressable,
      String? zoneId,
      Map<String, dynamic> properties = const <String, dynamic>{},
    }) {
      return InteractiveElement(
        index: index,
        type: type,
        label: label,
        zoneId: zoneId,
        properties: properties,
      );
    }

    testWidgets(
      'preserves old direct-index behavior without a fresh resolver',
      (tester) async {
        final observed = [element(index: 3, label: 'Icon Button')];
        final context = await buildContext(tester, observed: observed);

        final resolved = await context.resolveInteractiveElement(3);

        expect(resolved, same(observed.first));
      },
    );

    testWidgets('same index succeeds when identity is unchanged', (
      tester,
    ) async {
      final observed = [
        element(
          index: 3,
          label: 'Buy now',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final current = [
        element(
          index: 3,
          label: 'Buy now',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final context = await buildContext(
        tester,
        observed: observed,
        getCurrentElements: () async => current,
      );

      final resolved = await context.resolveInteractiveElement(
        3,
        actionName: 'tap',
      );

      expect(resolved, same(current.first));
    });

    testWidgets('dangerous same-index label mismatch is blocked', (
      tester,
    ) async {
      final observed = [
        element(
          index: 3,
          label: 'Buy now',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final current = [
        element(
          index: 3,
          label: 'Delete account',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final context = await buildContext(
        tester,
        observed: observed,
        getCurrentElements: () async => current,
      );

      await expectLater(
        context.resolveInteractiveElement(3, actionName: 'tap'),
        throwsA(
          isA<StaleTargetException>().having(
            (error) => error.toString(),
            'message',
            contains('STALE_TARGET'),
          ),
        ),
      );
    });

    testWidgets('relocates when an inserted element shifts the index', (
      tester,
    ) async {
      final observed = [
        element(
          index: 3,
          label: 'Buy now',
          zoneId: 'checkout',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final current = [
        element(
          index: 3,
          label: 'Promo image',
          zoneId: 'checkout',
          properties: const {'role': 'button', 'widgetType': 'GestureDetector'},
        ),
        element(
          index: 4,
          label: 'Buy now',
          zoneId: 'checkout',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final context = await buildContext(
        tester,
        observed: observed,
        getCurrentElements: () async => current,
      );

      final resolved = await context.resolveInteractiveElement(
        3,
        actionName: 'tap',
      );

      expect(resolved.index, 4);
      expect(resolved.label, 'Buy now');
    });

    testWidgets('blocks when relocation is ambiguous', (tester) async {
      final observed = [
        element(
          index: 3,
          label: 'Buy now',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final current = [
        element(
          index: 4,
          label: 'Buy now',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
        element(
          index: 5,
          label: 'Buy now',
          properties: const {'role': 'button', 'widgetType': 'ElevatedButton'},
        ),
      ];
      final context = await buildContext(
        tester,
        observed: observed,
        getCurrentElements: () async => current,
      );

      await expectLater(
        context.resolveInteractiveElement(3, actionName: 'tap'),
        throwsA(isA<StaleTargetException>()),
      );
    });

    testWidgets('matches without developer-authored IDs', (tester) async {
      final observed = [
        element(
          index: 3,
          label: 'Buy now',
          zoneId: 'checkout',
          properties: const {
            'role': 'button',
            'widgetType': 'ElevatedButton',
            'enabled': true,
          },
        ),
      ];
      final current = [
        element(
          index: 4,
          label: 'Buy now',
          zoneId: 'checkout',
          properties: const {
            'role': 'button',
            'widgetType': 'ElevatedButton',
            'enabled': true,
          },
        ),
      ];
      final context = await buildContext(
        tester,
        observed: observed,
        getCurrentElements: () async => current,
      );

      final resolved = await context.resolveInteractiveElement(3);

      expect(resolved.index, 4);
    });

    testWidgets('blocks when the screen changes before execution', (
      tester,
    ) async {
      final context = await buildContext(
        tester,
        observed: [element(index: 3, label: 'Buy now')],
        observedScreenName: 'Checkout',
        currentScreenName: 'Settings',
        getCurrentElements: () async => [element(index: 3, label: 'Buy now')],
      );

      await expectLater(
        context.resolveInteractiveElement(3, actionName: 'tap'),
        throwsA(
          isA<StaleTargetException>().having(
            (error) => error.toString(),
            'message',
            contains('screen changed'),
          ),
        ),
      );
    });
  });
}
