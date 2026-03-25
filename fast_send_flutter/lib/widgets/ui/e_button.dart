import 'package:flutter/material.dart';

import '../../core/config/styles.dart';

enum EButtonVariant { primary, secondary, danger }

class EButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final EButtonVariant variant;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;

  const EButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.variant = EButtonVariant.primary,
    this.height = 44,
    this.radius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (bg, fg, border) = switch (variant) {
      EButtonVariant.primary => (
        AppStyles.primary,
        Colors.white,
        Colors.transparent,
      ),
      EButtonVariant.secondary => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        scheme.outlineVariant,
      ),
      EButtonVariant.danger => (
        scheme.error,
        scheme.onError,
        Colors.transparent,
      ),
    };

    final effectiveOnPressed = (loading) ? null : onPressed;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: FilledButton(
        onPressed: effectiveOnPressed,
        style:
            FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              padding: padding,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
                side: BorderSide(color: border),
              ),
            ).copyWith(
              elevation: const WidgetStatePropertyAll(0),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return fg.withValues(alpha: 0.08);
                }
                if (states.contains(WidgetState.hovered)) {
                  return fg.withValues(alpha: 0.06);
                }
                return null;
              }),
            ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
