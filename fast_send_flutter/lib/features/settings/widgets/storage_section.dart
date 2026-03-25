import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../cloud/providers/cloud_provider.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class StorageSection extends ConsumerWidget {
  final String storagePath;

  const StorageSection({super.key, required this.storagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.storage),
        SettingsCard(
          child: ListTile(
            leading: const Icon(Icons.folder),
            title: Text(l10n.storagePath),
            subtitle: Text(storagePath.isEmpty ? l10n.notSet : storagePath),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                ref.read(fileServiceProvider.notifier).selectStorageDir(),
          ),
        ),
      ],
    );
  }
}
