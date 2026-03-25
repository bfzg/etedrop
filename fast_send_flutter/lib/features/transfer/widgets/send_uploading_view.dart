import 'package:flutter/material.dart';

import '../../../core/utils/format_utils.dart';
import '../../../styles/styles.dart';

class SendUploadingView extends StatelessWidget {
  final String? fileName;
  final int? fileSize;
  final double progress;

  const SendUploadingView({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          Gap.md,
          if (fileName != null) Text(fileName!, style: AppTextStyles.fileName(context)),
          if (fileSize != null && fileSize! > 0)
            Text(
              FormatUtils.fileSize(fileSize!),
              style: AppTextStyles.fileSize(context),
            ),
          Gap.md,
          LinearProgressIndicator(value: progress),
          Gap.xs,
          Text(
            '正在处理... ${(progress * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.hint(context),
          ),
        ],
      ),
    );
  }
}

