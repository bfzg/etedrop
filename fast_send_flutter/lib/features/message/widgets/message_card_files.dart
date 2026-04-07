import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/file_type_icon.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/reveal_file_in_explorer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../styles/styles.dart';
import '../../cloud/providers/cloud_provider.dart';
import '../models/transfer_message.dart';
import 'message_card_utils.dart';

Future<String?> readUtf8TextPreview(String path, {int maxBytes = 32768}) async {
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

Widget messageFileTypeAssetIcon(
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

class TextFilePreviewBox extends StatefulWidget {
  final String path;

  const TextFilePreviewBox({super.key, required this.path});

  @override
  State<TextFilePreviewBox> createState() => _TextFilePreviewBoxState();
}

class _TextFilePreviewBoxState extends State<TextFilePreviewBox> {
  late final Future<String?> _future = readUtf8TextPreview(widget.path);

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

Widget revealableFileChip(
  BuildContext context,
  WidgetRef ref,
  ThemeData theme,
  AppLocalizations l10n,
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
      children: [
        if (thumbOk)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(path),
              key: ValueKey(path),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              cacheWidth: 80,
              errorBuilder: (_, _, _) => messageFileTypeAssetIcon(
                context,
                fileName,
                boxSide: 40,
              ),
            ),
          )
        else
          messageFileTypeAssetIcon(context, fileName, boxSide: 40),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.fileName(context),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          FormatUtils.fileSize(fileSize),
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: AppTextStyles.secondary(context),
        ),
      ],
    ),
  );
  if (!canReveal) return chip;
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Tooltip(
      message: l10n.showInFolder,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openMessageFileInExplorer(
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

Widget revealableSingleFileBlock(
  BuildContext context,
  WidgetRef ref,
  ThemeData theme,
  AppLocalizations l10n,
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
            key: ValueKey(path),
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
            messageFileTypeAssetIcon(context, message.fileName, boxSide: 44),
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
          isPlainTextPreviewFileName(message.fileName)) ...[
        const SizedBox(height: 10),
        TextFilePreviewBox(path: path),
      ],
    ],
  );
  if (!canReveal) return block;
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Tooltip(
      message: l10n.showInFolder,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openMessageFileInExplorer(context, ref, message),
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

Future<void> openMessageFileInExplorer(
  BuildContext context,
  WidgetRef ref,
  TransferMessage message, {
  int? batchIndex,
  String? batchFileName,
}) async {
  final path = await resolveMessageLocalPath(
    ref,
    message,
    batchIndex: batchIndex,
    batchFileName: batchFileName,
  );
  if (path == null) {
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileNotFoundMaybeMoved)),
      );
    }
    return;
  }
  final ok = await revealFileInExplorer(path);
  if (!ok && context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.revealInFolderNotSupported)),
    );
  }
}

Future<String?> resolveMessageLocalPath(
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
