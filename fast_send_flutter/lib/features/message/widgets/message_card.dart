import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/file_type_icon.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/reveal_file_in_explorer.dart';
import '../../../styles/styles.dart';
import '../../cloud/providers/cloud_provider.dart';
import '../../device/models/device_config.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/providers/lan_provider.dart';
import '../../lan/providers/transfer_receive_speed_provider.dart';
import '../models/transfer_message.dart';
import '../providers/message_provider.dart';

class MessageCard extends ConsumerWidget {
  final TransferMessage message;

  const MessageCard({super.key, required this.message});

  static String? _trimCaption(TransferMessage m) {
    final s = m.caption?.trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static bool _isLikelyImageFileName(String name) {
    switch (p.extension(name).toLowerCase()) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.webp':
      case '.bmp':
      case '.heic':
        return true;
      default:
        return false;
    }
  }

  /// 可在卡片内直接展示正文的纯文本类附件（与 [fileTypePngForFileName] 中文本类一致）。
  static bool _isPlainTextPreviewFileName(String name) {
    switch (p.extension(name).toLowerCase()) {
      case '.txt':
      case '.md':
      case '.log':
      case '.json':
      case '.xml':
      case '.yaml':
      case '.yml':
      case '.toml':
      case '.csv':
        return true;
      default:
        return false;
    }
  }

  static List<String>? _decodedLocalPaths(TransferMessage m) {
    final raw = m.localFilePathsJson;
    if (raw == null || raw.isEmpty) return null;
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return null;
    }
  }

  static String? _pathAt(List<String>? list, int index) {
    if (list == null || index < 0 || index >= list.length) return null;
    final s = list[index];
    if (s.isEmpty) return null;
    if (File(s).existsSync()) return s;
    return null;
  }

  List<Map<String, dynamic>>? _batchFiles(TransferMessage m) {
    if (!m.isBatch || m.batchFilesJson == null) return null;
    try {
      final list = jsonDecode(m.batchFilesJson!) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  String _outgoingTargetSummary(WidgetRef ref, TransferMessage m) {
    if (!m.isOutgoing || m.targetDeviceIdsJson == null) return '';
    try {
      final ids = (jsonDecode(m.targetDeviceIdsJson!) as List)
          .map((e) => e as String)
          .toList();
      final devices = ref.watch(lanManagerProvider);
      final names = <String>[];
      for (final id in ids) {
        LanDevice? found;
        for (final d in devices) {
          if (d.deviceId == id) {
            found = d;
            break;
          }
        }
        if (found != null) names.add(found.deviceName);
      }
      if (names.isEmpty) return '${ids.length} 台设备';
      if (names.length <= 2) return names.join('、');
      return '${names.take(2).join('、')} 等 ${ids.length} 台';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final receiveSpeeds = ref.watch(transferReceiveSpeedProvider);
    final receiveSpeedKey = message.shareId ?? message.id;
    final receiveBps = !message.isOutgoing
        ? receiveSpeeds[receiveSpeedKey]
        : null;
    final isPending = message.status == TransferMessageStatus.pending;
    final showIncomingActions = isPending && !message.isOutgoing;
    final batch = _batchFiles(message);
    final canRevealInFolder = message.status == TransferMessageStatus.completed;

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: ClipOval(
                    child: Image.asset(
                      memojiAssetPath(message.senderAvatar),
                      fit: BoxFit.cover,
                      width: 46,
                      height: 46,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person,
                        size: 24,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              message.isOutgoing ? '我' : message.senderName,
                              style: AppTextStyles.secondary(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (message.isOutgoing) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '发送',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (message.isOutgoing && message.isBatch) ...[
                        const SizedBox(height: 4),
                        Text(
                          '发给 ${_outgoingTargetSummary(ref, message)}',
                          style: AppTextStyles.hint(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        FormatUtils.dateTime(message.timestamp),
                        style: AppTextStyles.secondary(context),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: message.status),
              ],
            ),
            const SizedBox(height: 12),
            if (_trimCaption(message) != null) ...[
              SelectableText(
                _trimCaption(message)!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
            ],
            if (batch != null && batch.isNotEmpty) ...[
              Text(message.fileName, style: AppTextStyles.fileName(context)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < batch.length; i++)
                    _revealableFileChip(
                      context,
                      ref,
                      theme,
                      canRevealInFolder,
                      fileIndex: i,
                      fileName: batch[i]['name'] as String? ?? '',
                      fileSize: (batch[i]['size'] as num?)?.toInt() ?? 0,
                      message: message,
                      localPreviewPath: _pathAt(_decodedLocalPaths(message), i),
                      isImage: _isLikelyImageFileName(
                        batch[i]['name'] as String? ?? '',
                      ),
                    ),
                ],
              ),
              if (batch.length == 1 &&
                  canRevealInFolder &&
                  _isPlainTextPreviewFileName(
                    batch.first['name'] as String? ?? '',
                  )) ...[
                Builder(
                  builder: (ctx) {
                    final pth = _pathAt(_decodedLocalPaths(message), 0);
                    if (pth == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _TextFilePreviewBox(path: pth),
                    );
                  },
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '合计 ${FormatUtils.fileSize(message.fileSize)}',
                style: AppTextStyles.hint(context),
              ),
            ] else if (!message.isBatch) ...[
              _revealableSingleFileBlock(
                context,
                ref,
                theme,
                canRevealInFolder,
                message: message,
                localPreviewPath: MessageCard._pathAt(
                  MessageCard._decodedLocalPaths(message),
                  0,
                ),
                isImage: MessageCard._isLikelyImageFileName(message.fileName),
              ),
            ],
            if (message.status == TransferMessageStatus.receiving) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: message.progress <= 0 ? null : message.progress,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.isOutgoing
                        ? '发送中 ${(message.progress * 100).toStringAsFixed(0)}%'
                        : '接收中 ${(message.progress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.secondary(context),
                  ),
                  if (receiveBps != null && receiveBps > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '约 ${FormatUtils.transferSpeed(receiveBps)}',
                      style: AppTextStyles.hint(context),
                    ),
                  ],
                ],
              ),
            ],
            if (message.status == TransferMessageStatus.failed &&
                message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(message.errorMessage!, style: AppTextStyles.error(context)),
            ],
            if (message.status == TransferMessageStatus.expired &&
                message.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                message.errorMessage!,
                style: AppTextStyles.secondary(context),
              ),
            ],
            if (message.isOutgoing &&
                message.status == TransferMessageStatus.pending) ...[
              const SizedBox(height: 8),
              Text('等待对方在消息内接受（2 分钟内有效）', style: AppTextStyles.hint(context)),
            ],
            if (message.isOutgoing &&
                message.status == TransferMessageStatus.expired &&
                message.localFilePathsJson != null &&
                message.targetDeviceIdsJson != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _retryOutgoingShare(context, ref, message),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试发送'),
                ),
              ),
            ],
            if (showIncomingActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      // 在首个 await 前捕获 notifier，避免异步间隙后 MessageCard 已卸载导致 ref 不可用
                      final msgNotifier = ref.read(
                        messageListProvider.notifier,
                      );
                      final lanNotifier = ref.read(lanManagerProvider.notifier);
                      if (message.isBatch && message.shareId != null) {
                        try {
                          await lanNotifier.receiverRespondToShare(
                            message,
                            false,
                          );
                        } catch (_) {}
                      }
                      msgNotifier.updateStatus(
                        message.id,
                        TransferMessageStatus.rejected,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('拒绝'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final msgNotifier = ref.read(
                        messageListProvider.notifier,
                      );
                      final lanNotifier = ref.read(lanManagerProvider.notifier);
                      if (message.isBatch && message.shareId != null) {
                        msgNotifier.updateStatus(
                          message.id,
                          TransferMessageStatus.accepted,
                        );
                        try {
                          await lanNotifier.receiverRespondToShare(
                            message,
                            true,
                          );
                          var textOnlyOffer = false;
                          final raw = message.batchFilesJson;
                          if (raw != null && raw.isNotEmpty) {
                            try {
                              final list = jsonDecode(raw) as List<dynamic>;
                              textOnlyOffer = list.isEmpty;
                            } catch (_) {}
                          }
                          if (textOnlyOffer) {
                            msgNotifier.markCompleted(message.id);
                          }
                        } catch (e) {
                          msgNotifier.updateStatus(
                            message.id,
                            TransferMessageStatus.pending,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('无法通知发送方: $e')),
                            );
                          }
                        }
                      } else {
                        msgNotifier.updateStatus(
                          message.id,
                          TransferMessageStatus.accepted,
                        );
                      }
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('接收'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<String?> _readUtf8TextPreview(String path, {int maxBytes = 32768}) async {
  try {
    final f = File(path);
    if (!await f.exists()) return null;
    final len = await f.length();
    if (len <= maxBytes) {
      return utf8.decode(await f.readAsBytes(), allowMalformed: true);
    }
    final raf = await f.open();
    try {
      final bytes = await raf.read(maxBytes);
      return '${utf8.decode(bytes, allowMalformed: true)}\n…';
    } finally {
      await raf.close();
    }
  } catch (_) {
    return null;
  }
}

Widget _messageFileTypeAssetIcon(
  BuildContext context,
  String fileName, {
  double boxSide = 40,
}) {
  final theme = Theme.of(context);
  final pad = boxSide * 0.15;
  return SizedBox(
    width: boxSide,
    height: boxSide,
    child: Padding(
      padding: EdgeInsets.all(pad),
      child: Image.asset(
        fileTypePngForFileName(fileName),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.insert_drive_file_outlined,
          size: boxSide * 0.45,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _TextFilePreviewBox extends StatefulWidget {
  final String path;

  const _TextFilePreviewBox({required this.path});

  @override
  State<_TextFilePreviewBox> createState() => _TextFilePreviewBoxState();
}

class _TextFilePreviewBoxState extends State<_TextFilePreviewBox> {
  late final Future<String?> _future = _readUtf8TextPreview(widget.path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        final t = snap.data;
        if (t == null || t.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.55,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: SelectableText(
              t,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}

Widget _revealableFileChip(
  BuildContext context,
  WidgetRef ref,
  ThemeData theme,
  bool canReveal, {
  required int fileIndex,
  required String fileName,
  required int fileSize,
  required TransferMessage message,
  String? localPreviewPath,
  bool isImage = false,
}) {
  final path = localPreviewPath;
  final thumbOk = path != null && isImage && File(path).existsSync();
  final chip = Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (thumbOk)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(path),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              cacheWidth: 80,
              errorBuilder: (_, _, _) => _messageFileTypeAssetIcon(
                context,
                fileName,
                boxSide: 40,
              ),
            ),
          )
        else
          _messageFileTypeAssetIcon(context, fileName, boxSide: 40),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Text(
          FormatUtils.fileSize(fileSize),
          style: AppTextStyles.secondary(context),
        ),
      ],
    ),
  );
  if (!canReveal) return chip;
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Tooltip(
      message: '在文件夹中显示',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMessageFileInExplorer(
            context,
            ref,
            message,
            batchIndex: fileIndex,
            batchFileName: fileName,
          ),
          borderRadius: BorderRadius.circular(8),
          child: chip,
        ),
      ),
    ),
  );
}

Widget _revealableSingleFileBlock(
  BuildContext context,
  WidgetRef ref,
  ThemeData theme,
  bool canReveal, {
  required TransferMessage message,
  String? localPreviewPath,
  bool isImage = false,
}) {
  final path = localPreviewPath;
  final thumbOk = path != null && isImage && File(path).existsSync();

  final block = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (thumbOk) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            cacheWidth: 320,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (!thumbOk)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _messageFileTypeAssetIcon(context, message.fileName, boxSide: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName,
                    style: AppTextStyles.fileName(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${FormatUtils.fileSize(message.fileSize)} · ${FormatUtils.dateTime(message.timestamp)}',
                    style: AppTextStyles.hint(context),
                  ),
                ],
              ),
            ),
          ],
        )
      else ...[
        Text(
          message.fileName,
          style: AppTextStyles.fileName(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${FormatUtils.fileSize(message.fileSize)} · ${FormatUtils.dateTime(message.timestamp)}',
          style: AppTextStyles.hint(context),
        ),
      ],
      if (canReveal &&
          path != null &&
          File(path).existsSync() &&
          MessageCard._isPlainTextPreviewFileName(message.fileName)) ...[
        const SizedBox(height: 10),
        _TextFilePreviewBox(path: path),
      ],
    ],
  );
  if (!canReveal) return block;
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Tooltip(
      message: '在文件夹中显示',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMessageFileInExplorer(context, ref, message),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: block,
          ),
        ),
      ),
    ),
  );
}

Future<void> _openMessageFileInExplorer(
  BuildContext context,
  WidgetRef ref,
  TransferMessage message, {
  int? batchIndex,
  String? batchFileName,
}) async {
  final path = await _resolveMessageLocalPath(
    ref,
    message,
    batchIndex: batchIndex,
    batchFileName: batchFileName,
  );
  if (path == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('找不到本地文件，可能已移动或删除')));
    }
    return;
  }
  final ok = await revealFileInExplorer(path);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('当前平台无法在文件夹中定位文件')));
  }
}

Future<String?> _resolveMessageLocalPath(
  WidgetRef ref,
  TransferMessage message, {
  int? batchIndex,
  String? batchFileName,
}) async {
  final raw = message.localFilePathsJson;
  if (raw != null && raw.isNotEmpty) {
    try {
      final list = List<String>.from(jsonDecode(raw) as List);
      if (batchIndex != null) {
        if (batchIndex >= 0 && batchIndex < list.length) {
          final s = list[batchIndex];
          if (s.isNotEmpty && await File(s).exists()) return s;
        }
      } else if (list.isNotEmpty) {
        for (final s in list) {
          if (s.isNotEmpty && await File(s).exists()) return s;
        }
      }
    } catch (_) {}
  }
  final name = batchFileName ?? message.fileName;
  try {
    final dir = await ref.read(downloadDirProvider.future);
    if (dir.isEmpty) return null;
    final guess = p.join(dir, name);
    if (await File(guess).exists()) return guess;
  } catch (_) {}
  return null;
}

Future<void> _retryOutgoingShare(
  BuildContext context,
  WidgetRef ref,
  TransferMessage message,
) async {
  final pathsRaw = message.localFilePathsJson;
  final idsRaw = message.targetDeviceIdsJson;
  if (pathsRaw == null || idsRaw == null) return;
  final lanNotifier = ref.read(lanManagerProvider.notifier);
  try {
    final paths = (jsonDecode(pathsRaw) as List)
        .map((e) => e as String)
        .toList();
    final ids = (jsonDecode(idsRaw) as List).map((e) => e as String).toList();
    final existing = <String>[];
    for (final p in paths) {
      if (await File(p).exists()) {
        existing.add(p);
      }
    }
    if (existing.isEmpty) {
      final capOnly = message.caption?.trim();
      if (capOnly != null &&
          capOnly.isNotEmpty &&
          ids.isNotEmpty) {
        await lanNotifier.startBatchShare(
          absoluteFilePaths: const [],
          targetDeviceIds: ids,
          caption: capOnly,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已重新发起分享')));
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('本地文件已不存在或已移动，无法重试')));
      }
      return;
    }
    if (ids.isEmpty) return;
    final cap = message.caption?.trim();
    await lanNotifier.startBatchShare(
      absoluteFilePaths: existing,
      targetDeviceIds: ids,
      caption: cap != null && cap.isNotEmpty ? cap : null,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已重新发起分享')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重试失败: $e')));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TransferMessageStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TransferMessageStatus.pending => (
        '待处理',
        Theme.of(context).colorScheme.primary,
      ),
      TransferMessageStatus.accepted => ('已接受', Colors.green),
      TransferMessageStatus.receiving => (
        '接收中',
        Theme.of(context).colorScheme.primary,
      ),
      TransferMessageStatus.completed => ('已完成', Colors.green),
      TransferMessageStatus.rejected => (
        '已拒绝',
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      TransferMessageStatus.failed => (
        '失败',
        Theme.of(context).colorScheme.error,
      ),
      TransferMessageStatus.expired => (
        '已过期',
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
