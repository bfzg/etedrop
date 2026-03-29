import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui/e_button.dart';
import '../../../widgets/ui/e_dialog.dart';
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
    builder: (ctx) => EDialog.alert(
      title: Text(l10n.editDeviceName),
      content: EDialog.formBody(
        ctx,
        TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.inputDeviceName,
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(ctx).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
      actions: [
        EButton(
          text: l10n.cancel,
          variant: EButtonVariant.secondary,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        EButton(
          text: l10n.confirm,
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result != null && result.isNotEmpty && result != currentName) {
    await ref.read(deviceManagerProvider).setDeviceName(result);
  }
}
