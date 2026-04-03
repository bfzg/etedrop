import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../lan/providers/lan_provider.dart';
import '../models/transfer_message.dart';
import '../providers/message_provider.dart';

Future<void> retryOutgoingShare(
  BuildContext context,
  WidgetRef ref,
  TransferMessage message,
) async {
  final l10n = AppLocalizations.of(context)!;
  final pathsRaw = message.localFilePathsJson;
  final idsRaw = message.targetDeviceIdsJson;
  if (pathsRaw == null || idsRaw == null) return;
  final lanNotifier = ref.read(lanManagerProvider.notifier);
  try {
    final paths = (jsonDecode(pathsRaw) as List)
        .map((e) => e as String)
        .toList();
    final ids = (jsonDecode(idsRaw) as List).map((e) => e as String).toList();
    final existing = <String>[];
    for (final p in paths) {
      if (await File(p).exists()) {
        existing.add(p);
      }
    }
    if (existing.isEmpty) {
      final capOnly = message.caption?.trim();
      if (capOnly != null && capOnly.isNotEmpty && ids.isNotEmpty) {
        await lanNotifier.startBatchShare(
          absoluteFilePaths: const [],
          targetDeviceIds: ids,
          caption: capOnly,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.shareRestarted)),
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.localFileGoneCannotRetry)),
        );
      }
      return;
    }
    if (ids.isEmpty) return;
    final cap = message.caption?.trim();
    await lanNotifier.startBatchShare(
      absoluteFilePaths: existing,
      targetDeviceIds: ids,
      caption: cap != null && cap.isNotEmpty ? cap : null,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareRestarted)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.retryFailed('$e'))),
      );
    }
  }
}

/// 待处理且为接收侧时的「拒绝 / 接收」操作行。
class MessageCardIncomingActions extends ConsumerWidget {
  final TransferMessage message;

  const MessageCardIncomingActions({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () async {
            final msgNotifier = ref.read(messageListProvider.notifier);
            final lanNotifier = ref.read(lanManagerProvider.notifier);
            if (message.isBatch && message.shareId != null) {
              try {
                await lanNotifier.receiverRespondToShare(message, false);
              } catch (_) {}
            }
            msgNotifier.updateStatus(
              message.id,
              TransferMessageStatus.rejected,
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
          ),
          child: Text(l10n.reject),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () async {
            final msgNotifier = ref.read(messageListProvider.notifier);
            final lanNotifier = ref.read(lanManagerProvider.notifier);
            if (message.isBatch && message.shareId != null) {
              msgNotifier.updateStatus(
                message.id,
                TransferMessageStatus.accepted,
              );
              try {
                await lanNotifier.receiverRespondToShare(message, true);
                var textOnlyOffer = false;
                final raw = message.batchFilesJson;
                if (raw != null && raw.isNotEmpty) {
                  try {
                    final list = jsonDecode(raw) as List<dynamic>;
                    textOnlyOffer = list.isEmpty;
                  } catch (_) {}
                }
                if (textOnlyOffer) {
                  msgNotifier.markCompleted(message.id);
                }
              } catch (e) {
                msgNotifier.updateStatus(
                  message.id,
                  TransferMessageStatus.pending,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.notifySenderFailed('$e'),
                      ),
                    ),
                  );
                }
              }
            } else {
              msgNotifier.updateStatus(
                message.id,
                TransferMessageStatus.accepted,
              );
            }
          },
          icon: const Icon(Icons.download, size: 18),
          label: Text(l10n.receiveAction),
        ),
      ],
    );
  }
}
