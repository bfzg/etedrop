import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/reveal_file_in_explorer.dart';
import '../../contact/models/chat_message.dart';

class ChatAttachment extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;

  const ChatAttachment({super.key, required this.message, this.onDelete});

  @override
  State<ChatAttachment> createState() => _ChatAttachmentState();
}

class _ChatAttachmentState extends State<ChatAttachment> {
  Offset? _menuPosition;

  String? get _path => widget.message.localPath;

  bool get _isImage {
    final name = widget.message.fileName ?? _path ?? '';
    final ext = p.extension(name).toLowerCase();
    return const {
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.bmp',
      '.heic',
      '.heif',
    }.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onSecondaryTapDown: (details) => _menuPosition = details.globalPosition,
      onSecondaryTap: _showContextMenu,
      child: _isImage ? _buildImage(context) : _buildFileCard(context),
    );
  }

  Widget _buildImage(BuildContext context) {
    final path = _path;
    final file = path == null ? null : File(path);
    if (file == null || !file.existsSync()) {
      return _buildFileCard(context);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
        child: Image.file(file, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context) {
    final name = widget.message.fileName ?? '文件';
    return Container(
      width: 260,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDEF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatFileSize(widget.message.fileSize ?? 0),
                  style: const TextStyle(
                    color: Color(0xFF9B9CA3),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(_iconForFile(name), color: const Color(0xFFE08A2E), size: 38),
        ],
      ),
    );
  }

  Future<void> _handleTap() async {
    if (_isImage) {
      _previewImage();
      return;
    }
    await _revealInFolder();
  }

  void _previewImage() {
    final path = _path;
    if (path == null || !File(path).existsSync()) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: .5,
              maxScale: 6,
              child: Center(child: Image.file(File(path))),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showContextMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = _menuPosition ?? Offset.zero;
    final selected = await showMenu<_AttachmentAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: _AttachmentAction.reveal, child: Text('在文件夹中打开')),
        PopupMenuItem(value: _AttachmentAction.copy, child: Text('复制')),
        PopupMenuItem(value: _AttachmentAction.saveAs, child: Text('另存为')),
        PopupMenuDivider(),
        PopupMenuItem(value: _AttachmentAction.delete, child: Text('删除')),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case _AttachmentAction.reveal:
        await _revealInFolder();
      case _AttachmentAction.copy:
        await _copyFile();
      case _AttachmentAction.saveAs:
        await _saveAs();
      case _AttachmentAction.delete:
        widget.onDelete?.call();
    }
  }

  Future<void> _revealInFolder() async {
    final path = _path;
    if (path == null) return;
    final ok = await revealFileInExplorer(path);
    if (!ok) {
      await OpenFilex.open(path);
    }
  }

  Future<void> _copyFile() async {
    final path = _path;
    if (path == null || !await File(path).exists()) return;
    final ok = await Pasteboard.writeFiles([path]);
    if (!ok) {
      Pasteboard.writeText(path);
    }
  }

  Future<void> _saveAs() async {
    final path = _path;
    if (path == null) return;
    final source = File(path);
    if (!await source.exists()) return;
    final target = await FilePicker.platform.saveFile(
      fileName: widget.message.fileName ?? p.basename(path),
    );
    if (target == null || target.isEmpty) return;
    await source.copy(target);
  }

  IconData _iconForFile(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext == '.zip' || ext == '.rar' || ext == '.7z' || ext == '.tar') {
      return Icons.folder_zip_outlined;
    }
    if (ext == '.pdf') return Icons.picture_as_pdf_outlined;
    if (ext == '.mp4' || ext == '.mov' || ext == '.mkv') {
      return Icons.movie_outlined;
    }
    if (ext == '.mp3' || ext == '.wav' || ext == '.flac') {
      return Icons.audio_file_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '未知大小';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final text = value >= 10 || unit == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text ${units[unit]}';
  }
}

enum _AttachmentAction { reveal, copy, saveAs, delete }
