import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/styles.dart';
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
    final devices = ref.watch(lanManagerProvider);
    final myDeviceId = ref.watch(deviceIdProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '附近的设备',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (selectedIds.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppStyles.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '已选 ${selectedIds.length}',
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
        const SizedBox(height: 16),
        if (devices.isEmpty)
          SizedBox(
            height: 100,
            child: Center(
              child: Row(
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
                  Text('正在扫描局域网设备...', style: AppTextStyles.secondary(context)),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 20,
            runSpacing: 16,
            children: devices.map((device) {
              final isSelf = device.deviceId == myDeviceId;
              final selected = selectedIds.contains(device.deviceId);
              return _DeviceAvatar(
                device: device,
                selected: selected,
                isSelf: isSelf,
                onTap: isSelf ? null : () => onToggle(device.deviceId),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _DeviceAvatar extends StatelessWidget {
  final LanDevice device;
  final bool selected;
  final bool isSelf;
  final VoidCallback? onTap;

  const _DeviceAvatar({
    required this.device,
    required this.selected,
    required this.isSelf,
    this.onTap,
  });

  static const double _size = 78;

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
                              : isSelf
                              ? theme.colorScheme.outlineVariant
                              : theme.colorScheme.outlineVariant,
                          width: selected ? 2.5 : 1.5,
                        ),
                      ),
                      child: ClipOval(
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
                      ),
                    ),
                  ),

                  // 右上角 You 标记
                  if (isSelf)
                    Positioned(
                      right: 0,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSecondaryContainer,
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
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppStyles.primary
                    : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // 系统名称
            Text(
              _osLabel(device.os),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
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
