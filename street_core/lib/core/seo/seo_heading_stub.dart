// Stub implementation for non-web platforms
// This file is used when dart.library.js_interop is not available

import 'package:flutter/widgets.dart';

/// Stub implementation of SEO heading for non-web platforms
/// Simply renders a Text widget since HTML elements don't apply
class SeoHeadingWebImpl extends StatelessWidget {

  const SeoHeadingWebImpl({
    super.key,
    required this.tag,
    required this.text,
    required this.style,
    this.textAlign,
    this.height,
  });
  final String tag; // Unused on non-web
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
    );
  }
}
