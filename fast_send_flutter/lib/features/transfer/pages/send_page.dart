import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/constants.dart';
import '../../../core/utils/format_utils.dart';
import '../../../styles/styles.dart';
import '../services/signaling_service.dart';
import '../../../l10n/app_localizations.dart';

/// 发送状态
enum SendStatus {
  idle,
  selectingFile,
  connecting,
  waiting,
  paired,
  transferring,
  done,
  error,
}

/// 文件发送页面
/// 对应 Electron: src/routes/send.tsx → SendPage
class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  SendStatus _status = SendStatus.idle;
  String? _filePath;
  String? _fileName;
  int? _fileSize;
  String? _code;
  String? _errorMsg;
  double _progress = 0;
  SignalingService? _signaling;

  @override
  void dispose() {
    _signaling?.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    setState(() => _status = SendStatus.selectingFile);

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) {
      setState(() => _status = SendStatus.idle);
      return;
    }

    final file = result.files.first;
    if (file.path == null) {
      setState(() => _status = SendStatus.idle);
      return;
    }

    setState(() {
      _filePath = file.path;
      _fileName = file.name;
      _fileSize = file.size;
      _status = SendStatus.idle;
    });
  }

  Future<void> _startSend() async {
    if (_filePath == null) return;

    setState(() {
      _status = SendStatus.connecting;
      _errorMsg = null;
      _progress = 0;
    });

    _signaling = SignalingService(
      AppConstants.signalingServerUrl,
      callbacks: SignalingCallbacks(
        onStatusChange: (status) {
          if (!mounted) return;
          switch (status) {
            case SignalingStatus.waiting:
              setState(() => _status = SendStatus.waiting);
              break;
            case SignalingStatus.paired:
              setState(() => _status = SendStatus.paired);
              break;
            case SignalingStatus.error:
              setState(() => _status = SendStatus.error);
              break;
            case SignalingStatus.closed:
              if (_status != SendStatus.done && _status != SendStatus.error) {
                setState(() => _status = SendStatus.idle);
              }
              break;
            default:
              break;
          }
        },
        onCode: (code) {
          if (!mounted) return;
          setState(() => _code = code);
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _errorMsg = err;
            _status = SendStatus.error;
          });
        },
        onDataChannelOpen: () {
          if (!mounted) return;
          _doTransfer();
        },
      ),
    );

    try {
      await _signaling!.connectAsSender();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _status = SendStatus.error;
        });
      }
    }
  }

  Future<void> _doTransfer() async {
    if (_filePath == null || _signaling == null) return;

    setState(() => _status = SendStatus.transferring);

    try {
      // 发送文件元信息
      final metaJson =
          '{"type":"file-meta","name":"$_fileName","size":$_fileSize}';
      await _signaling!.sendData(metaJson);

      // 读取并分块发送
      final file = File(_filePath!);
      final totalSize = await file.length();
      int sent = 0;

      final stream = file.openRead();
      await for (final chunk in stream) {
        await _signaling!.sendData(Uint8List.fromList(chunk));
        sent += chunk.length;
        if (mounted) {
          setState(() => _progress = sent / totalSize);
        }
      }

      // 发送完成标记
      await _signaling!.sendData('{"type":"file-end"}');

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _status = SendStatus.done;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = '传输失败: $e';
          _status = SendStatus.error;
        });
      }
    }
  }

  void _reset() {
    _signaling?.dispose();
    _signaling = null;
    setState(() {
      _status = SendStatus.idle;
      _filePath = null;
      _fileName = null;
      _fileSize = null;
      _code = null;
      _errorMsg = null;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: isDesktopLayout ? null : AppBar(title: Text(l10n.sendFile)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 文件选择区域
                if (_status == SendStatus.idle ||
                    _status == SendStatus.selectingFile) ...[
                  Icon(
                    Icons.upload_file_outlined,
                    size: 82,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  Gap.md,
                  if (_fileName != null) ...[
                    Text(_fileName!, style: AppTextStyles.fileName(context)),
                    Text(
                      FormatUtils.fileSize(_fileSize ?? 0),
                      style: AppTextStyles.fileSize(context),
                    ),
                    Gap.md,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: _selectFile,
                          child: Text(l10n.reselect),
                        ),
                        Gap.h(Spacing.buttonGap),
                        FilledButton.icon(
                          onPressed: _startSend,
                          icon: const Icon(Icons.send),
                          label: Text(l10n.startSend),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(l10n.selectFileToSend, style: AppTextStyles.title(context)),
                    Gap.xs,
                    Text('点击上传或将文件拖拽到此处', style: AppTextStyles.hint(context)),
                    Gap.md,
                    FilledButton.icon(
                      onPressed: _selectFile,
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(l10n.selectFile),
                    ),
                  ],
                ],

                // 连接中
                if (_status == SendStatus.connecting) ...[
                  const CircularProgressIndicator(),
                  Gap.md,
                  Text(l10n.connecting),
                ],

                // 等待接收方
                if (_status == SendStatus.waiting && _code != null) ...[
                  Icon(
                    Icons.qr_code,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  Gap.md,
                  Text(l10n.pickupCode),
                  Gap.xs,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xl,
                      vertical: Spacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_code!, style: AppTextStyles.pickupCode(context)),
                        Gap.h(Spacing.sm),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _code!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.copied),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Gap.md,
                  Text(
                    l10n.waitingForReceiver,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Gap.xl,
                  TextButton(onPressed: _reset, child: Text(l10n.cancel)),
                ],

                // 传输中
                if (_status == SendStatus.transferring) ...[
                  Text(_fileName ?? '', style: AppTextStyles.fileName(context)),
                  Gap.md,
                  LinearProgressIndicator(value: _progress),
                  Gap.xs,
                  Text('${(_progress * 100).toStringAsFixed(1)}%'),
                ],

                // 完成
                if (_status == SendStatus.done) ...[
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  Gap.md,
                  Text(l10n.sendComplete, style: AppTextStyles.completeTitle(context)),
                  Gap.xl,
                  FilledButton(
                    onPressed: _reset,
                    child: Text(l10n.sendNewFile),
                  ),
                ],

                // 错误
                if (_status == SendStatus.error) ...[
                  Icon(Icons.error, size: 64, color: theme.colorScheme.error),
                  Gap.md,
                  Text(_errorMsg ?? l10n.unknownError, style: AppTextStyles.error(context)),
                  Gap.md,
                  FilledButton(onPressed: _reset, child: Text(l10n.retry)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
