import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.about),
        const SettingsCard(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppConstants.appName),
            subtitle: Text('v${AppConstants.version}'),
          ),
        ),
      ],
    );
  }
}
