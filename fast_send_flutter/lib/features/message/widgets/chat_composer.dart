import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../core/utils/clipboard_image.dart';
import '../../../core/utils/transfer_temp_cache.dart';

class ChatComposer extends StatefulWidget {
  final Future<void> Function({required List<String> paths, String? caption})
  onSend;

  const ChatComposer({super.key, required this.onSend});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _paths = <String>[];
  bool _dragging = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    unawaited(pruneTransferTempCacheOlderThan(const Duration(days: 2)));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _clean(String raw) {
    var value = raw.trim();
    if (value.length > 1 &&
        ((value.startsWith("'") && value.endsWith("'")) ||
            (value.startsWith('"') && value.endsWith('"')))) {
      value = value.substring(1, value.length - 1).trim();
    }
    return value;
  }

  void _addPaths(Iterable<String> values) {
    final next = [..._paths];
    for (final value in values) {
      final path = _clean(value);
      if (path.isNotEmpty && !next.contains(path)) next.add(path);
    }
    setState(() {
      _paths
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    _addPaths(
      result.files.where((file) => file.path != null).map((file) => file.path!),
    );
  }

  Future<void> _pasteImage() async {
    final bytes = await readClipboardImageBytes();
    if (!mounted || bytes == null || bytes.isEmpty) return;
    final path = await saveClipboardImageBytesToTempFile(bytes);
    if (mounted) _addPaths([path]);
  }

  void _insertNewline() {
    final value = _text.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length)
        : text.length;
    final end = selection.isValid ? selection.end.clamp(0, text.length) : start;
    _text.value = value.copyWith(
      text: '${text.substring(0, start)}\n${text.substring(end)}',
      selection: TextSelection.collapsed(offset: start + 1),
      composing: TextRange.empty,
    );
  }

  Future<void> _send() async {
    if (_sending) return;
    final caption = _text.text.trim();
    if (_paths.isEmpty && caption.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(
        paths: List<String>.from(_paths),
        caption: caption.isEmpty ? null : caption,
      );
      if (!mounted) return;
      _text.clear();
      setState(() => _paths.clear());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        _addPaths(details.files.map((file) => file.path));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 220,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        decoration: BoxDecoration(
          color: _dragging
              ? theme.colorScheme.primary.withValues(alpha: .04)
              : theme.colorScheme.surface,
          border: Border.all(
            color: _dragging
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: _dragging ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final inputWidth = _paths.isEmpty
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 196).clamp(
                          260.0,
                          constraints.maxWidth,
                        );
                  return SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (var i = 0; i < _paths.length; i++)
                            _AttachmentPreview(
                              path: _paths[i],
                              onRemove: () =>
                                  setState(() => _paths.removeAt(i)),
                            ),
                          SizedBox(
                            width: inputWidth,
                            child: CallbackShortcuts(
                              bindings: {
                                const SingleActivator(
                                  LogicalKeyboardKey.enter,
                                ): () =>
                                    unawaited(_send()),
                                const SingleActivator(
                                  LogicalKeyboardKey.enter,
                                  meta: true,
                                ): _insertNewline,
                                const SingleActivator(
                                  LogicalKeyboardKey.enter,
                                  control: true,
                                ): _insertNewline,
                              },
                              child: TextField(
                                controller: _text,
                                focusNode: _focus,
                                minLines: _paths.isEmpty ? 3 : 1,
                                maxLines: 8,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText: _paths.isEmpty
                                      ? '输入消息，或拖入文件'
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: .7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: '表情',
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {
                    final value = _text.value;
                    _text.value = value.copyWith(
                      text: '${value.text}🙂',
                      selection: TextSelection.collapsed(
                        offset: value.text.length + 2,
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: '选择文件',
                  icon: const Icon(Icons.folder_outlined),
                  onPressed: _pickFiles,
                ),
                IconButton(
                  tooltip: '粘贴图片',
                  icon: const Icon(Icons.content_paste_outlined),
                  onPressed: _pasteImage,
                ),
                const Spacer(),
                TDButton(
                  type: TDButtonType.fill,
                  size: TDButtonSize.small,
                  disabled: _sending,
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 7),
                  onTap: _sending ? null : _send,
                  text: '发送',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _AttachmentPreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final image =
        file.existsSync() &&
        [
          '.png',
          '.jpg',
          '.jpeg',
          '.gif',
          '.webp',
          '.bmp',
          '.heic',
        ].contains(p.extension(path).toLowerCase());
    return Container(
      width: 180,
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (image)
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.file(file, width: 48, height: 48, fit: BoxFit.cover),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.insert_drive_file_outlined),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              p.basename(path),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: '移除',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            iconSize: 16,
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
