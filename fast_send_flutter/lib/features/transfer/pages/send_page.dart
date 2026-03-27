import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

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
  bool _isPageDragging = false;
  final Set<String> _selectedDeviceIds = {};
  final List<String> _pendingPaths = [];

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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    final added = <String>[];
    for (final f in result.files) {
      if (f.path == null) continue;
      final filePath = _cleanPath(f.path!);
      if (filePath.isEmpty) continue;
      if (!_pendingPaths.contains(filePath)) {
        added.add(filePath);
      }
    }
    if (added.isEmpty) return;
    setState(() => _pendingPaths.addAll(added));
  }

  Future<void> _handleDropFile(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    final added = <String>[];
    for (final dropped in details.files) {
      final path = _cleanPath(dropped.path);
      if (path.isEmpty) continue;
      if (!_pendingPaths.contains(path)) {
        added.add(path);
      }
    }
    if (added.isEmpty) return;
    setState(() => _pendingPaths.addAll(added));
  }

  void _removePendingAt(int index) {
    setState(() => _pendingPaths.removeAt(index));
  }

  void _clearPending() {
    setState(() => _pendingPaths.clear());
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
      ref.read(lanManagerProvider.notifier).cancelOutgoingShare(
            id,
            userCancelled: true,
          );
    }
    _clearActiveShareState();
  }

  Future<void> _startLanShare() async {
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
    if (_pendingPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择或拖入至少一个文件')),
      );
      return;
    }

    final prevId = _activeShareId;
    if (prevId != null) {
      ref.read(lanManagerProvider.notifier).cancelOutgoingShare(
            prevId,
            userCancelled: true,
          );
      _clearActiveShareState();
    }

    try {
      final id = await ref.read(lanManagerProvider.notifier).startBatchShare(
            absoluteFilePaths: List<String>.from(_pendingPaths),
            targetDeviceIds: targets.map((d) => d.deviceId).toList(),
          );
      if (!mounted) return;
      setState(() {
        _pendingPaths.clear();
        _activeShareId = id;
        _activeExpiresAt = DateTime.now().add(const Duration(minutes: 2));
        _activeRecipients = List<LanDevice>.from(targets);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已发送分享邀请，对方在消息里接受后开始传输')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发起失败: $e')),
        );
      }
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
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isPageDragging = true),
        onDragExited: (_) => setState(() => _isPageDragging = false),
        onDragDone: (details) async {
          setState(() => _isPageDragging = false);
          await _handleDropFile(details);
        },
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final hasActive = _activeShareId != null && _activeExpiresAt != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            // padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: NearbyDeviceGrid(
              selectedIds: _selectedDeviceIds,
              onToggle: _toggleDevice,
            ),
          ),
          const SizedBox(height: Spacing.md),
          FileDropCard(
            isDragging: _isPageDragging,
            hasSelectedDevices: _selectedDeviceIds.isNotEmpty,
            selectedFileCount:
                _pendingPaths.isEmpty ? null : _pendingPaths.length,
            addToQueueMode: true,
            onPickRequested: _pickFiles,
          ),
          if (_pendingPaths.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            _PendingFilesList(
              paths: _pendingPaths,
              onRemove: _removePendingAt,
              onClear: _clearPending,
            ),
          ],
          const SizedBox(height: Spacing.lg),
          FilledButton.icon(
            onPressed: (_selectedDeviceIds.isEmpty || _pendingPaths.isEmpty)
                ? null
                : _startLanShare,
            icon: const Icon(Icons.share_outlined),
            label: Text(
              hasActive ? '重新发起分享（将结束当前会话）' : '发起局域网分享',
            ),
          ),
          if (hasActive) ...[
            const SizedBox(height: Spacing.md),
            LanSharePanel(
              shareId: _activeShareId!,
              expiresAt: _activeExpiresAt!,
              recipients: _activeRecipients,
              onCancel: _cancelShare,
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

class _PendingFilesList extends StatelessWidget {
  final List<String> paths;
  final void Function(int index) onRemove;
  final VoidCallback onClear;

  const _PendingFilesList({
    required this.paths,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '待发送文件',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClear,
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: paths.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.basename(paths[i]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => onRemove(i),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
