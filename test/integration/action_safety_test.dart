import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileai_flutter/mobileai_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Action safety guardrails', () {
    late GlobalKey rootKey;
    late AgentRuntime runtime;

    setUp(() {
      rootKey = GlobalKey();
    });

    tearDown(() {
      runtime.dispose();
    });

    test('known read-only tools skip the classifier', () async {
      final classifier = _FakeClassifier(actionDecision: _allow());
      runtime = AgentRuntime(
        provider: _DoneProvider(),
        rootKey: rootKey,
        config: AgentConfig(
          actionSafety: ActionSafetyConfig(classifier: classifier),
        ),
      );

      final result = await runtime.executeTool('wait', {'seconds': 0});

      expect(result, contains('Waited'));
      expect(classifier.classifyActionCount, 0);
    });

    test('cached preclassified block prevents tool execution', () async {
      final classifier = _FakeClassifier(
        screenDecisions: {
          0: const ActionSafetyDecision(
            decision: ActionSafetyDecisionKind.block,
            reason: 'Destructive action is outside this request.',
            userMessage: 'I cannot do that.',
            capability: ActionSafetyCapability.destructive,
            scope: ActionSafetyScope.accountManagement,
            risk: ActionSafetyRisk.critical,
          ),
        },
      );
      runtime = AgentRuntime(
        provider: _TapThenDoneProvider(),
        rootKey: rootKey,
        config: AgentConfig(
          platformAdapter: const _SnapshotPlatformAdapter(),
          actionSafety: ActionSafetyConfig(classifier: classifier),
        ),
      );

      final result = await runtime.execute('delete account');

      expect(result.success, isTrue);
      expect(result.steps.first.result, contains('SAFETY_BLOCKED'));
      expect(classifier.classifyActionCount, 0);
    });

    test('fallback classifier timeout becomes ask', () async {
      var approvals = 0;
      var executions = 0;
      final classifier = _FakeClassifier(
        actionDecision: _allow(),
        actionDelay: const Duration(seconds: 1),
      );
      runtime = AgentRuntime(
        provider: _DoneProvider(),
        rootKey: rootKey,
        config: AgentConfig(
          customTools: {
            'custom_unknown': ToolDefinition(
              name: 'custom_unknown',
              description: 'Unknown side effect.',
              parameters: const {},
              handler: (_) async {
                executions++;
                return 'ok';
              },
            ),
          },
          actionSafety: ActionSafetyConfig(
            classifier: classifier,
            classifierTimeout: const Duration(milliseconds: 10),
          ),
          onAskUser: (_) async {
            approvals++;
            return '__APPROVAL_GRANTED__';
          },
        ),
      );

      final result = await runtime.executeTool('custom_unknown', {});

      expect(result, 'ok');
      expect(approvals, 1);
      expect(executions, 1);
    });

    test('low-confidence allow becomes ask', () async {
      var approvals = 0;
      final classifier = _FakeClassifier(
        actionDecision: _allow(confidence: 0.2),
      );
      runtime = AgentRuntime(
        provider: _DoneProvider(),
        rootKey: rootKey,
        config: AgentConfig(
          customTools: {
            'custom_unknown': ToolDefinition(
              name: 'custom_unknown',
              description: 'Unknown side effect.',
              parameters: const {},
              handler: (_) async => 'ok',
            ),
          },
          actionSafety: ActionSafetyConfig(classifier: classifier),
          onAskUser: (_) async {
            approvals++;
            return '__APPROVAL_GRANTED__';
          },
        ),
      );

      final result = await runtime.executeTool('custom_unknown', {});

      expect(result, 'ok');
      expect(approvals, 1);
    });

    test('block cannot be overridden by user approval', () async {
      var executions = 0;
      var approvals = 0;
      final classifier = _FakeClassifier(
        actionDecision: const ActionSafetyDecision(
          decision: ActionSafetyDecisionKind.block,
          reason: 'Blocked by policy.',
          userMessage: 'This is blocked.',
          capability: ActionSafetyCapability.destructive,
          scope: ActionSafetyScope.accountManagement,
          risk: ActionSafetyRisk.critical,
        ),
      );
      runtime = AgentRuntime(
        provider: _DoneProvider(),
        rootKey: rootKey,
        config: AgentConfig(
          customTools: {
            'custom_unknown': ToolDefinition(
              name: 'custom_unknown',
              description: 'Unknown side effect.',
              parameters: const {},
              handler: (_) async {
                executions++;
                return 'ok';
              },
            ),
          },
          actionSafety: ActionSafetyConfig(classifier: classifier),
          onAskUser: (_) async {
            approvals++;
            return '__APPROVAL_GRANTED__';
          },
        ),
      );

      final result = await runtime.executeTool('custom_unknown', {});

      expect(result, contains('SAFETY_BLOCKED'));
      expect(approvals, 0);
      expect(executions, 0);
    });

    test('developer override can change block to ask', () async {
      var approvals = 0;
      var executions = 0;
      final classifier = _FakeClassifier(
        actionDecision: const ActionSafetyDecision(
          decision: ActionSafetyDecisionKind.block,
          reason: 'Blocked by default.',
          capability: ActionSafetyCapability.destructive,
          scope: ActionSafetyScope.accountManagement,
          risk: ActionSafetyRisk.critical,
        ),
      );
      runtime = AgentRuntime(
        provider: _DoneProvider(),
        rootKey: rootKey,
        config: AgentConfig(
          customTools: {
            'export_demo_data': ToolDefinition(
              name: 'export_demo_data',
              description: 'Export demo data.',
              parameters: const {},
              handler: (_) async {
                executions++;
                return 'exported';
              },
            ),
          },
          actionSafety: ActionSafetyConfig(
            classifier: classifier,
            overrideDecision: (decision, context) {
              if (context.toolName == 'export_demo_data' &&
                  decision.capability == ActionSafetyCapability.destructive) {
                return decision.copyWith(
                  decision: ActionSafetyDecisionKind.ask,
                  reason: 'Demo export is allowed after confirmation.',
                  userMessage:
                      'This exports demo data. Do you want me to continue?',
                );
              }
              return decision;
            },
          ),
          onAskUser: (_) async {
            approvals++;
            return '__APPROVAL_GRANTED__';
          },
        ),
      );

      final result = await runtime.executeTool('export_demo_data', {});

      expect(result, 'exported');
      expect(approvals, 1);
      expect(executions, 1);
    });

    test('classifier false disables semantic classifier only', () async {
      var executions = 0;
      runtime = AgentRuntime(
        provider: _DoneProvider(),
        rootKey: rootKey,
        config: AgentConfig(
          customTools: {
            'custom_unknown': ToolDefinition(
              name: 'custom_unknown',
              description: 'Unknown side effect.',
              parameters: const {},
              handler: (_) async {
                executions++;
                return 'ok';
              },
            ),
          },
          actionSafety: const ActionSafetyConfig(classifier: false),
        ),
      );

      final result = await runtime.executeTool('custom_unknown', {});

      expect(result, 'ok');
      expect(executions, 1);
    });
  });
}

ActionSafetyDecision _allow({double confidence = 0.9}) {
  return ActionSafetyDecision(
    decision: ActionSafetyDecisionKind.allow,
    confidence: confidence,
    reason: 'Allowed by fake classifier.',
    capability: ActionSafetyCapability.uiNavigate,
    scope: ActionSafetyScope.readOrLookup,
    risk: ActionSafetyRisk.low,
  );
}

class _FakeClassifier implements ActionSafetyClassifier {
  final Map<int, ActionSafetyDecision> screenDecisions;
  final ActionSafetyDecision actionDecision;
  final Duration actionDelay;
  int classifyScreenCount = 0;
  int classifyActionCount = 0;

  _FakeClassifier({
    this.screenDecisions = const {},
    ActionSafetyDecision? actionDecision,
    this.actionDelay = Duration.zero,
  }) : actionDecision = actionDecision ?? _allow();

  @override
  Future<ScreenSafetyMap> classifyScreen(ScreenSafetyInput input) async {
    classifyScreenCount++;
    return ScreenSafetyMap(
      screenSignature: input.screenSignature,
      decisions: screenDecisions,
    );
  }

  @override
  Future<ActionSafetyDecision> classifyAction(ActionSafetyInput input) async {
    classifyActionCount++;
    if (actionDelay > Duration.zero) {
      await Future<void>.delayed(actionDelay);
    }
    return actionDecision;
  }
}

class _DoneProvider extends AiProvider {
  @override
  Future<ProviderResult> generateContent({
    required String systemPrompt,
    required String userMessage,
    required List<ToolDefinition> tools,
    required List<AgentStep> history,
    String? screenshotBase64,
    List<UserImage>? userImages,
  }) async {
    return ProviderResult(
      actionName: 'done',
      actionParams: const {'success': true, 'text': 'done'},
    );
  }
}

class _TapThenDoneProvider extends AiProvider {
  int calls = 0;

  @override
  Future<ProviderResult> generateContent({
    required String systemPrompt,
    required String userMessage,
    required List<ToolDefinition> tools,
    required List<AgentStep> history,
    String? screenshotBase64,
    List<UserImage>? userImages,
  }) async {
    calls++;
    if (calls == 1) {
      return ProviderResult(
        actionName: 'tap',
        actionParams: const {'index': 0},
      );
    }
    return ProviderResult(
      actionName: 'done',
      actionParams: const {'success': true, 'text': 'done'},
    );
  }
}

class _SnapshotPlatformAdapter implements PlatformAdapter {
  const _SnapshotPlatformAdapter();

  @override
  Future<ScreenSnapshot> getScreenSnapshot() async {
    return ScreenSnapshot(
      screenName: 'Settings',
      availableScreens: const ['Settings'],
      elementsText: '[0]<button>Delete account</button>',
      elements: [
        InteractiveElement(
          index: 0,
          type: ElementType.pressable,
          label: 'Delete account',
        ),
      ],
    );
  }

  @override
  NavigationSnapshot getNavigationSnapshot() {
    return const NavigationSnapshot(currentScreenName: 'Settings');
  }

  @override
  Future<String> executeAction(ActionIntent intent) async {
    return 'executed ${intent.action}';
  }

  @override
  Future<String?> captureScreenshot() async => null;
}
