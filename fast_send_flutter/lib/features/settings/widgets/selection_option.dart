import 'package:flutter/material.dart';

import '../../../core/config/styles.dart';

class SelectionOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const SelectionOption({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: selected ? AppStyles.primary : null,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
            if (selected) Icon(Icons.check, color: AppStyles.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
