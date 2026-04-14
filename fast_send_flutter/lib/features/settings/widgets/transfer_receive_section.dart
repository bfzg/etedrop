import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/transfer_receive_prefs_provider.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

/// 传输相关偏好（自动接收、视频转码等）
class TransferReceiveSection extends ConsumerWidget {
  const TransferReceiveSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final autoReceive = ref.watch(autoReceiveLanTransferProvider);
    final transcodeEnabled = ref.watch(videoTranscodeEnabledProvider);

    // 视频转码仅在桌面端（有 ffmpeg bundle）才有意义
    final showTranscode = Platform.isWindows || Platform.isMacOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.transferReceiveSection),
        SettingsCard(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.download_done_outlined),
                title: Text(l10n.transferAutoReceiveTitle),
                subtitle: Text(l10n.transferAutoReceiveSubtitle),
                value: autoReceive,
                onChanged: (v) {
                  ref
                      .read(autoReceiveLanTransferProvider.notifier)
                      .setEnabled(v);
                },
              ),
              if (showTranscode) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.tune_outlined),
                  title: Text(l10n.videoTranscodeTitle),
                  subtitle: Text(l10n.videoTranscodeSubtitle),
                  value: transcodeEnabled,
                  onChanged: (v) {
                    ref
                        .read(videoTranscodeEnabledProvider.notifier)
                        .setEnabled(v);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
