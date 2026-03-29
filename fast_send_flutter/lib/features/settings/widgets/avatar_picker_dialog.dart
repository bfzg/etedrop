import 'package:flutter/material.dart';

import '../../../core/config/styles.dart';
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
    return AlertDialog(
      title: const Text('选择头像'),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
