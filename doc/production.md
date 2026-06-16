# Production

This page covers production setup for networking, telemetry, support, consent, and security.

## API Keys And Proxies

Do not ship provider API keys in your mobile app bundle.

Use `proxyUrl` and route provider calls through your backend.

```dart
AIAgent(
  proxyUrl: 'https://api.example.com/twomilia/chat',
  proxyHeaders: {'Authorization': 'Bearer $sessionToken'},
  child: MaterialApp.router(routerConfig: router),
)
```

For local development only:

```dart
AIAgent(
  apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  child: MaterialApp.router(routerConfig: router),
)
```

## Consent

Use `AIConsentConfig` to require explicit opt-in.

```dart
AIAgent(
  consent: const AIConsentConfig(
    required: true,
    persist: true,
    title: 'AI Assistant',
    providerLabel: 'Google Gemini',
  ),
  child: MaterialApp.router(routerConfig: router),
)
```

## Data Masking

Mask sensitive screen content before it reaches the provider.

```dart
AIAgent(
  transformScreenContent: (content) async {
    return content.replaceAll(
      RegExp(r'\b\d{4} \d{4} \d{4} \d{4}\b'),
      '[card number]',
    );
  },
  child: MaterialApp.router(routerConfig: router),
)
```

## Telemetry

Use `TelemetryConfig` to enable Twomilia Cloud analytics.

```dart
AIAgent(
  telemetry: const TelemetryConfig(
    enabled: true,
    analyticsKey: 'twomilia_pub_xxxxxxxx',
    baseUrl: 'https://twomilia.com',
  ),
  child: MaterialApp.router(routerConfig: router),
)
```

## Human Support

Configure support mode for support assistant behavior and escalation.

```dart
AIAgent(
  supportMode: SupportModeConfig(
    enabled: true,
    supportStyle: 'warm-concise',
    greetingMessage: 'Hi there. How can I help?',
    escalation: EscalationConfig(
      provider: EscalationProvider.custom,
      onEscalate: (context) async {
        await helpdesk.createTicket(context);
        return 'A support ticket has been created.';
      },
    ),
  ),
  child: MaterialApp.router(routerConfig: router),
)
```

## Recommended Guardrail Defaults

Use copilot for approved assistance.

```dart
AIAgent(
  interactionMode: AppInteractionMode.copilot,
  consent: const AIConsentConfig(required: true, persist: true),
  actionSafety: const ActionSafetyConfig(),
  child: MaterialApp.router(routerConfig: router),
)
```

The default action-safety classifier uses the same provider family as the acting model. If your app uses `proxyUrl`, make sure the proxy allows both the acting model and the guard model:

- Gemini guard model: `gemini-2.5-flash-lite`
- OpenAI guard model: `gpt-5.4-nano`

Unknown, low-confidence, timeout, or invalid classifier results become approval prompts instead of silent execution.

Use companion when the assistant should help without operating the app.

```dart
AIAgent(
  interactionMode: AppInteractionMode.companion,
  child: MaterialApp.router(routerConfig: router),
)
```

## Release Checklist

- Provider traffic goes through your backend proxy.
- Consent behavior matches your app policy.
- Sensitive fields are masked or excluded.
- Companion mode is used where guidance-only behavior is required.
- Copilot approval and semantic action safety are tested on UI-altering flows.
- App-owned actions declare `ToolEffect` metadata.
- High-risk actions require confirmation or are blocked by app policy.
- Navigation is configured through `router`, `routerAdapter`, or `navigatorKey`.
- Human escalation has been tested if support mode is enabled.
- `flutter analyze` and `flutter test` pass.
