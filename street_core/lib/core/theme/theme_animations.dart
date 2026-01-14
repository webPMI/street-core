import '/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Theme Animation System
///
/// Smooth, accessible animations for theme transitions and micro-interactions
class ThemeAnimations {
  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================

  /// Standard Material easing curve - use for most animations
  static const Curve standard = Curves.easeInOutCubic;

  /// Emphasized easing - use for important transitions
  static const Curve emphasized = Curves.fastOutSlowIn;

  /// Decelerated easing - use for entering animations
  static const Curve decelerate = Curves.easeOut;

  /// Accelerated easing - use for exiting animations
  static const Curve accelerate = Curves.easeIn;

  /// Bounce - use sparingly for playful interactions
  static const Curve bounce = Curves.elasticOut;

  // ============================================================================
  // THEME TRANSITION WIDGET
  // ============================================================================

  /// Animated theme transition that smoothly interpolates colors
  static Widget buildThemeTransition({
    required Widget child,
    Duration duration = AppDuration.normal,
    Curve curve = standard,
  }) {
    return AnimatedTheme(
      data: ThemeData.light(), // Will be replaced by context theme
      curve: curve,
      duration: duration,
      child: child,
    );
  }

  // ============================================================================
  // SHIMMER EFFECT (Loading states)
  // ============================================================================

  static Widget shimmer({
    required Widget child,
    required Color baseColor,
    required Color highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
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
        // Loop the animation
      },
    );
  }

  // ============================================================================
  // FADE TRANSITION
  // ============================================================================

  static Widget fadeIn({
    required Widget child,
    Duration duration = AppDuration.normal,
    Duration delay = Duration.zero,
    Curve curve = decelerate,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  static Widget fadeOut({
    required Widget child,
    Duration duration = AppDuration.normal,
    Curve curve = accelerate,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  // ============================================================================
  // SLIDE TRANSITION
  // ============================================================================

  static Widget slideIn({
    required Widget child,
    required Offset begin,
    Duration duration = AppDuration.normal,
    Duration delay = Duration.zero,
    Curve curve = emphasized,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: Offset.zero),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: child,
    );
  }

  // ============================================================================
  // SCALE TRANSITION
  // ============================================================================

  static Widget scaleIn({
    required Widget child,
    Duration duration = AppDuration.fast,
    Duration delay = Duration.zero,
    Curve curve = emphasized,
    Alignment alignment = Alignment.center,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: alignment,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
      onEnd: () {
        // Reverse animation (would need stateful implementation)
      },
    );
  }

  // ============================================================================
  // ROTATION TRANSITION
  // ============================================================================

  static Widget rotateIn({
    required Widget child,
    Duration duration = AppDuration.normal,
    Duration delay = Duration.zero,
    Curve curve = emphasized,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -0.1, end: 0),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        return Transform.rotate(angle: value, child: child);
      },
      child: child,
    );
  }

  // ============================================================================
  // PAGE TRANSITIONS
  // ============================================================================

  static Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    PageTransitionType type = PageTransitionType.fade,
  }) {
    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(opacity: animation, child: child);

      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: emphasized)),
          child: child,
        );

      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: emphasized)),
          child: child,
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: emphasized)),
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: emphasized)),
          child: FadeTransition(opacity: animation, child: child),
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: emphasized)),
          child: child,
        );
    }
  }

  // ============================================================================
  // MICRO-INTERACTIONS
  // ============================================================================

  /// Button press animation
  static Widget buttonPress({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0.95),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(onTap: onPressed, child: child),
        );
      },
      child: child,
    );
  }

  /// Card lift on hover
  static Widget cardLift({
    required Widget child,
    required bool isHovered,
    double normalElevation = 2.0,
    double hoveredElevation = 8.0,
  }) {
    return AnimatedContainer(
      duration: AppDuration.fast,
      curve: emphasized,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: isHovered ? hoveredElevation : normalElevation,
            offset: Offset(0, isHovered ? 4 : 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================================
  // LOADING ANIMATIONS
  // ============================================================================

  /// Spinning loader
  static Widget spinner({Color? color, double size = 40}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        // Loop animation (would need stateful implementation)
      },
    );
  }

  /// Pulsing loader
  static Widget pulsingDots({
    Color? color,
    int dotCount = 3,
    double dotSize = 10,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        dotCount,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: (color ?? Colors.blue).withValues(alpha: value),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
            onEnd: () {
              // Reverse animation (would need stateful implementation)
            },
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // STAGGER ANIMATIONS
  // ============================================================================

  /// Build staggered list items
  static Widget staggeredList({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 50),
    Duration itemDuration = AppDuration.normal,
    Axis scrollDirection = Axis.vertical,
  }) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return fadeIn(
          delay: staggerDelay * index,
          duration: itemDuration,
          child: slideIn(
            begin: scrollDirection == Axis.vertical
                ? const Offset(0, 20)
                : const Offset(20, 0),
            delay: staggerDelay * index,
            duration: itemDuration,
            child: children[index],
          ),
        );
      },
    );
  }

  // ============================================================================
  // HERO ANIMATIONS
  // ============================================================================

  /// Create hero transition for shared element
  static Widget hero({required String tag, required Widget child}) {
    return Hero(
      tag: tag,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }

  // ============================================================================
  // ACCESSIBILITY SUPPORT
  // ============================================================================

  /// Check if animations should be reduced (accessibility)
  static bool shouldReduceAnimations(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get duration respecting accessibility settings
  static Duration getDuration(BuildContext context, Duration defaultDuration) {
    return shouldReduceAnimations(context) ? Duration.zero : defaultDuration;
  }

  /// Get curve respecting accessibility settings
  static Curve getCurve(BuildContext context, Curve defaultCurve) {
    return shouldReduceAnimations(context) ? Curves.linear : defaultCurve;
  }
}

// ============================================================================
// PAGE TRANSITION TYPES
// ============================================================================

enum PageTransitionType {
  fade,
  slideRight,
  slideLeft,
  slideUp,
  scale,
  rotation,
}
