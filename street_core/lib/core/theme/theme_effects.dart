import 'dart:ui';

import '/core/theme/app_colors.dart';
import '/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Visual Effects System
///
/// Modern visual effects including:
/// - Glassmorphism
/// - Gradients
/// - Shadows
/// - Blur effects
/// - Neumorphism (optional)
class ThemeEffects {
  // ============================================================================
  // GLASSMORPHISM
  // ============================================================================

  /// Glassmorphism container with blur and transparency
  static Widget glass({
    required Widget child,
    double blur = 10.0,
    double opacity = 0.15,
    Color? tintColor,
    BorderRadius? borderRadius,
    Border? border,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? AppRadius.cardRadius,
        border:
            border ??
            Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? AppRadius.cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? AppSpacing.edgeInsetsMD,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (tintColor ?? Colors.white).withValues(alpha: opacity),
                  (tintColor ?? Colors.white).withValues(alpha: opacity * 0.5),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Frosted glass effect with stronger blur
  static Widget frostedGlass({
    required Widget child,
    double blur = 20.0,
    Color? tintColor,
    BorderRadius? borderRadius,
  }) {
    return glass(
      blur: blur,
      opacity: 0.25,
      tintColor: tintColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  // ============================================================================
  // GRADIENT CONTAINERS
  // ============================================================================

  /// Linear gradient container
  static Widget gradientContainer({
    required Widget child,
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxShadow? shadow,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? AppRadius.cardRadius,
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: stops,
        ),
        boxShadow: shadow != null ? [shadow] : null,
      ),
      child: Padding(padding: padding ?? AppSpacing.edgeInsetsMD, child: child),
    );
  }

  /// Animated gradient container
  static Widget animatedGradient({
    required Widget child,
    required List<Color> colors,
    Duration duration = const Duration(seconds: 3),
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (context, value, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? AppRadius.cardRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (value * 2), -1),
              end: Alignment(1.0 - (value * 2), 1),
              colors: colors,
            ),
          ),
          child: Padding(
            padding: padding ?? AppSpacing.edgeInsetsMD,
            child: child,
          ),
        );
      },
      child: child,
      onEnd: () {
        // Loop animation (would need StatefulWidget)
      },
    );
  }

  /// Radial gradient container
  static Widget radialGradient({
    required Widget child,
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double radius = 1.0,
    List<double>? stops,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? AppRadius.cardRadius,
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: colors,
          stops: stops,
        ),
      ),
      child: Padding(padding: padding ?? AppSpacing.edgeInsetsMD, child: child),
    );
  }

  // ============================================================================
  // SHADOW SYSTEM
  // ============================================================================

  /// Material Design elevation shadows
  static List<BoxShadow> elevation(
    double elevation, {
    Color? shadowColor,
    double opacity = 0.15,
  }) {
    if (elevation == 0) return [];

    final color = (shadowColor ?? Colors.black).withValues(alpha: opacity);

    return [
      BoxShadow(
        color: color,
        blurRadius: elevation * 1.5,
        offset: Offset(0, elevation * 0.5),
        spreadRadius: elevation * 0.1,
      ),
    ];
  }

  /// Soft shadow (more diffuse)
  static List<BoxShadow> softShadow({
    double blur = 20,
    Offset offset = const Offset(0, 4),
    Color? color,
    double opacity = 0.1,
  }) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  /// Hard shadow (more defined)
  static List<BoxShadow> hardShadow({
    double blur = 8,
    Offset offset = const Offset(0, 2),
    Color? color,
    double opacity = 0.25,
  }) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
        spreadRadius: 1,
      ),
    ];
  }

  /// Colored shadow (brand-specific)
  static List<BoxShadow> coloredShadow({
    required Color color,
    double blur = 15,
    Offset offset = const Offset(0, 4),
    double opacity = 0.3,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  /// Glow effect (multiple layered shadows)
  static List<BoxShadow> glow({required Color color, double intensity = 0.5}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: intensity * 0.5),
        blurRadius: 40,
        spreadRadius: 4,
      ),
    ];
  }

  // ============================================================================
  // NEUMORPHISM (Optional - use sparingly)
  // ============================================================================

  /// Neumorphic container
  static Widget neumorphic({
    required Widget child,
    required Color backgroundColor,
    bool isPressed = false,
    double blur = 15,
    double distance = 8,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    final isDark = backgroundColor.computeLuminance() < 0.5;

    return Container(
      padding: padding ?? AppSpacing.edgeInsetsMD,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? AppRadius.cardRadius,
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: blur * 0.5,
                  offset: Offset(distance * 0.3, distance * 0.3),
                ),
              ]
            : [
                // Light shadow (top-left)
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.8),
                  blurRadius: blur,
                  offset: Offset(-distance, -distance),
                ),
                // Dark shadow (bottom-right)
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.15),
                  blurRadius: blur,
                  offset: Offset(distance, distance),
                ),
              ],
      ),
      child: child,
    );
  }

  // ============================================================================
  // BLUR EFFECTS
  // ============================================================================

  /// Background blur filter
  static Widget blur({
    required Widget child,
    double sigmaX = 10.0,
    double sigmaY = 10.0,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: child,
      ),
    );
  }

  /// Blurred overlay
  static Widget blurredOverlay({
    required Widget child,
    double blur = 10.0,
    Color? overlayColor,
    double opacity = 0.3,
  }) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                color: (overlayColor ?? Colors.black).withValues(
                  alpha: opacity,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // GRADIENT OVERLAYS
  // ============================================================================

  /// Fade gradient overlay (useful for images)
  static Widget gradientOverlay({
    required Widget child,
    List<Color>? colors,
    AlignmentGeometry begin = Alignment.topCenter,
    AlignmentGeometry end = Alignment.bottomCenter,
  }) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors:
                    colors ??
                    [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Scrim overlay (darkens content)
  static Widget scrim({
    required Widget child,
    double opacity = 0.5,
    Color color = Colors.black,
  }) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(color: color.withValues(alpha: opacity)),
        ),
      ],
    );
  }

  // ============================================================================
  // SHIMMER EFFECT
  // ============================================================================

  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -2, end: 2),
      duration: duration,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (value - 1).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Would loop in StatefulWidget
      },
    );
  }

  // ============================================================================
  // BORDER EFFECTS
  // ============================================================================

  /// Gradient border
  static Widget gradientBorder({
    required Widget child,
    required Gradient gradient,
    double width = 2.0,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? AppRadius.cardRadius,
      ),
      child: Container(
        margin: EdgeInsets.all(width),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppRadius.cardRadius,
        ),
        child: Padding(
          padding: padding ?? AppSpacing.edgeInsetsMD,
          child: child,
        ),
      ),
    );
  }

  /// Animated border
  static Widget animatedBorder({
    required Widget child,
    required Color color,
    double width = 2.0,
    Duration duration = const Duration(seconds: 2),
    BorderRadius? borderRadius,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (context, value, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: 0.5 + (value * 0.5)),
              width: width,
            ),
            borderRadius: borderRadius ?? AppRadius.cardRadius,
          ),
          child: child,
        );
      },
      child: child,
      onEnd: () {
        // Would loop in StatefulWidget
      },
    );
  }

  // ============================================================================
  // COMBINED EFFECTS
  // ============================================================================

  /// Premium card with gradient, shadow, and border
  static Widget premiumCard({
    required Widget child,
    Gradient? gradient,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? AppSpacing.edgeInsetsMD,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? AppRadius.cardRadius,
        gradient: gradient ?? AppColors.sportyGradient,
        boxShadow: coloredShadow(color: gradient?.colors.first ?? Colors.blue),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? AppRadius.cardRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: padding ?? AppSpacing.edgeInsetsMD,
          child: child,
        ),
      ),
    );
  }

  /// Glass card with blur and gradient
  static Widget glassCard({
    required Widget child,
    required BuildContext context,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return glass(
      margin: margin,
      borderRadius: borderRadius,
      padding: padding,
      tintColor: isDark ? Colors.white : Colors.black,
      opacity: isDark ? 0.1 : 0.05,
      child: child,
    );
  }

  // ============================================================================
  // IMAGE EFFECTS
  // ============================================================================

  /// Image with gradient overlay
  static Widget imageWithGradient({
    required ImageProvider image,
    required Widget overlay,
    BoxFit fit = BoxFit.cover,
    AlignmentGeometry gradientBegin = Alignment.topCenter,
    AlignmentGeometry gradientEnd = Alignment.bottomCenter,
    List<Color>? gradientColors,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: image, fit: fit),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientBegin,
              end: gradientEnd,
              colors:
                  gradientColors ??
                  [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ),
          ),
        ),
        overlay,
      ],
    );
  }

  /// Parallax scrolling effect helper
  static Widget parallax({
    required Widget background,
    required Widget foreground,
    double backgroundSpeed = 0.5,
    double foregroundSpeed = 1.0,
  }) {
    // This is a simplified version
    // Real implementation would use ScrollController
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(0, 0), // Would calculate based on scroll
          child: background,
        ),
        Transform.translate(
          offset: const Offset(0, 0), // Would calculate based on scroll
          child: foreground,
        ),
      ],
    );
  }
}
