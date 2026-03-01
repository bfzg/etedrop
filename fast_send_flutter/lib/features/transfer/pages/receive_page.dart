import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/config/constants.dart';
import '../../../core/utils/format_utils.dart';
import '../../../styles/styles.dart';
import '../services/signaling_service.dart';
import '../../../l10n/app_localizations.dart';

/// 接收状态
enum ReceiveStatus { idle, connecting, waiting, receiving, done, error }

/// 文件接收页面
/// 对应 Electron: src/routes/download.tsx → DownloadPage
class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final _codeController = TextEditingController();
  ReceiveStatus _status = ReceiveStatus.idle;
  String? _errorMsg;
  String? _fileName;
  int _fileSize = 0;
  int _received = 0;
  double _progress = 0;
  final List<Uint8List> _chunks = [];
  SignalingService? _signaling;

  @override
  void dispose() {
    _codeController.dispose();
    _signaling?.dispose();
    super.dispose();
  }

  Future<void> _startReceive() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _status = ReceiveStatus.connecting;
      _errorMsg = null;
      _progress = 0;
      _received = 0;
      _chunks.clear();
      _fileName = null;
      _fileSize = 0;
    });

    _signaling = SignalingService(
      AppConstants.signalingServerUrl,
      callbacks: SignalingCallbacks(
        onStatusChange: (status) {
          if (!mounted) return;
          switch (status) {
            case SignalingStatus.waiting:
              setState(() => _status = ReceiveStatus.waiting);
              break;
            case SignalingStatus.error:
              setState(() => _status = ReceiveStatus.error);
              break;
            case SignalingStatus.closed:
              if (_status != ReceiveStatus.done &&
                  _status != ReceiveStatus.error) {
                setState(() => _status = ReceiveStatus.idle);
              }
              break;
            default:
              break;
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _errorMsg = err;
            _status = ReceiveStatus.error;
          });
        },
        onDataChannelOpen: () {
          if (!mounted) return;
          setState(() => _status = ReceiveStatus.waiting);
        },
        onReceive: (data, {required int size, required int duration}) async {
          if (!mounted) return;
          _handleData(data);
        },
      ),
    );

    try {
      await _signaling!.connectAsReceiver(code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _status = ReceiveStatus.error;
        });
      }
    }
  }

  void _handleData(dynamic data) {
    if (data is String) {
      try {
        final msg = jsonDecode(data) as Map<String, dynamic>;
        if (msg['type'] == 'file-meta') {
          setState(() {
            _fileName = msg['name'] as String?;
            _fileSize = (msg['size'] as num?)?.toInt() ?? 0;
            _status = ReceiveStatus.receiving;
          });
        } else if (msg['type'] == 'file-end') {
          _onFileComplete();
        }
      } catch (_) {
        // 非 JSON 字符串，忽略
      }
    } else if (data is Uint8List) {
      _chunks.add(data);
      _received += data.length;
      if (_fileSize > 0 && mounted) {
        setState(() => _progress = _received / _fileSize);
      }
    }
  }

  void _onFileComplete() {
    if (mounted) {
      setState(() {
        _progress = 1.0;
        _status = ReceiveStatus.done;
      });
    }
  }

  Future<void> _saveFile() async {
    if (_chunks.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: l10n.saveFile,
      fileName: _fileName ?? 'received_file',
    );

    if (savePath == null) return;

    final file = File(savePath);
    final sink = file.openWrite();
    for (final chunk in _chunks) {
      sink.add(chunk);
    }
    await sink.close();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fileSaved(savePath))));
    }
  }

  void _reset() {
    _signaling?.dispose();
    _signaling = null;
    _chunks.clear();
    setState(() {
      _status = ReceiveStatus.idle;
      _errorMsg = null;
      _fileName = null;
      _fileSize = 0;
      _received = 0;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      appBar: isDesktopLayout ? null : AppBar(title: Text(l10n.receiveFile)),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 输入取件码
                if (_status == ReceiveStatus.idle) ...[
                  Icon(
                    Icons.download,
                    size: 82,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  Gap.md,
                  Text(l10n.inputPickupCodeHint),
                  Gap.md,
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.pickupCode,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _startReceive(),
                    ),
                  ),
                  Gap.md,
                  FilledButton.icon(
                    onPressed: _startReceive,
                    icon: const Icon(Icons.download),
                    label: Text(l10n.startReceive),
                  ),
                ],

                // 连接中
                if (_status == ReceiveStatus.connecting) ...[
                  const CircularProgressIndicator(),
                  Gap.md,
                  Text(l10n.connecting),
                ],

                // 等待发送方
                if (_status == ReceiveStatus.waiting) ...[
                  const CircularProgressIndicator(),
                  Gap.md,
                  Text(l10n.waitingForReceiver),
                  Gap.md,
                  TextButton(onPressed: _reset, child: Text(l10n.cancel)),
                ],

                // 接收中
                if (_status == ReceiveStatus.receiving) ...[
                  if (_fileName != null)
                    Text(_fileName!, style: theme.textTheme.titleMedium),
                  if (_fileSize > 0)
                    Text(
                      '${FormatUtils.fileSize(_received)} / ${FormatUtils.fileSize(_fileSize)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  Gap.md,
                  LinearProgressIndicator(value: _progress),
                  Gap.xs,
                  Text('${(_progress * 100).toStringAsFixed(1)}%'),
                ],

                // 完成
                if (_status == ReceiveStatus.done) ...[
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  Gap.md,
                  Text(
                    l10n.receiveComplete,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_fileName != null) ...[
                    Gap.xs,
                    Text('$_fileName (${FormatUtils.fileSize(_fileSize)})'),
                  ],
                  Gap.md,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: _saveFile,
                        icon: const Icon(Icons.save),
                        label: Text(l10n.saveFile),
                      ),
                      Gap.h(Spacing.buttonGap),
                      OutlinedButton(
                        onPressed: _reset,
                        child: Text(l10n.receiveNewFile),
                      ),
                    ],
                  ),
                ],

                // 错误
                if (_status == ReceiveStatus.error) ...[
                  Icon(Icons.error, size: 64, color: theme.colorScheme.error),
                  Gap.md,
                  Text(
                    _errorMsg ?? l10n.unknownError,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
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
