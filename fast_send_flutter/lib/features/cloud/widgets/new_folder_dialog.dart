import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui/e_dialog.dart';
import '../../../widgets/ui/e_button.dart';

/// 新建文件夹对话框
/// 对应 Electron: src/components/cloud/new-folder-dialog.tsx
class NewFolderDialog extends StatefulWidget {
  final Future<void> Function(String name) onConfirm;

  const NewFolderDialog({super.key, required this.onConfirm});

  @override
  State<NewFolderDialog> createState() => _NewFolderDialogState();

  static Future<void> show(
    BuildContext context,
    Future<void> Function(String name) onConfirm,
  ) {
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
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.folderNameEmpty);
      return;
    }
    if (name.contains('/') || name.contains('\\')) {
      setState(() => _error = l10n.folderNameInvalidChars);
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
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        setState(() => _error = loc.createFolderFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenW = MediaQuery.sizeOf(context).width;
    // Slightly wider than the global default to better fit the input.
    final formWidth = screenW >= 420 ? 380.0 : null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.folderNameHint,
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _handleConfirm(),
        ),
      ],
    );

    return EDialog.alert(
      title: Text(l10n.newFolderDialogTitle),
      content: formWidth != null ? SizedBox(width: formWidth, child: content) : content,
      actions: [
        EButton(
          text: l10n.cancel,
          variant: EButtonVariant.secondary,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
        EButton(
          text: l10n.createFolderButton,
          loading: _loading,
          onPressed: _loading ? null : _handleConfirm,
        ),
      ],
    );
  }
}
