import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../styles/styles.dart';
import '../../lan/providers/lan_provider.dart';
import '../../lan/models/lan_device.dart';
import '../widgets/send_error_view.dart';
import '../widgets/send_uploading_view.dart';
import '../widgets/dashed_border_painter.dart';

enum SendStatus { idle, uploading, done, error }

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});

  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  SendStatus _status = SendStatus.idle;
  String? _errorMsg;
  bool _isPageDragging = false;
  double _uploadProgress = 0;
  String? _uploadFileName;
  int? _uploadFileSize;

  final Set<String> _selectedDeviceIds = {};

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

  Future<void> _pickAndSend() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final filePath = _cleanPath(file.path!);
    if (filePath.isEmpty) return;

    await _sendToSelectedDevices(filePath);
  }

  Future<void> _handleDrop(String rawPath) async {
    final filePath = _cleanPath(rawPath);
    if (filePath.isEmpty) return;

    await _sendToSelectedDevices(filePath);
  }

  Future<void> _sendToSelectedDevices(String filePath) async {
    final devices = ref.read(lanManagerProvider);
    final targets = devices
        .where((d) => _selectedDeviceIds.contains(d.deviceId))
        .toList();

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择至少一个设备')),
      );
      return;
    }

    final fileName = p.basename(filePath);
    final fileSize = await File(filePath).length();

    setState(() {
      _status = SendStatus.uploading;
      _uploadFileName = fileName;
      _uploadFileSize = fileSize;
      _uploadProgress = 0;
      _errorMsg = null;
    });

    final errors = <String>[];
    int completed = 0;

    for (final device in targets) {
      try {
        await ref.read(lanManagerProvider.notifier).sendFile(device, filePath);
        completed++;
        if (mounted) {
          setState(() => _uploadProgress = completed / targets.length);
        }
      } catch (e) {
        errors.add('${device.deviceName}: $e');
      }
    }

    if (!mounted) return;

    if (errors.isNotEmpty && completed == 0) {
      setState(() {
        _status = SendStatus.error;
        _errorMsg = errors.join('\n');
      });
    } else {
      setState(() => _status = SendStatus.done);
      final msg = completed == targets.length
          ? '已发送至 $completed 台设备'
          : '已发送至 $completed/${targets.length} 台设备';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
      Future.delayed(const Duration(milliseconds: 800), _reset);
    }
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _status = SendStatus.idle;
      _errorMsg = null;
      _isPageDragging = false;
      _uploadProgress = 0;
      _uploadFileName = null;
      _uploadFileSize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;
    final devices = ref.watch(lanManagerProvider);

    // 移除不存在设备的勾选
    _selectedDeviceIds.removeWhere(
      (id) => !devices.any((d) => d.deviceId == id),
    );

    return Scaffold(
      appBar: isDesktopLayout ? null : AppBar(title: const Text('分享')),
      body: DropTarget(
        onDragEntered: (_) {
          if (_status != SendStatus.idle) return;
          setState(() => _isPageDragging = true);
        },
        onDragExited: (_) {
          if (_status != SendStatus.idle) return;
          setState(() => _isPageDragging = false);
        },
        onDragDone: (details) async {
          setState(() => _isPageDragging = false);
          if (_status != SendStatus.idle) return;
          if (details.files.isEmpty) return;
          await _handleDrop(details.files.first.path);
        },
        child: _buildBody(context, devices),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<LanDevice> devices) {
    if (_status == SendStatus.uploading) {
      return Center(
        child: SendUploadingView(
          fileName: _uploadFileName,
          fileSize: _uploadFileSize,
          progress: _uploadProgress,
        ),
      );
    }

    if (_status == SendStatus.error) {
      return Center(
        child: SendErrorView(
          errorMsg: _errorMsg ?? '未知错误',
          onRetry: _reset,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DeviceCard(
            devices: devices,
            selectedIds: _selectedDeviceIds,
            onToggle: _toggleDevice,
          ),
          const SizedBox(height: Spacing.md),
          _FileDropCard(
            isDragging: _isPageDragging,
            hasSelectedDevices: _selectedDeviceIds.isNotEmpty,
            onPickRequested: _pickAndSend,
          ),
        ],
      ),
    );
  }
}

// ─── 附近设备卡片（可勾选） ───────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final List<LanDevice> devices;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _DeviceCard({
    required this.devices,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomPaint(
      painter: DashedBorderPainter(
        color: theme.colorScheme.outlineVariant,
        strokeWidth: 1.5,
        dashWidth: 6,
        dashGap: 4,
        radius: 14,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '附近的设备',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (selectedIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '已选 ${selectedIds.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (devices.isEmpty)
              SizedBox(
                height: 72,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '正在扫描局域网设备...',
                        style: AppTextStyles.secondary(context),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: devices.map((device) {
                  final selected = selectedIds.contains(device.deviceId);
                  return _SelectableDeviceChip(
                    device: device,
                    selected: selected,
                    onTap: () => onToggle(device.deviceId),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectableDeviceChip extends StatelessWidget {
  final LanDevice device;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableDeviceChip({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForOs(device.os),
                size: 20,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                device.deviceName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
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

// ─── 文件拖入/选择卡片 ─────────────────────────────────────────

class _FileDropCard extends StatelessWidget {
  final bool isDragging;
  final bool hasSelectedDevices;
  final VoidCallback onPickRequested;

  const _FileDropCard({
    required this.isDragging,
    required this.hasSelectedDevices,
    required this.onPickRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isDragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return GestureDetector(
      onTap: onPickRequested,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: borderColor,
            strokeWidth: isDragging ? 2.0 : 1.5,
            dashWidth: 6,
            dashGap: 4,
            radius: 14,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(Spacing.xl),
            decoration: BoxDecoration(
              color: isDragging
                  ? theme.colorScheme.primary.withValues(alpha: 0.04)
                  : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDragging ? Icons.file_download : Icons.upload_file_outlined,
                  size: 48,
                  color: isDragging
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  isDragging ? '释放以发送文件' : '拖入或点击选择文件',
                  style: AppTextStyles.title(context).copyWith(
                    color: isDragging ? theme.colorScheme.primary : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasSelectedDevices
                      ? '文件将发送给已选择的设备'
                      : '请先在上方选择接收设备',
                  style: AppTextStyles.hint(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
