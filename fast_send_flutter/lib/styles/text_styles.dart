import 'package:flutter/material.dart';

/// 统一文字样式
/// 
/// 使用方式：
/// ```dart
/// Text('标题', style: AppTextStyles.title(context)),
/// Text('描述', style: AppTextStyles.hint(context)),
/// ```
class AppTextStyles {
  AppTextStyles._();

  /// 页面标题 - 大号、主色
  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );

  /// 提示文字 - 中号、淡色
  static TextStyle hint(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 16,
          );

  /// 次要文字 - 小号、淡色
  static TextStyle secondary(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 14,
          );

  /// 错误文字
  static TextStyle error(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.error,
          );

  /// 成功文字
  static TextStyle success(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Colors.green,
          );

  /// 文件名 - 中号、加粗
  static TextStyle fileName(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w500,
          );

  /// 文件大小 - 小号
  static TextStyle fileSize(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;

  /// 取件码 - 大号、加粗、字母间距
  static TextStyle pickupCode(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          );

  /// 完成标题 - 大号、加粗
  static TextStyle completeTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          );
}
