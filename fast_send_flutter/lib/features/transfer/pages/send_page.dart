import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/config/constants.dart';
import '../../../styles/styles.dart';
import '../../cloud/providers/cloud_provider.dart';
import '../../device/providers/device_provider.dart';
import '../../share/providers/share_provider.dart';
import '../../lan/providers/lan_provider.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/widgets/lan_device_list.dart';

import '../widgets/send_drop_area.dart';
import '../widgets/send_error_view.dart';
import '../widgets/send_shared_view.dart';
import '../widgets/send_uploading_view.dart';

enum SendStatus { idle, uploading, shared, error }

class SendPage extends ConsumerStatefulWidget {
  const SendPage({super.key});

  @override
  ConsumerState<SendPage> createState() => _SendPageState();
}

class _SendPageState extends ConsumerState<SendPage> {
  SendStatus _status = SendStatus.idle;
  String? _fileName;
  int? _fileSize;
  String? _shareLink;
  String? _shareCode;
  String? _errorMsg;
  bool _isPageDragging = false;
  double _uploadProgress = 0;

  String _cleanDroppedPath(String raw) {
    var s = raw.trim();
    if (s.length >= 2) {
      final first = s[0];
      final last = s[s.length - 1];
      final isPairedQuotes = (first == '\'' && last == '\'') || (first == '"' && last == '"');
      if (isPairedQuotes) {
        s = s.substring(1, s.length - 1).trim();
      }
    }

    // 再额外处理“只出现在一侧”的引号情况（来自拖拽的字符串经常有这种包裹）
    while (s.isNotEmpty && (s.startsWith('\'') || s.startsWith('"'))) {
      s = s.substring(1).trimLeft();
    }
    while (s.isNotEmpty && (s.endsWith('\'') || s.endsWith('"'))) {
      s = s.substring(0, s.length - 1).trimRight();
    }
    return s;
  }

  String _cleanFileName(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    if (s.length >= 2) {
      final first = s[0];
      final last = s[s.length - 1];
      final isPairedQuotes = (first == '\'' && last == '\'') || (first == '"' && last == '"');
      if (isPairedQuotes) {
        s = s.substring(1, s.length - 1).trim();
      }
    }

    while (s.isNotEmpty && (s.startsWith('\'') || s.startsWith('"'))) {
      s = s.substring(1).trimLeft();
    }
    while (s.isNotEmpty && (s.endsWith('\'') || s.endsWith('"'))) {
      s = s.substring(0, s.length - 1).trimRight();
    }

    return p.basename(s);
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    await _processFile(file.path!, file.name, file.size);
  }

  Future<void> _sendFileToLanDevice(LanDevice device) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    final cleanedFilePath = _cleanDroppedPath(file.path!);
    final cleanedFileName = _cleanFileName(file.name);

    if (cleanedFilePath.isEmpty || cleanedFileName.isEmpty) {
      setState(() {
        _status = SendStatus.error;
        _errorMsg = '无效文件路径';
      });
      return;
    }

    setState(() {
      _status = SendStatus.uploading;
      _fileName = cleanedFileName;
      _fileSize = file.size;
      _errorMsg = null;
      _uploadProgress = 0;
    });

    try {
      await ref.read(lanManagerProvider.notifier).sendFile(device, cleanedFilePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功发送至 ${device.deviceName}'),
            duration: const Duration(seconds: 2),
          ),
        );
        _reset();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = '$e';
          _status = SendStatus.error;
        });
      }
    }
  }

  Future<void> _processFile(
    String filePath,
    String fileName,
    int fileSize,
  ) async {
    final cleanedFilePath = _cleanDroppedPath(filePath);
    final cleanedFileName = _cleanFileName(fileName);

    if (cleanedFilePath.isEmpty || cleanedFileName.isEmpty) {
      setState(() {
        _status = SendStatus.error;
        _errorMsg = '无效文件路径';
      });
      return;
    }

    setState(() {
      _status = SendStatus.uploading;
      _fileName = cleanedFileName;
      _fileSize = fileSize;
      _errorMsg = null;
      _uploadProgress = 0;
    });

    String storageDir = '';
    try {
      final fileService = ref.read(fileServiceProvider);
      storageDir = fileService.storageDir;
      if (fileService.storageDir.isEmpty) {
        throw Exception('请先在网盘中设置存储目录');
      }

      final shareDir = '_shares';

      final targetPath = p.join(shareDir, cleanedFileName);
      final sourceFile = File(cleanedFilePath);
      final totalSize = await sourceFile.length();
      final targetAbsPath = fileService.resolveStoragePath(targetPath);
      // 直接确保目标文件父目录存在（避免 createDir 对某些权限/路径组合触发异常）
      await Directory(p.dirname(targetAbsPath)).create(recursive: true);
      final targetFile = File(targetAbsPath);

      final sink = targetFile.openWrite();
      int written = 0;
      await for (final chunk in sourceFile.openRead()) {
        sink.add(chunk);
        written += chunk.length;
        if (mounted) {
          setState(() => _uploadProgress = written / totalSize);
        }
      }
      await sink.close();

      if (!mounted) return;

      final notifier = ref.read(shareServiceProvider.notifier);
      await notifier.ensureInit();
      final service = ref.read(shareServiceProvider);
      final info = await service.createShare(
        targetPath,
        fileName: cleanedFileName,
        fileSize: fileSize,
      );

      ref.invalidate(shareListProvider);

      final deviceId = ref.read(deviceIdProvider);
      String? link;
      if (deviceId != null && deviceId.isNotEmpty) {
        link = '${AppConstants.shareLinkBaseUrl}/share/$deviceId/${info.code}';
      }

      if (mounted) {
        setState(() {
          _status = SendStatus.shared;
          _shareCode = info.code;
          _shareLink = link;
        });

        if (link != null) {
          await Clipboard.setData(ClipboardData(text: link));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('分享链接已复制到剪贴板'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is PathAccessException) {
            _errorMsg = '无法写入存储目录：$storageDir\n'
                '建议更换为可写入的位置（例如下载目录）后重试。\n\n'
                '$e';
          } else {
            _errorMsg = '$e';
          }
          _status = SendStatus.error;
        });
      }
    }
  }

  Future<void> _cancelShare() async {
    if (_shareCode != null) {
      try {
        final notifier = ref.read(shareServiceProvider.notifier);
        await notifier.ensureInit();
        final service = ref.read(shareServiceProvider);
        await service.deleteShare(_shareCode!);
        ref.invalidate(shareListProvider);
      } catch (_) {}
    }
    _reset();
  }

  void _reset() {
    setState(() {
      _status = SendStatus.idle;
      _fileName = null;
      _fileSize = null;
      _shareLink = null;
      _shareCode = null;
      _errorMsg = null;
      _isPageDragging = false;
      _uploadProgress = 0;
    });
  }

  void _copyLink() {
    if (_shareLink == null) return;
    Clipboard.setData(ClipboardData(text: _shareLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享链接已复制'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: isDesktopLayout ? null : AppBar(title: const Text('分享文件')),
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

          final file = details.files.first;
          final filePath = file.path;
          final cleanedFilePath = _cleanDroppedPath(filePath);
          if (cleanedFilePath.isEmpty) return;

          final size = await File(cleanedFilePath).length();
          if (!mounted) return;
          await _processFile(cleanedFilePath, p.basename(cleanedFilePath), size);
        },
        child: SizedBox.expand(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_status == SendStatus.idle) ...[
                      SendDropArea(
                        enableDropTarget: false,
                        isDraggingOverride: _isPageDragging,
                        onPickRequested: () {
                          _selectFile();
                        },
                        onFileDropped: _processFile,
                      ),
                      const SizedBox(height: 32),
                      LanDeviceList(
                        onDeviceSelected: _sendFileToLanDevice,
                      ),
                    ],
                    if (_status == SendStatus.uploading)
                      SendUploadingView(
                        fileName: _fileName,
                        fileSize: _fileSize,
                        progress: _uploadProgress,
                      ),
                    if (_status == SendStatus.shared)
                      SendSharedView(
                        fileName: _fileName,
                        fileSize: _fileSize,
                        shareLink: _shareLink,
                        onCopyLink: _copyLink,
                        onCancelShare: () {
                          _cancelShare();
                        },
                        onShareNew: _reset,
                      ),
                    if (_status == SendStatus.error)
                      SendErrorView(
                        errorMsg: _errorMsg ?? '未知错误',
                        onRetry: _reset,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
