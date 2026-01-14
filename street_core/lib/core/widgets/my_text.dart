import '../lang/context_tr.dart';
import 'package:flutter/material.dart';

/// Optimized text widget with automatic translation support.
///
/// Features:
/// - Auto-translates text keys using the current locale
/// - Supports parameterized translations via [args]
/// - Optional container styling (only renders Container when needed)
/// - Reactively updates when locale changes
///
/// Usage:
/// ```dart
/// // Simple translation
/// MyText('hello_world')
///
/// // With parameters
/// MyText('welcome_user', args: {'name': 'John'})
///
/// // Without translation (for dynamic content)
/// MyText(user.name, noTranslation: true)
///
/// // Selectable text (can copy)
/// MyText(user.email, noTranslation: true, selectable: true)
///
/// // With styling
/// MyText('title', style: TextStyle(fontSize: 24))
/// ```
class MyText extends StatelessWidget {
  const MyText(
    this.text, {
    super.key,
    this.args,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.noTranslation,
    this.selectable = false,
    // Container styling (only used when needed)
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.alignment,
    // Legacy parameters (kept for compatibility)
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.istitle,
  });

  /// The text key to translate, or literal text if [noTranslation] is true
  final String text;

  /// Parameters for translation substitution (e.g., {'name': 'John'})
  final Map<String, String>? args;

  /// Custom text style (overrides individual style parameters)
  final TextStyle? style;

  /// Text alignment (defaults to inherit from parent, not center)
  final TextAlign? textAlign;

  /// Maximum number of lines
  final int? maxLines;

  /// Text overflow behavior
  final TextOverflow? overflow;

  /// If true, skips translation and uses text as-is
  final bool? noTranslation;

  /// If true, text can be selected and copied
  final bool selectable;

  // Container styling parameters
  final double? padding;
  final double? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool? border;
  final bool? boxShadow;
  final Alignment? alignment;

  // Legacy style parameters (for backward compatibility)
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final bool? istitle;

  /// Returns true if container wrapper is needed
  bool get _needsContainer =>
      padding != null ||
      (margin != null && margin != 0) ||
      width != null ||
      height != null ||
      backgroundColor != null ||
      borderRadius != null ||
      (border ?? false) ||
      (boxShadow ?? false) ||
      alignment != null;

  /// Gets the translated text with parameter substitution
  String _getTranslatedText(BuildContext context) {
    if (noTranslation ?? false) return text;
    return context.tr(text, args: args);
  }

  /// Builds the effective TextStyle
  TextStyle? _buildTextStyle() {
    if (style != null) return style;

    // Only create TextStyle if legacy parameters are provided
    if (fontSize != null ||
        fontWeight != null ||
        fontStyle != null ||
        color != null ||
        (istitle ?? false) ||
        overflow != null) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight ?? (istitle ?? false ? FontWeight.bold : null),
        fontStyle: fontStyle,
        color: color,
        overflow: overflow,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Watch locale changes to trigger rebuilds
    // context.watch<LocaleCubit>();

    final translatedText = _getTranslatedText(context);
    final textStyle = _buildTextStyle();

    // Use SelectableText when selectable is true
    Widget textWidget;
    if (selectable) {
      textWidget = SelectableText(
        translatedText,
        style: textStyle,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    } else {
      textWidget = Text(
        translatedText,
        style: textStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Return plain Text if no container styling needed
    if (!_needsContainer) {
      return textWidget;
    }

    // Build container only when styling is needed
    final theme = Theme.of(context);
    final borderColor = border ?? false
        ? theme.dividerColor
        : Colors.transparent;

    return Container(
      width: width,
      height: height,
      margin: margin != null ? EdgeInsets.all(margin!) : null,
      padding: padding != null ? EdgeInsets.all(padding!) : null,
      alignment: alignment,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
        border: border ?? false ? Border.all(color: borderColor) : null,
        boxShadow: boxShadow ?? false
            ? [
                BoxShadow(
                  blurRadius: 4,
                  spreadRadius: 2,
                  blurStyle: BlurStyle.outer,
                  color: theme.cardColor,
                ),
              ]
            : null,
      ),
      child: textWidget,
    );
  }
}
