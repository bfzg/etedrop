import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';
import '../../../widgets/ui/e_button.dart';
import '../../lan/providers/transfer_receive_speed_provider.dart';
import '../../settings/providers/transfer_receive_prefs_provider.dart';
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
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;
    final receiveSpeedKey = message.shareId ?? message.id;
    final receiveBps = !message.isOutgoing
        ? receiveSpeeds[receiveSpeedKey]
        : null;
    final isPending = message.status == TransferMessageStatus.pending;
    final autoReceiveLan = ref.watch(autoReceiveLanTransferProvider);
    final showIncomingActions =
        isPending && !message.isOutgoing && !autoReceiveLan;
    final batch = decodeBatchFiles(message);
    final canRevealInFolder = message.status == TransferMessageStatus.completed;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MessageCardHeader(message: message),
            const SizedBox(height: 12),
            if (trimCaption(message) != null) ...[
              SelectableText(
                trimCaption(message)!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (batch != null && batch.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < batch.length; i++)
                    SizedBox(
                      width: isDesktopLayout ? 300 : double.infinity,
                      child: revealableFileChip(
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
                      padding: const EdgeInsets.only(top: 12),
                      child: TextFilePreviewBox(path: pth),
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.totalSizeLine(FormatUtils.fileSize(message.fileSize)),
                style: AppTextStyles.hint(context).copyWith(fontSize: 12),
              ),
            ] else if (!message.isBatch) ...[
              SizedBox(
                width: isDesktopLayout ? 350 : double.infinity,
                child: revealableSingleFileBlock(
                  context,
                  ref,
                  theme,
                  l10n,
                  canRevealInFolder,
                  message: message,
                  localPreviewPath: pathAt(decodedLocalPaths(message), 0),
                  isImage: isLikelyImageFileName(message.fileName),
                ),
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
                child: EButton(
                  variant: EButtonVariant.primary,
                  icon: Icons.refresh,
                  radius: 99,
                  size: EButtonSize.sm,
                  text: l10n.retrySend,
                  onPressed: () => retryOutgoingShare(context, ref, message),
                ),
              ),
            ],
            if (isPending && !message.isOutgoing && autoReceiveLan) ...[
              const SizedBox(height: 8),
              Text(
                l10n.transferAutoReceivingHint,
                style: AppTextStyles.hint(context),
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
