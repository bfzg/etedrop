import 'package:flutter/material.dart';

class MessageAvatar extends StatelessWidget {
  final int avatar;
  final double size;

  const MessageAvatar({super.key, required this.avatar, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/memoji/$avatar.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.person, size: size * .55),
        ),
      ),
    );
  }
}
