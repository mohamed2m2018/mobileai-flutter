# Rich UI

MobileAI Flutter can render structured assistant responses as text and app-defined blocks.

## Built-In Blocks

Built-in blocks registered by default:

- `FactCard`
- `ProductCard`
- `ActionCard`
- `ComparisonCard`
- `FormCard`

## Custom Blocks

Register custom blocks globally or per zone.

```dart
BlockDefinition(
  name: 'CheckoutHint',
  allowedPlacements: const [BlockPlacement.zone],
  builder: (context, props) => Container(
    padding: const EdgeInsets.all(12),
    child: Text('${props['text'] ?? ''}'),
  ),
)
```

## `AIZone`

Use `AIZone` to define a local surface where the assistant may guide, simplify, restore, or render blocks when the runtime mode allows it.

```dart
AIZone(
  id: 'pricing-summary',
  allowSimplify: true,
  allowInjectBlock: true,
  interventionEligible: true,
  child: const PricingTable(),
)
```

Companion mode blocks zone modification tools. Copilot and autopilot can use them when the zone grants permission.

## Custom Zone Blocks

```dart
AIZone(
  id: 'checkout-help',
  allowInjectBlock: true,
  blocks: [
    BlockDefinition(
      name: 'CheckoutHint',
      allowedPlacements: const [BlockPlacement.zone],
      builder: (context, props) => Text('${props['text'] ?? ''}'),
    ),
  ],
  child: const CheckoutScreen(),
)
```

## `RichContentRenderer`

Use `RichContentRenderer` when you build a custom chat surface and want to render assistant messages yourself.

```dart
RichContentRenderer(
  content: message.content,
)
```

## Theme Layers

Two theme layers are available:

- `theme` for the chat shell.
- `richUiTheme` for rich chat blocks and `AIZone` surfaces.

```dart
AIAgent(
  theme: const AgentChatBarTheme(
    primaryColor: Color(0xFF2563EB),
  ),
  richUiTheme: RichUiTheme.defaults(),
  child: MaterialApp.router(routerConfig: router),
)
```

## Guidance

- Use chat blocks for summaries, support facts, recommendations, and comparisons.
- Use zones when local placement reduces user effort.
- Keep block props structured and small.
- Do not use rich UI to bypass app permissions. Sensitive effects should still run through app code and runtime guardrails.
