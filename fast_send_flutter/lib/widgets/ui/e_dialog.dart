import 'package:flutter/material.dart';

/// 应用内统一对话框：白底、蓝色主题（与分享弹窗等一致），Material 3 下去除 surface tint 发灰。
abstract final class EDialog {
  const EDialog._();

  static const EdgeInsets insetPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 24,
  );

  /// 内容区与底部按钮之间需留白：底边非 0，避免表单与 actions 挤在一起。
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(24, 20, 24, 16);

  /// 按钮行上方额外间距（Material 默认 actions 顶边为 0）。
  static const EdgeInsets actionsPadding = EdgeInsets.fromLTRB(24, 8, 24, 24);

  static double? preferredFormWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 340) return null;
    return 340;
  }

  static Widget formBody(BuildContext context, Widget child) {
    final width = preferredFormWidth(context);
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return child;
  }

  static Widget scrollableFormBody(BuildContext context, Widget child) {
    return formBody(context, SingleChildScrollView(child: child));
  }

  static Widget alert({
    Key? key,
    Widget? title,
    required Widget content,
    List<Widget>? actions,
    EdgeInsets? insetPadding,
    EdgeInsets? contentPadding,
    EdgeInsets? actionsPadding,
    AlignmentGeometry? alignment,
  }) {
    return AlertDialog(
      key: key,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: insetPadding ?? EDialog.insetPadding,
      contentPadding: contentPadding ?? EDialog.contentPadding,
      actionsPadding: actionsPadding ?? EDialog.actionsPadding,
      title: title,
      content: content,
      actions: actions,
      alignment: alignment,
    );
  }
}
