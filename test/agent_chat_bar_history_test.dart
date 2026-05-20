import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileai_flutter/mobileai_flutter.dart';

void main() {
  Widget buildChatBar({
    required List<AiMessage> messages,
    Function(String, [List<UserImage>?])? onSend,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            AgentChatBar(
              onSend: onSend ?? (_, [__]) {},
              isThinking: false,
              messages: messages,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('history panel shows conversations and new conversation action', (
    tester,
  ) async {
    var selectedConversationId = '';
    var startedNewConversation = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AgentChatBar(
                onSend: (_, [__]) {},
                isThinking: false,
                conversations: const [
                  ConversationSummary(
                    id: 'conv_1',
                    title: 'Disable push notifications',
                    preview: 'I can help with that.',
                    messageCount: 2,
                    createdAt: 1,
                    updatedAt: 1,
                  ),
                ],
                onConversationSelect: (conversationId) {
                  selectedConversationId = conversationId;
                },
                onNewConversation: () {
                  startedNewConversation = true;
                },
              ),
            ],
          ),
        ),
      ),
    );

    final scaffoldSize = tester.getSize(find.byType(Scaffold));
    await tester.tapAt(
      Offset(scaffoldSize.width - 50, scaffoldSize.height - 170),
    );
    await tester.pumpAndSettle();

    expect(find.text('History'), findsNothing);
    await tester.tap(find.byIcon(Icons.history_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Disable push notifications'), findsOneWidget);

    await tester.tap(find.text('Disable push notifications'));
    await tester.pumpAndSettle();
    expect(selectedConversationId, 'conv_1');

    await tester.tap(find.byIcon(Icons.history_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    expect(startedNewConversation, isTrue);
  });

  testWidgets('text input stays answerable while awaiting a freeform reply', (
    tester,
  ) async {
    String sentMessage = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AgentChatBar(
                onSend: (value, [_]) {
                  sentMessage = value;
                },
                isThinking: true,
                awaitingUserResponse: true,
                messages: [
                  AiMessage(
                    role: 'assistant',
                    content: 'Hi there! How can I help you today?',
                    previewText: 'Hi there! How can I help you today?',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final scaffoldSize = tester.getSize(find.byType(Scaffold));
    await tester.tapAt(
      Offset(scaffoldSize.width - 50, scaffoldSize.height - 170),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<CupertinoTextField>(
      find.byType(CupertinoTextField),
    );
    expect(textField.enabled, isTrue);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);

    await tester.enterText(
      find.byType(CupertinoTextField),
      'add blue coffee machine to cart',
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(sentMessage, 'add blue coffee machine to cart');
  });

  testWidgets('closed assistant replies show badge and clear after opening', (
    tester,
  ) async {
    var messages = <AiMessage>[];

    await tester.pumpWidget(buildChatBar(messages: messages));

    messages = [
      AiMessage(
        role: 'assistant',
        content: 'I found the delivery fee on your latest charge.',
        previewText: 'I found the delivery fee on your latest charge.',
      ),
    ];
    await tester.pumpWidget(buildChatBar(messages: messages));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ai-closed-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-unread-badge')), findsOneWidget);
    expect(
      find.text('I found the delivery fee on your latest charge.'),
      findsOneWidget,
    );

    final scaffoldSize = tester.getSize(find.byType(Scaffold));
    await tester.tapAt(
      Offset(scaffoldSize.width - 50, scaffoldSize.height - 170),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ai-closed-preview')), findsNothing);
    expect(find.byKey(const ValueKey('ai-unread-badge')), findsNothing);

    await tester.tap(find.text('—'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ai-closed-preview')), findsNothing);
    expect(find.byKey(const ValueKey('ai-unread-badge')), findsNothing);
  });

  testWidgets('closed preview stays within screen edges', (tester) async {
    var messages = <AiMessage>[];

    await tester.pumpWidget(buildChatBar(messages: messages));

    messages = [
      AiMessage(
        role: 'assistant',
        content: 'Your order total is ready to review.',
        previewText: 'Your order total is ready to review.',
      ),
    ];
    await tester.pumpWidget(buildChatBar(messages: messages));
    await tester.pumpAndSettle();

    final scaffoldSize = tester.getSize(find.byType(Scaffold));
    var previewRect = tester.getRect(
      find.byKey(const ValueKey('ai-closed-preview')),
    );
    expect(previewRect.left, greaterThanOrEqualTo(0));
    expect(previewRect.right, lessThanOrEqualTo(scaffoldSize.width));

    await tester.drag(find.byKey(const ValueKey('fab')), const Offset(-500, 0));
    await tester.pumpAndSettle();

    previewRect = tester.getRect(
      find.byKey(const ValueKey('ai-closed-preview')),
    );
    expect(previewRect.left, greaterThanOrEqualTo(0));
    expect(previewRect.right, lessThanOrEqualTo(scaffoldSize.width));
  });
}
