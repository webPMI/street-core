import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import './my_text.dart';

/// Simple button widget using Material 3 FilledButton.
class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.margin,
    this.width,
    this.maxWidth = 400,
    this.backgroundColor,
    this.textColor,
  });

  final String? text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? margin;
  final double? width;
  final double maxWidth;
  final Color? backgroundColor;
  final Color? textColor;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgColor = textColor ?? theme.colorScheme.onPrimary;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: fgColor),
        if ((isLoading || icon != null) && text != null)
          const SizedBox(width: AppSpacing.sm),
        if (text != null)
          Flexible(
            child: MyText(
              text!,
              selectable: false,
              color: _isDisabled
                  ? theme.colorScheme.onSurface.withOpacity(0.38)
                  : fgColor,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    Widget button = FilledButton(
      onPressed: _isDisabled ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md * 0.75,
        ),
      ),
      child: buttonChild,
    );

    if (width != null) {
      button = SizedBox(width: width, child: button);
    }

    if (margin != null && margin! > 0) {
      button = Padding(
        padding: EdgeInsets.all(margin!),
        child: button,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: button,
    );
  }
}
