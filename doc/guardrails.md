# Guardrails

MobileAI Flutter is designed as delegated assistance, not user impersonation. The assistant can propose actions, but runtime code owns execution.

## Safety Layers

| Layer | Purpose |
| --- | --- |
| Consent | Require user opt-in before the assistant sends app context to an AI provider. |
| Interaction mode | `companion` guides without UI control, `copilot` performs approved actions, `autopilot` runs trusted low-risk automation. |
| Workflow approval | Copilot asks before UI-altering actions. |
| Semantic action safety | A guard classifier returns `allow`, `ask`, or `block` before generic UI/action tools run. |
| Interactive policy | `interactiveBlacklist` and `interactiveWhitelist` restrict targetable widgets. |
| Data masking | `transformScreenContent` can redact screen content before provider calls. |
| Outcome verification | Critical actions can be verified after execution. |

## Companion Mode

Companion mode is the safest interaction mode for user trust. The assistant can see the current screen and help the user understand what to do, but runtime blocks UI-effect tools.

Allowed in companion mode:

- Answering from visible screen content.
- Explaining confusing UI states.
- Giving step-by-step guidance for the user to perform.
- Querying knowledge with `query_knowledge` when configured.
- Querying app data registered through `AIData`.
- Calling non-UI support, reporting, or diagnostic tools when configured.

Blocked in companion mode:

- `tap`
- `type`
- `scroll`
- `keyboard`
- `navigate`
- `long_press`
- `adjust_slider`
- `select_picker`
- `set_date`
- `guide_user`
- `simplify_zone`
- `restore_zone`
- `render_block`
- `inject_card`

If the assistant tries to use one of these tools, the runtime blocks execution and returns a guidance-only message.

```dart
AIAgent(
  interactionMode: AppInteractionMode.companion,
  child: MaterialApp.router(routerConfig: router),
)
```

## Copilot Approval

Copilot mode is the default. UI-altering tools require workflow approval before execution.

```dart
AIAgent(
  interactionMode: AppInteractionMode.copilot,
  child: MaterialApp.router(routerConfig: router),
)
```

The approval flow is handled by the built-in chat UI. If you build a custom runtime integration, configure `onAskUser` and return `__APPROVAL_GRANTED__` only when the user explicitly approves.

## Semantic Action Safety

The acting AI does not execute tools directly. It proposes a tool call, then `AgentRuntime` runs action safety before any side effect.

The default classifier uses:

- the user's current request
- the current screen name and dehydrated screen content
- the target element label, type, index, and properties
- the tool name and args
- recent agent history
- optional `ToolEffect` metadata from `ToolDefinition` or `ActionDefinition`

The classifier returns a decision:

| Decision | Runtime behavior |
| --- | --- |
| `allow` | Continue when confidence is above `minConfidenceToAllow`. |
| `ask` | Show one approval prompt. If approved, remember the current scope/risk boundary for this task. |
| `block` | Prevent execution. The end user cannot override this; the assistant receives a safe error and should offer an alternative. |

Defaults:

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

Guard model selection:

| Acting provider | Default guard model |
| --- | --- |
| Gemini | `gemini-2.5-flash-lite` |
| OpenAI | `gpt-5.4-nano` |

Set `guardModel` to override the default model. Set `classifier` to a custom `ActionSafetyClassifier` to replace SDK classification. Set `classifier: false` only when you intentionally want to disable semantic classification; workflow approval, companion mode, masking, and interactive filtering still remain.

## Approval Reuse

Semantic approval is not stacked on top of workflow approval. If an `ask` decision is approved, that same prompt authorizes the current action. Routine approvals can be reused inside the same scope/risk boundary for the current task, so the user is not asked on every tap. High-impact actions can require fresh approval.

## Tool Effect Metadata

Use `effect` when registering app-owned actions or custom tools. This lets the runtime skip guard-model calls for known safe tools and require confirmation for known high-impact tools.

```dart
AIAction(
  action: ActionDefinition(
    name: 'export_demo_data',
    description: 'Export demo data for support review.',
    effect: ToolEffect.stateModify,
    parameters: const {},
    handler: (_) async => support.exportDemoData(),
  ),
  child: const SettingsScreen(),
)
```

Use stronger effects for stronger consequences:

- `ToolEffect.read`
- `ToolEffect.navigate`
- `ToolEffect.fill`
- `ToolEffect.select`
- `ToolEffect.stateModify`
- `ToolEffect.support`
- `ToolEffect.payment`
- `ToolEffect.commit`
- `ToolEffect.destructive`
- `ToolEffect.unknown`

## Developer Overrides

Use `overrideDecision` when app policy knows more than the generic classifier. Prefer semantic fields such as `capability`, `risk`, and `scope`; do not rely on button-label matching when avoidable.

```dart
AIAgent(
  actionSafety: ActionSafetyConfig(
    overrideDecision: (decision, context) {
      if (
        context.toolName == 'export_demo_data' &&
        decision.capability == ActionSafetyCapability.destructive
      ) {
        return decision.copyWith(
          decision: ActionSafetyDecisionKind.ask,
          reason: 'Demo export is allowed after confirmation.',
          userMessage: 'This exports demo data. Do you want me to continue?',
        );
      }

      return decision;
    },
  ),
  child: MaterialApp.router(routerConfig: router),
)
```

## Autopilot

Autopilot skips workflow approval for UI-altering tools.

```dart
AIAgent(
  interactionMode: AppInteractionMode.autopilot,
  child: MaterialApp.router(routerConfig: router),
)
```

Use it only for trusted low-risk workflows. Avoid it for payments, deletion, consent, account security, and regulated data flows.

## Masking Sensitive Data

Use `transformScreenContent` to redact data before it reaches the provider.

```dart
AIAgent(
  transformScreenContent: (content) async {
    return content
        .replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[ssn]')
        .replaceAll(RegExp(r'\b\d{4} \d{4} \d{4} \d{4}\b'), '[card number]');
  },
  child: MaterialApp.router(routerConfig: router),
)
```

## Interactive Filtering

Use `interactiveBlacklist` for controls the assistant must not target.

```dart
final deleteKey = GlobalKey();

AIAgent(
  interactiveBlacklist: [deleteKey],
  child: DeleteAccountButton(key: deleteKey),
)
```

Use `interactiveWhitelist` when the assistant should only interact with a known set of widgets.

## App-Owned Actions

Prefer `AIAction` for operations that should run through app code rather than UI tapping.

```dart
AIAction(
  action: ActionDefinition(
    name: 'report_late_order',
    description: 'Create a late-order report for support review.',
    effect: ToolEffect.support,
    parameters: const {},
    handler: (_) async => support.reportLateOrder(),
  ),
  child: const OrdersScreen(),
)
```
