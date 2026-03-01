import 'package:flutter/material.dart';

/// 统一间距常量
/// 
/// 使用方式：
/// ```dart
/// const SizedBox(height: Spacing.sm),  // 12
/// const SizedBox(height: Spacing.md),  // 16
/// const SizedBox(height: Spacing.lg),  // 20
/// ```
class Spacing {
  Spacing._();

  /// 极小间距 4px
  static const double xxs = 4;

  /// 小间距 8px
  static const double xs = 8;

  /// 中小间距 12px
  static const double sm = 12;

  /// 中等间距 16px（最常用）
  static const double md = 16;

  /// 中大间距 20px
  static const double lg = 20;

  /// 大间距 24px
  static const double xl = 24;

  /// 超大间距 32px
  static const double xxl = 32;

  /// 页面内边距
  static const double pagePadding = 24;

  /// 卡片内边距
  static const double cardPadding = 20;

  /// 列表项间距
  static const double listItemGap = 8;

  /// 按钮间距
  static const double buttonGap = 12;
}

/// 间距 SizedBox 快捷方法
class Gap {
  Gap._();

  /// 水平间距
  static SizedBox h(double width) => SizedBox(width: width);

  /// 垂直间距
  static SizedBox v(double height) => SizedBox(height: height);

  /// 预设快捷间距
  static const SizedBox xxs = SizedBox(height: Spacing.xxs, width: Spacing.xxs);
  static const SizedBox xs = SizedBox(height: Spacing.xs, width: Spacing.xs);
  static const SizedBox sm = SizedBox(height: Spacing.sm, width: Spacing.sm);
  static const SizedBox md = SizedBox(height: Spacing.md, width: Spacing.md);
  static const SizedBox lg = SizedBox(height: Spacing.lg, width: Spacing.lg);
  static const SizedBox xl = SizedBox(height: Spacing.xl, width: Spacing.xl);
  static const SizedBox xxl = SizedBox(height: Spacing.xxl, width: Spacing.xxl);
}
