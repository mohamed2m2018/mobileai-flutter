# API Reference

This page summarizes the main public APIs exported by `package:twomilia_flutter/twomilia_flutter.dart`.

## `AIAgent`

`AIAgent` wraps your app and provides the assistant runtime, chat UI, screen inspection, navigation access, guardrails, registered actions, app data, and support features.

```dart
AIAgent(
  apiKey: apiKey,
  router: router,
  child: MaterialApp.router(routerConfig: router),
)
```

## Core Props

| Prop | Type | Notes |
| --- | --- | --- |
| `apiKey` | `String?` | Local prototyping only. Prefer `proxyUrl` in production. |
| `provider` | `AiProvider?` | Custom provider instance. |
| `proxyUrl` | `String?` | Backend proxy URL for production provider calls. |
| `proxyHeaders` | `Map<String, String>?` | Headers sent to `proxyUrl`. |
| `model` | `String?` | Provider-specific model name. |
| `router` | `dynamic` | `GoRouter` instance. |
| `routerAdapter` | `FlutterRouterAdapter?` | Custom route adapter. |
| `navigatorKey` | `GlobalKey<NavigatorState>?` | Navigator integration. |
| `screenMap` | `ScreenMap?` | Generated route/screen hint map. |
| `maxSteps` | `int` | Default: `15`. |
| `instructions` | `String?` | App-specific assistant instructions. |
| `language` | `String` | Default: `'en'`. |
| `interactionMode` | `AppInteractionMode` | Default: `AppInteractionMode.copilot`. |
| `actionSafety` | `ActionSafetyConfig` | Default semantic guardrails for copilot actions. |
| `enableUiControl` | `bool` | Disable UI-control tools when `false`. |
| `transformScreenContent` | `Future<String> Function(String)?` | Redact or rewrite screen content before provider calls. |

## Interaction Modes

| Mode | Runtime behavior |
| --- | --- |
| `AppInteractionMode.companion` | Registers guidance/data/support tools and blocks UI-effect tools such as `tap`, `type`, `scroll`, `navigate`, `guide_user`, and zone rendering tools. |
| `AppInteractionMode.copilot` | Registers UI tools and enforces workflow approval plus semantic action safety before UI-altering actions. |
| `AppInteractionMode.autopilot` | Registers UI tools without workflow approval. Semantic action safety still runs unless disabled. Use only for trusted low-risk workflows. |

## Action Safety

`ActionSafetyConfig` controls the runtime safety gate that runs before side-effecting tools.

```dart
AIAgent(
  actionSafety: const ActionSafetyConfig(
    enabled: true,
    classifier: ActionSafetyClassifierSetting.defaultClassifier,
    guardModel: 'auto',
    classifierTimeout: Duration(milliseconds: 300),
    minConfidenceToAllow: 0.75,
    unknownActionDecision: ActionSafetyDecisionKind.ask,
    approvalReuse: ActionSafetyApprovalReuse.riskBoundary,
    allowUserOverrideForAsk: true,
  ),
  child: MaterialApp.router(routerConfig: router),
)
```

| Field | Type | Default |
| --- | --- | --- |
| `enabled` | `bool` | `true` |
| `classifier` | `Object?` | `ActionSafetyClassifierSetting.defaultClassifier` |
| `guardModel` | `String` | `'auto'` |
| `classifierTimeout` | `Duration` | `300ms` |
| `minConfidenceToAllow` | `double` | `0.75` |
| `unknownActionDecision` | `ActionSafetyDecisionKind` | `ask` |
| `approvalReuse` | `ActionSafetyApprovalReuse` | `riskBoundary` |
| `allowUserOverrideForAsk` | `bool` | `true` |
| `overrideDecision` | `ActionSafetyOverride?` | `null` |
| `onDecision` | `ActionSafetyDecisionCallback?` | `null` |

Default guard models:

- Gemini: `gemini-2.5-flash-lite`
- OpenAI: `gpt-5.4-nano`

`classifier` can be a custom `ActionSafetyClassifier`, `ActionSafetyClassifierSetting.defaultClassifier`, or `false`.

## UI And Theme

| Prop | Type | Notes |
| --- | --- | --- |
| `showChatBar` | `bool` | Default: `true`. |
| `accentColor` | `Color?` | Quick accent for the chat UI. |
| `theme` | `AgentChatBarTheme?` | Chat shell theme. |
| `richUiTheme` | `RichUiTheme?` | Rich block and zone theme. |
| `blockActionHandlers` | `Map<String, BlockActionHandler>` | Handlers for interactive rich blocks. |

## Safety And Persistence

| Prop | Type | Notes |
| --- | --- | --- |
| `consent` | `AIConsentConfig?` | Consent gate configuration. |
| `conversationPersistenceKey` | `String?` | Persist chat history locally. |
| `interactiveBlacklist` | `List<GlobalKey>?` | Widgets the assistant must not target. |
| `interactiveWhitelist` | `List<GlobalKey>?` | Widgets the assistant may target. |
| `maxTokenBudget` | `int?` | Stop when token budget is exceeded. |
| `maxCostUsd` | `double?` | Stop when estimated cost is exceeded. |

## Support, Telemetry, And Voice

| Prop | Type | Notes |
| --- | --- | --- |
| `telemetry` | `TelemetryConfig?` | Twomilia telemetry configuration. |
| `supportMode` | `SupportModeConfig` | Support assistant and escalation configuration. |
| `enableVoice` | `bool` | Enable voice mode surface. |
| `voiceProxyUrl` | `String?` | Voice WebSocket proxy URL. |
| `voiceProxyHeaders` | `Map<String, String>?` | Headers sent to `voiceProxyUrl`. |

## Lifecycle

| Prop | Type |
| --- | --- |
| `onResult` | `void Function(ExecutionResult result)?` |
| `onBeforeStep` | `Future<void> Function(int stepCount)?` |
| `onAfterStep` | `Future<void> Function(List<AgentStep> history)?` |
| `onStatusUpdate` | `void Function(String status)?` |

## `AIData`

Registers an app data source.

```dart
AIData(
  definition: DataDefinition(
    name: 'catalog',
    description: 'Returns product catalog information.',
    handler: (context) async => catalog.search(context.query),
  ),
  child: const CatalogScreen(),
)
```

## `AIAction`

Registers an app-owned action.

```dart
AIAction(
  action: ActionDefinition(
    name: 'apply_coupon',
    description: 'Apply a coupon to the cart.',
    effect: ToolEffect.stateModify,
    parameters: {
      'code': ActionParameterDef(
        type: 'string',
        description: 'Coupon code',
        required: true,
      ),
    },
    handler: (args) async => cart.applyCoupon(args['code'] as String),
  ),
  child: const CartScreen(),
)
```

## Controller

Use `context.ai` inside the `AIAgent` tree.

```dart
final agent = context.ai;

agent.send('Help me understand this screen');
agent.cancel();
agent.clearMessages();
agent.startNewConversation();
```

Controller state:

- `isRunning`
- `isAwaitingUserResponse`
- `status`
- `messages`
- `lastResult`

## Other Exports

The package also exports:

- Providers: `GeminiProvider`, `OpenAIProvider`, `createProvider`
- Navigation adapters: `GoRouterAdapter`, `NavigatorRouterAdapter`, `FlutterRouterAdapter`
- Rich UI: `RichContentRenderer`, built-in blocks, `AIZone`
- Services: `KnowledgeBaseService`, `ConversationService`, `VoiceService`
- Telemetry: `MobileAI`
- Support: `SupportModeConfig`, escalation tools, `CSATSurvey`
