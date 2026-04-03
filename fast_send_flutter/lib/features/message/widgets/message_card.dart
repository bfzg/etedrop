import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';
import '../../lan/providers/transfer_receive_speed_provider.dart';
import '../models/transfer_message.dart';
import 'message_card_actions.dart';
import 'message_card_files.dart';
import 'message_card_header.dart';
import 'message_card_utils.dart';

class MessageCard extends ConsumerWidget {
  final TransferMessage message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final receiveSpeeds = ref.watch(transferReceiveSpeedProvider);
    final receiveSpeedKey = message.shareId ?? message.id;
    final receiveBps = !message.isOutgoing
        ? receiveSpeeds[receiveSpeedKey]
        : null;
    final isPending = message.status == TransferMessageStatus.pending;
    final showIncomingActions = isPending && !message.isOutgoing;
    final batch = decodeBatchFiles(message);
    final canRevealInFolder = message.status == TransferMessageStatus.completed;

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MessageCardHeader(message: message),
            const SizedBox(height: 12),
            if (trimCaption(message) != null) ...[
              SelectableText(
                trimCaption(message)!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
            ],
            if (batch != null && batch.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < batch.length; i++)
                    revealableFileChip(
                      context,
                      ref,
                      theme,
                      l10n,
                      canRevealInFolder,
                      fileIndex: i,
                      fileName: batch[i]['name'] as String? ?? '',
                      fileSize: (batch[i]['size'] as num?)?.toInt() ?? 0,
                      message: message,
                      localPreviewPath: pathAt(decodedLocalPaths(message), i),
                      isImage: isLikelyImageFileName(
                        batch[i]['name'] as String? ?? '',
                      ),
                    ),
                ],
              ),
              if (batch.length == 1 &&
                  canRevealInFolder &&
                  isPlainTextPreviewFileName(
                    batch.first['name'] as String? ?? '',
                  )) ...[
                Builder(
                  builder: (ctx) {
                    final pth = pathAt(decodedLocalPaths(message), 0);
                    if (pth == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFilePreviewBox(path: pth),
                    );
                  },
                ),
              ],
              const SizedBox(height: 4),
              Text(
                l10n.totalSizeLine(FormatUtils.fileSize(message.fileSize)),
                style: AppTextStyles.hint(context),
              ),
            ] else if (!message.isBatch) ...[
              revealableSingleFileBlock(
                context,
                ref,
                theme,
                l10n,
                canRevealInFolder,
                message: message,
                localPreviewPath: pathAt(decodedLocalPaths(message), 0),
                isImage: isLikelyImageFileName(message.fileName),
              ),
            ],
            if (message.status == TransferMessageStatus.receiving) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: message.progress <= 0 ? null : message.progress,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.isOutgoing
                        ? l10n.sendingPercent(
                            (message.progress * 100).toStringAsFixed(0),
                          )
                        : l10n.receivingPercent(
                            (message.progress * 100).toStringAsFixed(0),
                          ),
                    style: AppTextStyles.secondary(context),
                  ),
                  if (receiveBps != null && receiveBps > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.approxSpeed(FormatUtils.transferSpeed(receiveBps)),
                      style: AppTextStyles.hint(context),
                    ),
                  ],
                ],
              ),
            ],
            if (message.status == TransferMessageStatus.failed &&
                message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(message.errorMessage!, style: AppTextStyles.error(context)),
            ],
            if (message.status == TransferMessageStatus.expired &&
                message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                message.errorMessage!,
                style: AppTextStyles.secondary(context),
              ),
            ],
            if (message.isOutgoing &&
                message.status == TransferMessageStatus.pending) ...[
              const SizedBox(height: 8),
              Text(
                l10n.waitAcceptInMessage,
                style: AppTextStyles.hint(context),
              ),
            ],
            if (message.isOutgoing &&
                message.status == TransferMessageStatus.expired &&
                message.localFilePathsJson != null &&
                message.targetDeviceIdsJson != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => retryOutgoingShare(context, ref, message),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.retrySend),
                ),
              ),
            ],
            if (showIncomingActions) ...[
              const SizedBox(height: 12),
              MessageCardIncomingActions(message: message),
            ],
          ],
        ),
      ),
    );
  }
}
