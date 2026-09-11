import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../contact/models/contact_state.dart';
import '../../contact/providers/contact_provider.dart';
import 'chat_bubble.dart';
import 'chat_composer.dart';

class ChatView extends ConsumerStatefulWidget {
  final String conversationId;
  final Future<void> Function({required List<String> paths, String? caption})
  onSend;
  final VoidCallback? onBack;

  const ChatView({
    super.key,
    required this.conversationId,
    required this.onSend,
    this.onBack,
  });

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;
  String? _lastConversationId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(contactBookProvider);
    final title = _title(book, widget.conversationId);
    final messages =
        book.messages
            .where((m) => m.conversationId == widget.conversationId)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final shouldScrollToBottom =
        _lastConversationId != widget.conversationId ||
        _lastMessageCount != messages.length;
    _lastConversationId = widget.conversationId;
    _lastMessageCount = messages.length;
    if (shouldScrollToBottom && messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .45),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('暂无消息'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => ChatBubble(
                    message: messages[index],
                    onDelete: () => ref
                        .read(contactBookProvider.notifier)
                        .deleteMessage(messages[index].messageId),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ChatComposer(onSend: widget.onSend),
          ),
        ),
      ],
    );
  }

  String _title(ContactBookState book, String conversationId) {
    if (conversationId.startsWith('dm:')) {
      final id = conversationId.substring(3);
      final matches = book.contacts.where((c) => c.userId == id);
      return matches.isEmpty ? id : matches.first.displayName;
    }
    final id = conversationId.substring(6);
    final matches = book.groups.where((g) => g.groupId == id);
    return matches.isEmpty ? '群组' : matches.first.name;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}
