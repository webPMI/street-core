// Web-specific heading implementation using real HTML elements
// This file should only be imported when running on web platform

import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Counter for unique heading IDs
int _headingCounter = 0;

/// Generate unique ID for heading elements
String _generateHeadingId() => 'seo-heading-${_headingCounter++}';

/// Web implementation of SEO heading using real HTML element
class SeoHeadingWebImpl extends StatefulWidget {

  const SeoHeadingWebImpl({
    super.key,
    required this.tag,
    required this.text,
    required this.style,
    this.textAlign,
    this.height,
  });
  final String tag; // h1, h2, h3, h4, h5, h6, p, span
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final double? height;

  @override
  State<SeoHeadingWebImpl> createState() => _SeoHeadingWebImplState();
}

class _SeoHeadingWebImplState extends State<SeoHeadingWebImpl> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = _generateHeadingId();
    _registerViewFactory();
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final element = web.document.createElement(widget.tag) as web.HTMLElement;
        element.textContent = widget.text;
        _applyStyles(element);
        return element;
      },
    );
  }

  void _applyStyles(web.HTMLElement element) {
    final style = widget.style;
    final cssStyles = StringBuffer();

    // Font properties
    if (style.fontSize != null) {
      cssStyles.write('font-size: ${style.fontSize}px; ');
    }
    if (style.fontWeight != null) {
      cssStyles.write('font-weight: ${_fontWeightToCss(style.fontWeight!)}; ');
    }
    if (style.fontFamily != null) {
      cssStyles.write('font-family: ${style.fontFamily}; ');
    }
    if (style.color != null) {
      cssStyles.write('color: ${_colorToCss(style.color!)}; ');
    }
    if (style.letterSpacing != null) {
      cssStyles.write('letter-spacing: ${style.letterSpacing}px; ');
    }
    if (style.height != null && style.fontSize != null) {
      cssStyles.write('line-height: ${style.height! * style.fontSize!}px; ');
    }

    // Text alignment
    if (widget.textAlign != null) {
      cssStyles.write('text-align: ${_textAlignToCss(widget.textAlign!)}; ');
    }

    // Reset default margins and handle wrapping
    cssStyles.write('margin: 0; padding: 0; white-space: pre-wrap; word-wrap: break-word; ');

    element.style.cssText = cssStyles.toString();
  }

  String _fontWeightToCss(FontWeight weight) {
    return weight.value.toString();
  }

  String _colorToCss(Color color) {
    final r = (color.r * 255.0).round() & 0xff;
    final g = (color.g * 255.0).round() & 0xff;
    final b = (color.b * 255.0).round() & 0xff;
    final a = color.a;
    return 'rgba($r, $g, $b, $a)';
  }

  String _textAlignToCss(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return 'left';
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
        return 'center';
      case TextAlign.justify:
        return 'justify';
      case TextAlign.start:
        return 'start';
      case TextAlign.end:
        return 'end';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate approximate height based on text style
    final fontSize = widget.style.fontSize ?? 16;
    final lineHeight = widget.style.height ?? 1.2;
    final isParagraph = widget.tag == 'p';
    
    // Use provided height or calculate approximate height
    final double effectiveHeight = widget.height ?? 
        ((fontSize * lineHeight) * (isParagraph ? 3 : 1) + 4);

    // Use LayoutBuilder to get available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width or a reasonable default
        final width = constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : 800.0;
        
        return SizedBox(
          width: width,
          height: effectiveHeight,
          child: HtmlElementView(
            viewType: _viewId,
          ),
        );
      },
    );
  }
}
