import '../helpers/responsive/responsive_builder.dart';
import '../theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A standardized, responsive card widget with Material Design 3 compliance.
///
/// This widget provides a consistent card implementation following the FitRiders
/// design system with:
/// - Consistent spacing using [AppSpacing]
/// - Standard border radius using [AppRadius.cardRadius]
/// - Theme-aware colors from [ColorScheme]
/// - Optional hover effects with smooth animations
/// - Accessibility support with Semantics
///
/// ## Usage Examples
///
/// ### Basic Card
/// ```dart
/// MyResponsiveCard(
///   child: Text('Hello World'),
/// )
/// ```
///
/// ### Interactive Card with Hover
/// ```dart
/// MyResponsiveCard(
///   onTap: () => print('Tapped'),
///   hoverEffect: true,
///   child: Text('Click me'),
/// )
/// ```
///
/// ### Custom Styling
/// ```dart
/// MyResponsiveCard(
///   backgroundColor: Colors.blue,
///   borderColor: Colors.red,
///   elevation: AppElevation.md,
///   customPadding: AppSpacing.edgeInsetsLG,
///   child: Text('Custom card'),
/// )
/// ```
///
/// ## Accessibility
///
/// This widget includes semantic labels for screen readers. Use [semanticLabel]
/// to provide context about the card's purpose.
class MyResponsiveCard extends StatefulWidget {
  /// Creates a responsive card widget.
  ///
  /// The [child] parameter is required and represents the card's content.
  const MyResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.customPadding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.elevation,
    this.hoverEffect = false,
    this.customRadius,
    this.semanticLabel,
    this.surfaceTint = true,
  });

  /// The widget to display inside the card.
  final Widget child;

  /// Called when the card is tapped. Makes the card interactive.
  final VoidCallback? onTap;

  /// Custom padding for the card content.
  ///
  /// If null, defaults to responsive padding based on screen size:
  /// - Mobile: [AppSpacing.md] (16px)
  /// - Tablet: 20px
  /// - Desktop: [AppSpacing.lg] (24px)
  final EdgeInsetsGeometry? customPadding;

  /// Margin around the card. Defaults to [AppSpacing.edgeInsetsMD] if null.
  final EdgeInsetsGeometry? margin;

  /// Background color of the card.
  ///
  /// If null, uses [ColorScheme.surfaceContainerLowest] for proper Material 3
  /// surface hierarchy.
  final Color? backgroundColor;

  /// Border color for the card outline.
  ///
  /// If null, uses a subtle border with [ColorScheme.outlineVariant] at 10% opacity.
  final Color? borderColor;

  /// Elevation of the card shadow.
  ///
  /// If null, uses [AppElevation.card] (2.0) as default.
  /// When [hoverEffect] is true and hovering, elevation increases to [AppElevation.md] (4.0).
  final double? elevation;

  /// Enables hover effect with lift animation and increased shadow.
  ///
  /// When enabled:
  /// - Card lifts 4px upward on hover
  /// - Elevation increases from 2.0 to 4.0
  /// - Smooth animation over 200ms
  final bool hoverEffect;

  /// Custom border radius value in pixels.
  ///
  /// If null, uses [AppRadius.cardRadius] (12.0) for consistency.
  final double? customRadius;

  /// Semantic label for accessibility.
  ///
  /// Used by screen readers to describe the card's purpose.
  /// Example: "Product card", "User profile card", etc.
  final String? semanticLabel;

  /// Whether to apply surface tint color for Material 3 elevation.
  ///
  /// When true (default), uses [ColorScheme.surfaceTint] for elevated appearance.
  final bool surfaceTint;

  @override
  State<MyResponsiveCard> createState() => _MyResponsiveCardState();
}

class _MyResponsiveCardState extends State<MyResponsiveCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInteractive = widget.onTap != null;

    // =========================================================================
    // EFFECTIVE PROPERTIES
    // =========================================================================

    // Padding: Responsive defaults or custom
    final effectivePadding = widget.customPadding ??
        EdgeInsets.all(
          context.responsive(
            mobile: AppSpacing.md,
            tablet: 20,
            desktop: AppSpacing.lg,
          ),
        );

    // Margin: Default to AppSpacing.edgeInsetsMD
    final effectiveMargin = widget.margin ?? AppSpacing.edgeInsetsMD;

    // Elevation: Default to card elevation, increase on hover
    final baseElevation = widget.elevation ?? AppElevation.card;
    final effectiveElevation =
        (_isHovered && widget.hoverEffect) ? AppElevation.md : baseElevation;

    // Background: Use surfaceContainerLowest for proper Material 3 hierarchy
    final bgColor = widget.backgroundColor ?? colorScheme.surfaceContainerLowest;

    // Border radius: Use AppRadius.cardRadius for consistency
    final borderRadius = widget.customRadius ?? AppRadius.md;

    // Border: Subtle outline or custom color
    final borderSide = widget.borderColor != null
        ? BorderSide(color: widget.borderColor!)
        : BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.1),
          );

    // =========================================================================
    // CARD CONTENT
    // =========================================================================

    final Widget cardContent = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.fromBorderSide(borderSide),
        boxShadow: [
          if (effectiveElevation > 0)
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: effectiveElevation * 2,
              offset: Offset(0, effectiveElevation / 2),
              spreadRadius: 0,
            ),
        ],
      ),
      child: widget.child,
    );

    // =========================================================================
    // INTERACTION LAYER
    // =========================================================================

    Widget result = cardContent;

    // Add Material + InkWell for tap interactions
    if (isInteractive) {
      result = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: colorScheme.primary.withValues(alpha: 0.04),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: cardContent,
        ),
      );
    }

    // =========================================================================
    // HOVER EFFECT
    // =========================================================================

    if (widget.hoverEffect) {
      result = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: AppDuration.fast, // 200ms
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            0,
            _isHovered ? -4 : 0,
            0,
          ),
          child: result,
        ),
      );
    }

    // =========================================================================
    // MARGIN & SEMANTICS
    // =========================================================================

    // Apply margin
    result = Padding(
      padding: effectiveMargin,
      child: result,
    );

    // Add semantics for accessibility
    if (widget.semanticLabel != null) {
      result = Semantics(
        label: widget.semanticLabel,
        button: isInteractive,
        enabled: isInteractive,
        child: result,
      );
    }

    return result;
  }
}
