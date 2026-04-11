import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';
import '../../device/models/device_config.dart';
import '../../device/providers/device_provider.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/providers/lan_provider.dart';

class NearbyDeviceGrid extends ConsumerWidget {
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const NearbyDeviceGrid({
    super.key,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final raw = ref.watch(lanManagerProvider);
    final myDeviceId = ref.watch(deviceIdProvider);
    final theme = Theme.of(context);
    final safeH = MediaQuery.paddingOf(context);
    final devices = [...raw]
      ..sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        if (a.isOnline && b.isOnline && a.isPresenceWeak != b.isPresenceWeak) {
          return a.isPresenceWeak ? 1 : -1;
        }
        final aSelf = a.deviceId == myDeviceId;
        final bSelf = b.deviceId == myDeviceId;
        if (aSelf != bSelf) return aSelf ? -1 : 1;
        return a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase());
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
          child: Row(
            children: [
              Text(
                l10n.nearbyDevices,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (selectedIds.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppStyles.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.selectedCount(selectedIds.length),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppStyles.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (devices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
            child: SizedBox(
              height: !kIsWeb && Platform.isMacOS ? 140 : 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.findingNearbyUsers,
                        style: AppTextStyles.secondary(context),
                      ),
                    ],
                  ),
                  if (!kIsWeb && Platform.isMacOS) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n.macLanLocalNetworkHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                left: safeH.left + Spacing.xl,
                right: safeH.right + Spacing.xl,
              ),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(width: 28),
              itemBuilder: (context, index) {
                final device = devices[index];
                final isSelf = device.deviceId == myDeviceId;
                final selected = selectedIds.contains(device.deviceId);
                return _DeviceAvatar(
                  device: device,
                  selected: selected,
                  isSelf: isSelf,
                  offlineLabel: l10n.offline,
                  weakSignalLabel: l10n.weakSignal,
                  youLabel: l10n.youLabel,
                  onTap: isSelf
                      ? null
                      : (!device.isOnline &&
                            !selectedIds.contains(device.deviceId))
                      ? null
                      : () => onToggle(device.deviceId),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DeviceAvatar extends StatelessWidget {
  final LanDevice device;
  final bool selected;
  final bool isSelf;
  final String offlineLabel;
  final String weakSignalLabel;
  final String youLabel;
  final VoidCallback? onTap;

  const _DeviceAvatar({
    required this.device,
    required this.selected,
    required this.isSelf,
    required this.offlineLabel,
    required this.weakSignalLabel,
    required this.youLabel,
    this.onTap,
  });

  static const double _size = 84;
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  String _osLabel(String os) {
    switch (os.toLowerCase()) {
      case 'macos':
        return 'macOS';
      case 'windows':
        return 'Windows';
      case 'linux':
        return 'Linux';
      case 'ios':
        return 'iOS';
      case 'android':
        return 'Android';
      default:
        return os;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = !device.isOnline;
    final weak = device.isOnline && device.isPresenceWeak;
    final dimmed = (offline || weak) && !isSelf;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头像区域
            SizedBox(
              width: _size + 8,
              height: _size + 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 圆形边框 + 头像
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppStyles.primary
                              : dimmed
                              ? theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.45,
                                )
                              : theme.colorScheme.outlineVariant,
                          width: selected ? 3 : 2,
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          Widget img = ClipOval(
                            child: Image.asset(
                              memojiAssetPath(device.avatar),
                              width: _size - 4,
                              height: _size - 4,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.person,
                                size: 32,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                          if (offline && !isSelf) {
                            img = ColorFiltered(
                              colorFilter: _grayscale,
                              child: Opacity(opacity: 0.52, child: img),
                            );
                          } else if (weak && !isSelf) {
                            img = Opacity(opacity: 0.75, child: img);
                          }
                          return img;
                        },
                      ),
                    ),
                  ),

                  // 右上角 You 标记
                  if (isSelf)
                    Positioned(
                      right: -4,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppStyles.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          youLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // 右下角选中对勾
                  if (selected)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppStyles.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // 用户名
            Text(
              device.deviceName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: dimmed
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                    : selected
                    ? AppStyles.primary
                    : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // 系统名称 / 离线
            Text(
              offline
                  ? offlineLabel
                  : weak
                  ? weakSignalLabel
                  : _osLabel(device.os),
              style: TextStyle(
                fontSize: 12,
                color: offline
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
                    : weak
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
