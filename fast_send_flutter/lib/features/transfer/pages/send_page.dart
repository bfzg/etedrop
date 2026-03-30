import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/styles.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/providers/lan_provider.dart';
import '../widgets/file_drop_card.dart';
import '../widgets/lan_share_panel.dart';
import '../widgets/nearby_device_grid.dart';

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});

  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  final Set<String> _selectedDeviceIds = {};

  String? _activeShareId;
  DateTime? _activeExpiresAt;
  List<LanDevice> _activeRecipients = [];

  String _cleanPath(String raw) {
    var s = raw.trim();
    if (s.length >= 2) {
      final first = s[0];
      final last = s[s.length - 1];
      if ((first == '\'' && last == '\'') || (first == '"' && last == '"')) {
        s = s.substring(1, s.length - 1).trim();
      }
    }
    while (s.isNotEmpty && (s.startsWith('\'') || s.startsWith('"'))) {
      s = s.substring(1).trimLeft();
    }
    while (s.isNotEmpty && (s.endsWith('\'') || s.endsWith('"'))) {
      s = s.substring(0, s.length - 1).trimRight();
    }
    return s;
  }

  void _toggleDevice(String deviceId) {
    setState(() {
      if (_selectedDeviceIds.contains(deviceId)) {
        _selectedDeviceIds.remove(deviceId);
      } else {
        _selectedDeviceIds.add(deviceId);
      }
    });
  }

  void _clearActiveShareState() {
    setState(() {
      _activeShareId = null;
      _activeExpiresAt = null;
      _activeRecipients = [];
    });
  }

  void _cancelShare() {
    final id = _activeShareId;
    if (id != null) {
      ref
          .read(lanManagerProvider.notifier)
          .cancelOutgoingShare(id, userCancelled: true);
    }
    _clearActiveShareState();
  }

  /// 发起批量分享（路径已在外部整理好）
  Future<void> _startShare({
    required List<String> paths,
    String? caption,
  }) async {
    final unique = <String>[];
    for (final p in paths) {
      if (p.isNotEmpty && !unique.contains(p)) {
        unique.add(p);
      }
    }
    final capTrim = caption?.trim();
    if (unique.isEmpty && (capTrim == null || capTrim.isEmpty)) return;

    final devices = ref.read(lanManagerProvider);
    final targets = devices
        .where((d) => _selectedDeviceIds.contains(d.deviceId))
        .toList();

    if (targets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先在上方选择至少一个接收设备')));
      }
      return;
    }

    final prevId = _activeShareId;
    if (prevId != null) {
      ref
          .read(lanManagerProvider.notifier)
          .cancelOutgoingShare(prevId, userCancelled: true);
      _clearActiveShareState();
    }

    final id = await ref
        .read(lanManagerProvider.notifier)
        .startBatchShare(
          absoluteFilePaths: unique,
          targetDeviceIds: targets.map((d) => d.deviceId).toList(),
          caption: capTrim != null && capTrim.isNotEmpty ? capTrim : null,
        );
    if (!mounted) return;
    setState(() {
      _activeShareId = id;
      _activeExpiresAt = DateTime.now().add(const Duration(minutes: 2));
      _activeRecipients = List<LanDevice>.from(targets);
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已发送分享邀请，对方在消息里接受后开始传输')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;
    final devices = ref.watch(lanManagerProvider);

    _selectedDeviceIds.removeWhere(
      (id) => !devices.any((d) => d.deviceId == id),
    );

    return Scaffold(
      appBar: isDesktopLayout ? null : AppBar(title: const Text('分享')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final hasActive = _activeShareId != null && _activeExpiresAt != null;
    final devices = ref.watch(lanManagerProvider);
    final hasSelection = _selectedDeviceIds.isNotEmpty;
    final hasOnlineTarget = _selectedDeviceIds.any(
      (id) => devices.any((d) => d.deviceId == id && d.isOnline),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            child: NearbyDeviceGrid(
              selectedIds: _selectedDeviceIds,
              onToggle: _toggleDevice,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          FileDropCard(
            hasSelectedDevices: hasOnlineTarget,
            selectionOfflineOnly: hasSelection && !hasOnlineTarget,
            onSend: ({required absoluteFilePaths, caption}) async {
              final cleaned = absoluteFilePaths.map(_cleanPath).toList();
              await _startShare(paths: cleaned, caption: caption);
            },
          ),
          if (hasActive) ...[
            const SizedBox(height: Spacing.xl),
            LanSharePanel(
              shareId: _activeShareId!,
              expiresAt: _activeExpiresAt!,
              recipients: _activeRecipients,
              onCancelSharing: _cancelShare,
              onDismissRecord: _clearActiveShareState,
              onExpired: () {
                if (!mounted) return;
                _clearActiveShareState();
              },
            ),
          ],
        ],
      ),
    );
  }
}
