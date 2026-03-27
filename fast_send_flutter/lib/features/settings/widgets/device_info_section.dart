import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../device/models/device_config.dart';
import '../../device/providers/device_provider.dart';
import 'avatar_picker_dialog.dart';
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
    final avatar = ref.watch(deviceAvatarProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.deviceInfo),
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像 + 用户名 + 连接状态 一行
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 0,
                ),
                child: Row(
                  children: [
                    // 可点击的头像
                    GestureDetector(
                      onTap: () => _pickAvatar(context, ref, avatar),
                      child: Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                memojiAssetPath(avatar),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.person,
                                  size: 28,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // 用户名 + 状态
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => showRenameDeviceDialog(
                              context,
                              ref,
                              devName,
                              l10n,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    devName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: connected
                                      ? Colors.green
                                      : (connecting
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant
                                                  .withValues(alpha: 0.3)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                connected
                                    ? l10n.connected
                                    : (lastError != null &&
                                          lastError!.isNotEmpty)
                                    ? lastError!
                                    : l10n.disconnected,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 连接按钮
                    if (!connected && !connecting)
                      FilledButton.tonal(
                        onPressed: () =>
                            ref.read(deviceManagerProvider).connectToServer(),
                        child: Text(l10n.connect),
                      )
                    else if (connecting)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              if (devId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListTile(
                    title: Text(l10n.deviceId),
                    subtitle: Text(
                      devId!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAvatar(
    BuildContext context,
    WidgetRef ref,
    int currentAvatar,
  ) async {
    final result = await AvatarPickerDialog.show(context, currentAvatar);
    if (result != null && result != currentAvatar) {
      await ref.read(deviceManagerProvider).setAvatar(result);
    }
  }
}
