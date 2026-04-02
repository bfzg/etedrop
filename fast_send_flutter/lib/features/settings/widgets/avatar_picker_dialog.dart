import 'package:flutter/material.dart';

import '../../../core/config/styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui/e_button.dart';
import '../../../widgets/ui/e_dialog.dart';
import '../../device/models/device_config.dart';

class AvatarPickerDialog extends StatefulWidget {
  final int currentAvatar;

  const AvatarPickerDialog({super.key, required this.currentAvatar});

  static Future<int?> show(BuildContext context, int currentAvatar) {
    return showDialog<int>(
      context: context,
      builder: (_) => AvatarPickerDialog(currentAvatar: currentAvatar),
    );
  }

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EDialog.alert(
      title: Text(l10n.chooseAvatar),
      content: SizedBox(
        width: 360,
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: kMemojiCount,
          itemBuilder: (context, index) {
            final avatarId = index + 1;
            final isSelected = avatarId == _selected;
            return GestureDetector(
              onTap: () => setState(() => _selected = avatarId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppStyles.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    memojiAssetPath(avatarId),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        EButton(
          text: l10n.cancel,
          variant: EButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        EButton(
          text: l10n.confirm,
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
