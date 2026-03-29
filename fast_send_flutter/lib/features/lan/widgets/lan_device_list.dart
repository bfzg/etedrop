import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/lan_provider.dart';
import '../models/lan_device.dart';

class LanDeviceList extends ConsumerWidget {
  final Function(LanDevice) onDeviceSelected;

  const LanDeviceList({super.key, required this.onDeviceSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = ref.watch(lanManagerProvider);
    final devices = [...raw]..sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        return a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase());
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            '附近的设备',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        if (devices.isEmpty)
          Container(
            height: 100,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  '正在寻找附近的设备...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: devices.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final device = devices[index];
                return _DeviceItem(
                  device: device,
                  onTap: device.isOnline ? () => onDeviceSelected(device) : null,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DeviceItem extends StatelessWidget {
  final LanDevice device;
  final VoidCallback? onTap;

  const _DeviceItem({required this.device, required this.onTap});

  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = !device.isOnline;

    Widget iconCircle = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIconForOs(device.os),
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
    if (offline) {
      iconCircle = ColorFiltered(
        colorFilter: _grayscale,
        child: Opacity(opacity: 0.52, child: iconCircle),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconCircle,
            const SizedBox(height: 8),
            Text(
              device.deviceName,
              style: TextStyle(
                fontSize: 12,
                color: offline
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (offline)
              Text(
                '离线',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForOs(String os) {
    switch (os.toLowerCase()) {
      case 'macos':
        return Icons.laptop_mac;
      case 'windows':
        return Icons.desktop_windows;
      case 'linux':
        return Icons.computer;
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.phone_android;
      default:
        return Icons.devices;
    }
  }
}
