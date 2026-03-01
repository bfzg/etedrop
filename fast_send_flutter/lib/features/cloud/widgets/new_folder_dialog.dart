import 'package:flutter/material.dart';

/// 新建文件夹对话框
/// 对应 Electron: src/components/cloud/new-folder-dialog.tsx
class NewFolderDialog extends StatefulWidget {
  final Future<void> Function(String name) onConfirm;

  const NewFolderDialog({super.key, required this.onConfirm});

  @override
  State<NewFolderDialog> createState() => _NewFolderDialogState();

  static Future<void> show(BuildContext context, Future<void> Function(String name) onConfirm) {
    return showDialog(
      context: context,
      builder: (_) => NewFolderDialog(onConfirm: onConfirm),
    );
  }
}

class _NewFolderDialogState extends State<NewFolderDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入文件夹名称');
      return;
    }
    if (name.contains('/') || name.contains('\\')) {
      setState(() => _error = '文件夹名称不能包含 / 或 \\');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onConfirm(name);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '创建失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建文件夹'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '文件夹名称',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _handleConfirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _loading ? null : _handleConfirm,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('创建'),
        ),
      ],
    );
  }
}
