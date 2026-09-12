import 'package:flutter/material.dart';

import '../../core/config/styles.dart';

/// 应用内统一按钮样式。
///
/// - [primary]：主操作，蓝底白字。
/// - [secondary]：次要实心，灰底。
/// - [tonal]：浅底强调（如「关闭」）。
/// - [outlined]：线框 + 主色（如「复制」）；[destructive] 时为错误色线框。
/// - [text]：文本按钮；[destructive] 时为错误色文案。
/// - [danger]：危险实心（删除等）。
enum EButtonVariant {
  primary,
  secondary,
  tonal,
  outlined,
  text,
  danger,
  subtle,
}

/// 按钮尺寸预设（影响最小高度、内边距、圆角、字号与图标）。
enum EButtonSize {
  /// 紧凑：辅助操作、密集列表。
  sm,

  /// 默认（约 44 逻辑像素高）。
  md,

  /// 大号：强调主操作、大触控区。
  lg,
}

class _EButtonSizeSpec {
  final double minHeight;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;
  final double progressSide;
  final double progressStroke;
  final double gapAfterProgress;
  final double gapIconText;

  const _EButtonSizeSpec({
    required this.minHeight,
    required this.radius,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.progressSide,
    required this.progressStroke,
    required this.gapAfterProgress,
    required this.gapIconText,
  });

  static _EButtonSizeSpec of(EButtonSize s) {
    return switch (s) {
      EButtonSize.sm => _sm,
      EButtonSize.md => _md,
      EButtonSize.lg => _lg,
    };
  }

  static const _sm = _EButtonSizeSpec(
    minHeight: 34,
    radius: 8,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    fontSize: 13,
    iconSize: 16,
    progressSide: 14,
    progressStroke: 2,
    gapAfterProgress: 8,
    gapIconText: 6,
  );

  static const _md = _EButtonSizeSpec(
    minHeight: 44,
    radius: 10,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    fontSize: 15,
    iconSize: 18,
    progressSide: 16,
    progressStroke: 2,
    gapAfterProgress: 10,
    gapIconText: 8,
  );

  static const _lg = _EButtonSizeSpec(
    minHeight: 52,
    radius: 12,
    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    fontSize: 16,
    iconSize: 20,
    progressSide: 18,
    progressStroke: 2,
    gapAfterProgress: 10,
    gapIconText: 8,
  );
}

class EButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final EButtonVariant variant;

  /// 尺寸预设；[height]、[radius]、[padding] 非空时覆盖对应项。
  final EButtonSize size;

  final double? height;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;

  /// 用于 [outlined] / [text]：拒绝、取消分享等。
  final bool destructive;

  const EButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.variant = EButtonVariant.primary,
    this.size = EButtonSize.md,
    this.height,
    this.radius,
    this.padding,
    this.icon,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spec = _EButtonSizeSpec.of(size);
    final effectiveHeight = height ?? spec.minHeight;
    final effectiveRadius = radius ?? spec.radius;
    final effectivePadding = padding ?? spec.padding;
    final effectiveOnPressed = loading ? null : onPressed;

    final primaryFg = destructive ? scheme.error : AppStyles.primary;

    TextStyle labelStyle(Color fg) => theme.textTheme.bodyMedium!.copyWith(
      fontSize: spec.fontSize,
      fontWeight: FontWeight.w500,
      color: fg,
    );

    Widget labelRow({required Color fg}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: spec.progressSide,
              height: spec.progressSide,
              child: CircularProgressIndicator(
                strokeWidth: spec.progressStroke,
                color: fg,
              ),
            ),
            SizedBox(width: spec.gapAfterProgress),
          ] else if (icon != null) ...[
            Icon(icon, size: spec.iconSize, color: fg),
            SizedBox(width: spec.gapIconText),
          ],
          Text(text, style: labelStyle(fg)),
        ],
      );
    }

    final minSize = Size(0, effectiveHeight);

    switch (variant) {
      case EButtonVariant.subtle:
        final bg = WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled))
            return const Color(0xFFE5E5E8);
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed))
            return const Color(0xFFD6D6DA);
          return const Color(0xFFEDEDF1);
        });
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: effectiveHeight),
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ButtonStyle(
              elevation: const WidgetStatePropertyAll(0),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              backgroundColor: bg,
              foregroundColor: const WidgetStatePropertyAll(Colors.black),
              padding: WidgetStatePropertyAll(effectivePadding),
              minimumSize: WidgetStatePropertyAll(minSize),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(effectiveRadius),
                ),
              ),
            ),
            child: labelRow(fg: Colors.black),
          ),
        );
      case EButtonVariant.primary:
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: effectiveHeight),
          child: FilledButton(
            onPressed: effectiveOnPressed,
            style:
                FilledButton.styleFrom(
                  backgroundColor: AppStyles.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppStyles.primary.withValues(
                    alpha: 0.38,
                  ),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                  padding: effectivePadding,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  minimumSize: minSize,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(effectiveRadius),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.white.withValues(alpha: 0.12);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.white.withValues(alpha: 0.08);
                    }
                    return null;
                  }),
                ),
            child: labelRow(fg: Colors.white),
          ),
        );

      case EButtonVariant.secondary:
        final bg = scheme.surfaceContainerHighest;
        final fg = scheme.onSurface;
        final border = scheme.outlineVariant;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: effectiveHeight),
          child: FilledButton(
            onPressed: effectiveOnPressed,
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: effectivePadding,
              elevation: 0,
              minimumSize: minSize,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
                side: BorderSide(color: border),
              ),
            ),
            child: labelRow(fg: fg),
          ),
        );

      case EButtonVariant.tonal:
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: effectiveHeight),
          child: FilledButton.tonal(
            onPressed: effectiveOnPressed,
            style: FilledButton.styleFrom(
              padding: effectivePadding,
              elevation: 0,
              minimumSize: minSize,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
            ),
            child: labelRow(fg: scheme.primary),
          ),
        );

      case EButtonVariant.outlined:
        final fg = primaryFg;
        final side = BorderSide(color: fg);
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: effectiveHeight),
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              padding: effectivePadding,
              minimumSize: minSize,
              side: side,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
            ),
            child: labelRow(fg: fg),
          ),
        );

      case EButtonVariant.text:
        final fg = destructive ? scheme.error : scheme.primary;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: effectiveHeight),
          child: TextButton(
            onPressed: effectiveOnPressed,
            style: TextButton.styleFrom(
              foregroundColor: fg,
              padding: effectivePadding,
              minimumSize: minSize,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
            ),
            child: labelRow(fg: fg),
          ),
        );

      case EButtonVariant.danger:
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: effectiveHeight),
          child: FilledButton(
            onPressed: effectiveOnPressed,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              padding: effectivePadding,
              elevation: 0,
              minimumSize: minSize,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
            ),
            child: labelRow(fg: scheme.onError),
          ),
        );
    }
  }
}

/// 圆形主色图标按钮（如发送区「+」）。
class EIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// 与 [EButtonSize] 对齐：小 / 默认 / 大。
  final EButtonSize size;

  /// 覆盖 [size] 对应的边长（逻辑像素）。
  final double? dimension;

  const EIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = EButtonSize.md,
    this.dimension,
  });

  double get _side {
    if (dimension != null) return dimension!;
    return switch (size) {
      EButtonSize.sm => 34,
      EButtonSize.md => 40,
      EButtonSize.lg => 48,
    };
  }

  double get _iconSize {
    if (dimension != null) {
      return (dimension! * 0.45).clamp(18.0, 28.0);
    }
    return switch (size) {
      EButtonSize.sm => 20,
      EButtonSize.md => 24,
      EButtonSize.lg => 28,
    };
  }

  @override
  Widget build(BuildContext context) {
    final side = _side;
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: _iconSize),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        hoverColor: Colors.white.withValues(alpha: 0.12),
        minimumSize: Size(side, side),
        padding: EdgeInsets.zero,
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
