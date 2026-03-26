import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../cloud/providers/cloud_provider.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class StorageSection extends ConsumerWidget {
  final String storagePath;
  final String downloadPath;

  const StorageSection({
    super.key,
    required this.storagePath,
    required this.downloadPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.storage),
        SettingsCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('网盘目录'),
                subtitle: Text(storagePath.isEmpty ? l10n.notSet : storagePath),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(fileServiceProvider.notifier).selectStorageDir(),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('下载目录'),
                subtitle:
                    Text(downloadPath.isEmpty ? l10n.notSet : downloadPath),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(downloadDirProvider.notifier).selectDownloadDir(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
