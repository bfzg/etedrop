import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/transfer_receive_prefs_provider.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

/// 局域网接收相关偏好（自动接收分享等）
class TransferReceiveSection extends ConsumerWidget {
  const TransferReceiveSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(autoReceiveLanTransferProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.transferReceiveSection),
        SettingsCard(
          child: SwitchListTile.adaptive(
            secondary: const Icon(Icons.download_done_outlined),
            title: Text(l10n.transferAutoReceiveTitle),
            subtitle: Text(l10n.transferAutoReceiveSubtitle),
            value: enabled,
            onChanged: (v) {
              ref.read(autoReceiveLanTransferProvider.notifier).setEnabled(v);
            },
          ),
        ),
      ],
    );
  }
}
