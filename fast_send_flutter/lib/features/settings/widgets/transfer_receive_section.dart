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
    final transcodeEnabled = ref.watch(videoTranscodeEnabledProvider);

    // 桌面与 Android 均可能内置 ffmpeg；移动端常见为仅 remux（无 libx264），
    // 开关仍影响「是否允许尝试转码路径」（不兼容编码时的提示与行为）。
    final showTranscode =
        Platform.isWindows || Platform.isMacOS || Platform.isAndroid;
    if (!showTranscode) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.transferReceiveSection),
        SettingsCard(
          child: Column(
            children: [
              if (showTranscode)
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
          ),
        ),
      ],
    );
  }
}
