import '../platform/platform_detector.dart';
import './seo_heading_stub.dart'
    if (dart.library.js_interop) 'seo_heading_web.dart';
import 'package:flutter/material.dart';

/// SEO-optimized Heading widgets (H1, H2, H3, H4, H5, H6)
///
/// These widgets render semantic HTML headings for better SEO on web.
/// On web: Renders actual HTML heading elements (h1, h2, etc.)
/// On mobile/desktop: Renders styled Text widgets
///
/// Use these instead of regular Text widgets for titles and headings on public pages.

class SeoH1 extends StatelessWidget {

  const SeoH1(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.color,
    this.fontSize,
    this.fontWeight,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.displayLarge?.copyWith(
          color: color,
          fontSize: fontSize ?? 32,
          fontWeight: fontWeight ?? FontWeight.bold,
        ) ??
        TextStyle(
          color: color,
          fontSize: fontSize ?? 32,
          fontWeight: fontWeight ?? FontWeight.bold,
        );

    return Semantics(
      header: true,
      child: _buildHeading('h1', text, style ?? defaultStyle, textAlign),
    );
  }
}

class SeoH2 extends StatelessWidget {

  const SeoH2(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.color,
    this.fontSize,
    this.fontWeight,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.headlineLarge?.copyWith(
          color: color,
          fontSize: fontSize ?? 24,
          fontWeight: fontWeight ?? FontWeight.bold,
        ) ??
        TextStyle(
          color: color,
          fontSize: fontSize ?? 24,
          fontWeight: fontWeight ?? FontWeight.bold,
        );

    return Semantics(
      header: true,
      child: _buildHeading('h2', text, style ?? defaultStyle, textAlign),
    );
  }
}

class SeoH3 extends StatelessWidget {

  const SeoH3(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.color,
    this.fontSize,
    this.fontWeight,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.headlineMedium?.copyWith(
          color: color,
          fontSize: fontSize ?? 20,
          fontWeight: fontWeight ?? FontWeight.w600,
        ) ??
        TextStyle(
          color: color,
          fontSize: fontSize ?? 20,
          fontWeight: fontWeight ?? FontWeight.w600,
        );

    return Semantics(
      header: true,
      child: _buildHeading('h3', text, style ?? defaultStyle, textAlign),
    );
  }
}

class SeoH4 extends StatelessWidget {

  const SeoH4(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.color,
    this.fontSize,
    this.fontWeight,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.headlineSmall?.copyWith(
          color: color,
          fontSize: fontSize ?? 18,
          fontWeight: fontWeight ?? FontWeight.w600,
        ) ??
        TextStyle(
          color: color,
          fontSize: fontSize ?? 18,
          fontWeight: fontWeight ?? FontWeight.w600,
        );

    return Semantics(
      header: true,
      child: _buildHeading('h4', text, style ?? defaultStyle, textAlign),
    );
  }
}

/// H5 heading widget
class SeoH5 extends StatelessWidget {

  const SeoH5(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.color,
    this.fontSize,
    this.fontWeight,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.titleLarge?.copyWith(
          color: color,
          fontSize: fontSize ?? 16,
          fontWeight: fontWeight ?? FontWeight.w600,
        ) ??
        TextStyle(
          color: color,
          fontSize: fontSize ?? 16,
          fontWeight: fontWeight ?? FontWeight.w600,
        );

    return Semantics(
      header: true,
      child: _buildHeading('h5', text, style ?? defaultStyle, textAlign),
    );
  }
}

/// H6 heading widget
class SeoH6 extends StatelessWidget {

  const SeoH6(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.color,
    this.fontSize,
    this.fontWeight,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w600,
        ) ??
        TextStyle(
          color: color,
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w600,
        );

    return Semantics(
      header: true,
      child: _buildHeading('h6', text, style ?? defaultStyle, textAlign),
    );
  }
}

/// Helper to build heading
/// On web: Uses real HTML heading element
/// On other platforms: Uses Text widget
Widget _buildHeading(
  String tag,
  String text,
  TextStyle style,
  TextAlign? textAlign,
) {
  // Use HTML element on web for proper SEO
  if (PlatformDetector.isWeb) {
    return SeoHeadingWebImpl(
      tag: tag,
      text: text,
      style: style,
      textAlign: textAlign,
    );
  }

  // Use Text widget on non-web platforms
  return Text(text, style: style, textAlign: textAlign);
}
