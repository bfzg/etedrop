import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/lan_provider.dart';
import '../models/lan_device.dart';

class LanDeviceList extends ConsumerWidget {
  final Function(LanDevice) onDeviceSelected;

  const LanDeviceList({super.key, required this.onDeviceSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final raw = ref.watch(lanManagerProvider);
    final devices = [...raw]..sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        if (a.isOnline &&
            b.isOnline &&
            a.isPresenceWeak != b.isPresenceWeak) {
          return a.isPresenceWeak ? 1 : -1;
        }
        return a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase());
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            l10n.nearbyDevices,
            style: const TextStyle(
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
                  l10n.lookingForNearbyDevices,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                if (!kIsWeb && Platform.isMacOS) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.macLanLocalNetworkHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
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
                  offlineLabel: l10n.offline,
                  weakSignalLabel: l10n.weakSignal,
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
  final String offlineLabel;
  final String weakSignalLabel;
  final VoidCallback? onTap;

  const _DeviceItem({
    required this.device,
    required this.offlineLabel,
    required this.weakSignalLabel,
    required this.onTap,
  });

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
    final weak = device.isOnline && device.isPresenceWeak;

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
    } else if (weak) {
      iconCircle = Opacity(opacity: 0.78, child: iconCircle);
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
                offlineLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.45,
                  ),
                ),
              )
            else if (weak)
              Text(
                weakSignalLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.65,
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
