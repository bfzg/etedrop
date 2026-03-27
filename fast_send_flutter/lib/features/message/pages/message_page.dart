import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/styles.dart';
import '../providers/message_provider.dart';
import '../widgets/message_card.dart';
import '../widgets/message_empty_view.dart';

class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageListProvider);
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: isDesktopLayout
          ? null
          : AppBar(
              title: const Text('消息'),
              actions: [
                if (messages.isNotEmpty)
                  IconButton(
                    onPressed: () =>
                        ref.read(messageListProvider.notifier).clearAll(),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: '清空',
                  ),
              ],
            ),
      body: messages.isEmpty
          ? const MessageEmptyView()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              itemCount: messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final msg = messages[index];
                return MessageCard(message: msg);
              },
            ),
    );
  }
}
