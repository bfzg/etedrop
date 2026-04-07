import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/webrtc_keepalive_prefs_provider.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

/// WebRTC / 局域网传输后台保活开关（仅 iOS / Android）
class WebrtcBackgroundSection extends ConsumerWidget {
  const WebrtcBackgroundSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(webrtcKeepalivePreferenceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.webrtcBackgroundKeepaliveSection),
        SettingsCard(
          child: SwitchListTile.adaptive(
            secondary: const Icon(Icons.graphic_eq_outlined),
            title: Text(l10n.webrtcBackgroundKeepaliveTitle),
            subtitle: Text(l10n.webrtcBackgroundKeepaliveSubtitle),
            value: enabled,
            onChanged: (v) async {
              final ok = await ref
                  .read(webrtcKeepalivePreferenceProvider.notifier)
                  .setEnabled(
                    v,
                    fgNotificationTitle: l10n.webrtcBackgroundFgNotificationTitle,
                    fgNotificationBody: l10n.webrtcBackgroundFgNotificationBody,
                  );
              if (!context.mounted) return;
              if (!ok && v) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.webrtcBackgroundKeepaliveEnableFailed)),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
