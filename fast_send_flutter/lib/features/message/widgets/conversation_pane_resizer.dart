import 'package:flutter/material.dart';

class ConversationPaneResizer extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const ConversationPaneResizer({super.key, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: .55);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: SizedBox(
          width: 1,
          child: Center(child: Container(width: 1, color: color)),
        ),
      ),
    );
  }
}
