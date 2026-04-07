import 'package:flutter/material.dart';
import 'dart:io';
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
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.storage),
        SettingsCard(
          child: Column(
            children: [
              if (!isMobile) ...[
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text(l10n.cloudDirectoryLabel),
                  subtitle: Text(
                    storagePath.isEmpty ? l10n.notSet : storagePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ref
                      .read(fileServiceProvider.notifier)
                      .selectStorageDir(
                        dialogTitle: l10n.pickCloudStorageTitle,
                      ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.downloadDirectoryLabel),
                subtitle: Text(
                  downloadPath.isEmpty ? l10n.notSet : downloadPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ref.read(downloadDirProvider.notifier).selectDownloadDir(
                      dialogTitle: l10n.pickDownloadDirTitle,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
