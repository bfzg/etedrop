import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../contact/models/contact.dart';
import '../../contact/models/contact_state.dart';
import '../../contact/providers/contact_provider.dart';
import '../widgets/chat_view.dart';
import '../widgets/conversation_pane_resizer.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/message_avatar.dart';
import '../widgets/message_empty_view.dart';

class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  String? _selectedConversationId;
  double _conversationListWidth = 220;

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(contactBookProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    final selected = _selectedConversationId;
    final hasSelection =
        selected != null &&
        (book.contacts.any((c) => 'dm:${c.userId}' == selected) ||
            book.groups.any((g) => 'group:${g.groupId}' == selected));

    if (!hasSelection) {
      if (book.contacts.isNotEmpty) {
        _selectedConversationId = _conversationForContact(book.contacts.first);
      } else if (book.groups.isNotEmpty) {
        _selectedConversationId = 'group:${book.groups.first.groupId}';
      }
    }

    final list = _conversationList(context, book);
    final content = isDesktop
        ? Row(
            children: [
              SizedBox(width: _conversationListWidth, child: list),
              ConversationPaneResizer(
                onDrag: (delta) {
                  setState(() {
                    _conversationListWidth = (_conversationListWidth + delta)
                        .clamp(220, 340);
                  });
                },
              ),
              Expanded(
                child: _selectedConversationId == null
                    ? const MessageEmptyView()
                    : ChatView(
                        conversationId: _selectedConversationId!,
                        onSend: _sendComposer,
                      ),
              ),
            ],
          )
        : _selectedConversationId == null
        ? list
        : ChatView(
            conversationId: _selectedConversationId!,
            onBack: () => setState(() => _selectedConversationId = null),
            onSend: _sendComposer,
          );

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('消息'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1),
                  tooltip: '添加联系人',
                  onPressed: _addContact,
                ),
                IconButton(
                  icon: const Icon(Icons.group_add_outlined),
                  tooltip: '创建群组',
                  onPressed: _createGroup,
                ),
              ],
            ),
      body: SafeArea(bottom: false, child: content),
    );
  }

  Widget _conversationList(BuildContext context, ContactBookState book) {
    final desktop = MediaQuery.sizeOf(context).width >= 700;
    return Column(
      children: [
        if (desktop)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 10, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '消息',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1),
                  tooltip: '添加联系人',
                  onPressed: _addContact,
                ),
                IconButton(
                  icon: const Icon(Icons.group_add_outlined),
                  tooltip: '创建群组',
                  onPressed: _createGroup,
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              for (final conversation in _sortedConversations(book))
                ConversationTile(
                  title: conversation.title,
                  subtitle: conversation.subtitle,
                  avatar: conversation.avatar,
                  online: conversation.online,
                  selected:
                      _selectedConversationId == conversation.conversationId,
                  lastMessage: _lastMessage(book, conversation.conversationId),
                  unreadCount: _unreadCount(book, conversation.conversationId),
                  onTap: () => _selectConversation(conversation.conversationId),
                ),
              if (book.contacts.isEmpty && book.groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('正在寻找附近设备，或通过用户 ID 添加联系人'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _conversationForContact(Contact contact) => 'dm:${contact.userId}';

  List<_Conversation> _sortedConversations(ContactBookState book) {
    final conversations = <_Conversation>[
      for (final contact in book.contacts)
        _Conversation(
          conversationId: _conversationForContact(contact),
          title: contact.displayName,
          subtitle: contact.isOnline
              ? (contact.transport == ContactTransport.lan ? '局域网在线' : 'WebRTC')
              : '离线',
          avatar: contact.avatar,
          online: contact.isOnline,
        ),
      for (final group in book.groups)
        _Conversation(
          conversationId: 'group:${group.groupId}',
          title: group.name,
          subtitle: '${group.memberIds.length} 位成员',
          avatar: group.avatar,
        ),
    ];
    conversations.sort((a, b) {
      final byTime = _lastMessageTime(
        book,
        b.conversationId,
      ).compareTo(_lastMessageTime(book, a.conversationId));
      return byTime != 0
          ? byTime
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return conversations;
  }

  void _selectConversation(String conversationId) {
    setState(() => _selectedConversationId = conversationId);
    ref.read(contactBookProvider.notifier).markConversationRead(conversationId);
  }

  String? _lastMessage(ContactBookState book, String conversationId) {
    final matches = book.messages
        .where((m) => m.conversationId == conversationId)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return matches.first.text;
  }

  int _lastMessageTime(ContactBookState book, String conversationId) {
    final matches = book.messages.where(
      (m) => m.conversationId == conversationId,
    );
    return matches.isEmpty
        ? 0
        : matches.reduce((a, b) => a.timestamp > b.timestamp ? a : b).timestamp;
  }

  int _unreadCount(ContactBookState book, String conversationId) {
    return book.messages
        .where(
          (m) =>
              m.conversationId == conversationId && !m.isOutgoing && !m.isRead,
        )
        .length;
  }

  Future<void> _sendComposer({
    required List<String> paths,
    String? caption,
  }) async {
    final id = _selectedConversationId;
    if (id == null) return;
    final text = caption?.trim() ?? '';
    if (paths.isEmpty) {
      await ref.read(contactBookProvider.notifier).sendText(id, text);
    } else {
      await ref
          .read(contactBookProvider.notifier)
          .sendFiles(id, paths: paths, caption: text.isEmpty ? null : text);
    }
  }

  Future<void> _addContact() async {
    final controller = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加联系人'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '用户 ID',
            hintText: '输入对方的 WebRTC 用户 ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (id != null && id.trim().isNotEmpty) {
      ref.read(contactBookProvider.notifier).addByUserId(id);
    }
  }

  Future<void> _createGroup() async {
    final nameController = TextEditingController();
    final selected = <String>{};
    final book = ref.read(contactBookProvider);
    final result = await showDialog<(String, List<String>)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建群组'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '群组名称'),
                  ),
                  const SizedBox(height: 12),
                  for (final contact in book.contacts)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(contact.userId),
                      title: Text(contact.displayName),
                      secondary: MessageAvatar(
                        avatar: contact.avatar,
                        size: 32,
                      ),
                      onChanged: (value) => setDialogState(() {
                        if (value == true) {
                          selected.add(contact.userId);
                        } else {
                          selected.remove(contact.userId);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                nameController.text,
                selected.toList(),
              )),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result != null) {
      ref.read(contactBookProvider.notifier).createGroup(result.$1, result.$2);
    }
  }
}

class _Conversation {
  final String conversationId;
  final String title;
  final String subtitle;
  final int avatar;
  final bool online;

  const _Conversation({
    required this.conversationId,
    required this.title,
    required this.subtitle,
    required this.avatar,
    this.online = false,
  });
}
