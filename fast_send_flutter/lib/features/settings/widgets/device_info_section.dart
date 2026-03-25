import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../device/providers/device_provider.dart';
import 'rename_device_dialog.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class DeviceInfoSection extends ConsumerWidget {
  final bool connected;
  final bool connecting;
  final String? lastError;
  final String devName;
  final String? devId;

  const DeviceInfoSection({
    super.key,
    required this.connected,
    required this.connecting,
    required this.lastError,
    required this.devName,
    required this.devId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.deviceInfo),
        SettingsCard(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  connected
                      ? Icons.cloud_done
                      : (connecting ? Icons.cloud_sync : Icons.cloud_off),
                  color: connected
                      ? Colors.green
                      : (connecting
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant),
                ),
                title: Text(devName),
                subtitle: Text(
                  connected
                      ? l10n.connected
                      : (connecting ? l10n.connecting : l10n.disconnected),
                ),
                trailing: connected
                    ? null
                    : (connecting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : FilledButton.tonal(
                              onPressed: () => ref
                                  .read(deviceManagerProvider)
                                  .connectToServer(),
                              child: Text(l10n.connect),
                            )),
              ),
              if (lastError != null && lastError!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    lastError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Divider(height: 1, indent: 56),
              if (devId != null) ...[
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: Text(l10n.deviceId),
                  subtitle: Text(
                    devId!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
              ],
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.editDeviceName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    showRenameDeviceDialog(context, ref, devName, l10n),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
