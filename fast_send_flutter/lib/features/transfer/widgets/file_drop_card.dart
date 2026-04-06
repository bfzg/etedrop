import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/clipboard_image.dart'
    show readClipboardImageBytes, saveClipboardImageBytesToTempFile;
import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui/e_button.dart';
import '../../../core/utils/file_type_icon.dart';
import '../../../core/utils/transfer_temp_cache.dart';
import '../../../styles/styles.dart';
import 'dashed_border_painter.dart';

typedef TransferSendCallback =
    Future<void> Function({
      required List<String> absoluteFilePaths,
      String? caption,
    });

/// 发送页输入区：多行文字、附件列表、剪贴板图片、拖放与多选文件，确认后由 [onSend] 发起分享。
class FileDropCard extends StatefulWidget {
  final bool hasSelectedDevices;

  /// 已选设备但均为离线
  final bool selectionOfflineOnly;
  final TransferSendCallback onSend;

  const FileDropCard({
    super.key,
    required this.hasSelectedDevices,
    this.selectionOfflineOnly = false,
    required this.onSend,
  });

  @override
  State<FileDropCard> createState() => _FileDropCardState();
}

class _FileDropCardState extends State<FileDropCard> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _attachments = [];
  bool _dragging = false;
  bool _sending = false;

  static bool get _isDesktop {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  static bool _isImagePath(String path) {
    switch (p.extension(path).toLowerCase()) {
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

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_hardwareKeyHandler);
    unawaited(pruneTransferTempCacheOlderThan(const Duration(days: 2)));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hardwareKeyHandler);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 与 TextField 不可共用同一 [FocusNode] 包一层 [Focus]，否则触发 focus_manager 断言。
  bool _hardwareKeyHandler(KeyEvent event) {
    if (!_focusNode.hasFocus) return false;
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.keyV) return false;
    if (!HardwareKeyboard.instance.isMetaPressed &&
        !HardwareKeyboard.instance.isControlPressed) {
      return false;
    }
    unawaited(_pasteImageFromClipboard());
    return false;
  }

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

  void _addPaths(Iterable<String> rawPaths) {
    final next = <String>[..._attachments];
    for (final raw in rawPaths) {
      final path = _cleanPath(raw);
      if (path.isEmpty) continue;
      if (!next.contains(path)) next.add(path);
    }
    setState(() {
      _attachments
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final paths = <String>[];
    for (final f in result.files) {
      if (f.path == null) continue;
      paths.add(_cleanPath(f.path!));
    }
    _addPaths(paths);
  }

  Future<void> _pasteImageFromClipboard() async {
    final bytes = await readClipboardImageBytes();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    try {
      final fp = await saveClipboardImageBytesToTempFile(bytes);
      _addPaths([fp]);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clipboardImageSaveFailed('$e'))),
        );
      }
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final cap = _textController.text.trim();
    var paths = List<String>.from(_attachments);

    if (paths.isEmpty && cap.isEmpty) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.enterTextOrAddFiles)));
      }
      return;
    }

    if (!widget.hasSelectedDevices) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.selectOnlineReceiversFirst)),
        );
      }
      return;
    }

    setState(() => _sending = true);
    try {
      await widget.onSend(
        absoluteFilePaths: paths,
        caption: cap.isNotEmpty ? cap : null,
      );
      if (!mounted) return;
      setState(() {
        _textController.clear();
        _attachments.clear();
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.sendFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final borderColor = _dragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) async {
        setState(() => _dragging = false);
        if (details.files.isEmpty) return;
        final paths = <String>[];
        for (final dropped in details.files) {
          paths.add(_cleanPath(dropped.path));
        }
        _addPaths(paths);
      },
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: borderColor,
          strokeWidth: _dragging ? 2.0 : 1.5,
          dashWidth: 6,
          dashGap: 4,
          radius: 14,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.md,
            Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: _dragging
                ? theme.colorScheme.primary.withValues(alpha: 0.04)
                : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_attachments.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _attachments.length; i++)
                      _AttachmentChip(
                        path: _attachments[i],
                        isImage: _isImagePath(_attachments[i]),
                        removeTooltip: l10n.removeTooltip,
                        onRemove: () =>
                            setState(() => _attachments.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
              ],
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                minLines: 3,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _isDesktop
                      ? l10n.inputHintDesktop
                      : l10n.inputHintMobile,
                  hintStyle: AppTextStyles.hint(context),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  EIconButton(
                    icon: Icons.add,
                    tooltip: l10n.addFilesTooltip,
                    onPressed: _pickFiles,
                  ),
                  const Spacer(),
                  EButton(
                    variant: EButtonVariant.primary,
                    icon: Icons.send_rounded,
                    text: _sending ? l10n.sendingButton : l10n.sendButtonLabel,
                    loading: _sending,
                    onPressed: _send,
                    radius: 99,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final String path;
  final bool isImage;
  final String removeTooltip;
  final VoidCallback onRemove;

  const _AttachmentChip({
    required this.path,
    required this.isImage,
    required this.removeTooltip,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = p.basename(path);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isImage && File(path).existsSync())
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
                child: Image.file(
                  File(path),
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  cacheWidth: 104,
                  errorBuilder: (_, _, _) => SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: 52,
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    fileTypePngForFileName(name),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.insert_drive_file_outlined,
                      size: 28,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.secondary(context),
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              tooltip: removeTooltip,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
