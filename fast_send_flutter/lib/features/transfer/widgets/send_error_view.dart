import 'package:flutter/material.dart';

import '../../../styles/styles.dart';

class SendErrorView extends StatelessWidget {
  final String errorMsg;
  final VoidCallback onRetry;

  const SendErrorView({
    super.key,
    required this.errorMsg,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
        Gap.md,
        Text(
          errorMsg,
          style: AppTextStyles.error(context),
          textAlign: TextAlign.center,
        ),
        Gap.md,
        FilledButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}

