import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../styles/styles.dart';
import '../../lan/providers/lan_provider.dart';
import '../widgets/file_drop_card.dart';
import '../widgets/send_error_view.dart';
import '../widgets/send_uploading_view.dart';
import '../widgets/nearby_device_grid.dart';

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

  Future<void> _handleDropFile(DropDoneDetails details) async {
    if (details.files.isEmpty) return;

    final dropped = details.files.first;
    final droppedPath = _cleanPath(dropped.path);
    if (droppedPath.isEmpty) return;

    final fileName = p.basename(droppedPath);
    final fileSize = await dropped.length();

    await _sendDroppedToSelectedDevices(
      fileName: fileName,
      fileSize: fileSize,
      openRead: () => dropped.openRead(),
    );
  }

  Future<void> _sendToSelectedDevices(String filePath) async {
    final devices = ref.read(lanManagerProvider);
    final targets = devices
        .where((d) => _selectedDeviceIds.contains(d.deviceId))
        .toList();

    if (targets.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择至少一个设备')));
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

  Future<void> _sendDroppedToSelectedDevices({
    required String fileName,
    required int fileSize,
    required Stream<List<int>> Function() openRead,
  }) async {
    final devices = ref.read(lanManagerProvider);
    final targets = devices
        .where((d) => _selectedDeviceIds.contains(d.deviceId))
        .toList();

    if (targets.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择至少一个设备')));
      return;
    }

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
        await ref.read(lanManagerProvider.notifier).sendFileStream(
              device,
              fileStream: openRead(),
              fileName: fileName,
              fileSize: fileSize,
            );
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
          await _handleDropFile(details);
        },
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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
        child: SendErrorView(errorMsg: _errorMsg ?? '未知错误', onRetry: _reset),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 设备卡片 — 虚线边框
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: NearbyDeviceGrid(
              selectedIds: _selectedDeviceIds,
              onToggle: _toggleDevice,
            ),
          ),
          const SizedBox(height: Spacing.md),
          // 文件拖入卡片 — 虚线边框
          FileDropCard(
            isDragging: _isPageDragging,
            hasSelectedDevices: _selectedDeviceIds.isNotEmpty,
            onPickRequested: _pickAndSend,
          ),
        ],
      ),
    );
  }
}
