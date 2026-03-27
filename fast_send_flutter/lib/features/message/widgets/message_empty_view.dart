import 'package:flutter/material.dart';

import '../../../styles/styles.dart';

class MessageEmptyView extends StatelessWidget {
  const MessageEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
              alpha: 0.3,
            ),
          ),
          Gap.md,
          Text('暂无消息', style: AppTextStyles.hint(context)),
          Gap.xs,
          Text('当有设备向你发送文件时，会在这里显示', style: AppTextStyles.secondary(context)),
        ],
      ),
    );
  }
}

