import 'package:flutter/material.dart';

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
    return SimpleDialogOption(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: selected ? Theme.of(context).colorScheme.primary : null,
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
          if (selected)
            Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
        ],
      ),
    );
  }
}
