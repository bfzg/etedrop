import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../device/providers/device_provider.dart';

Future<void> showRenameDeviceDialog(
  BuildContext context,
  WidgetRef ref,
  String currentName,
  AppLocalizations l10n,
) async {
  final controller = TextEditingController(text: currentName);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.editDeviceName),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.inputDeviceName,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result != null && result.isNotEmpty && result != currentName) {
    await ref.read(deviceManagerProvider).setDeviceName(result);
  }
}
