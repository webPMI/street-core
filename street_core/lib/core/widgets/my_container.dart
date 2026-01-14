import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// A customizable container widget following the FitRiders design system.
///
/// [MyContainer] provides a standardized way to create containers with consistent
/// spacing, radius, elevation, and styling across the app. It integrates with
/// the app's theme system and design tokens.
///
/// ## Features
///
/// - Design system integration (AppSpacing, AppRadius, AppElevation)
/// - Theme-aware colors (uses colorScheme)
/// - Accessibility support (Semantics)
/// - Background image support
/// - Flexible sizing constraints
/// - Customizable borders and shadows
///
/// ## Basic Usage
///
/// ```dart
/// MyContainer(
///   padding: AppSpacing.md,
///   child: Text('Hello World'),
/// )
/// ```
///
/// ## With Border and Shadow
///
/// ```dart
/// MyContainer(
///   padding: AppSpacing.lg,
///   borderRadius: AppRadius.md,
///   borderColor: theme.colorScheme.primary,
///   borderWidth: 2,
///   elevation: AppElevation.sm,
///   child: MyContent(),
/// )
/// ```
///
/// ## Card Style
///
/// ```dart
/// MyContainer.card(
///   child: MyCardContent(),
/// )
/// ```
///
/// ## With Background Image
///
/// ```dart
/// MyContainer(
///   imageUrl: 'https://example.com/bg.jpg',
///   height: 200,
///   child: Overlay(),
/// )
/// ```
///
/// See also:
/// - [AppSpacing] for standard spacing values
/// - [AppRadius] for border radius constants
/// - [AppElevation] for elevation levels
class MyContainer extends StatelessWidget {
  /// Creates a customizable container widget.
  const MyContainer({
    super.key,
    this.child,
    this.color,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.elevation,
    this.maxWidth,
    this.maxHeight,
    this.minHeight,
    this.minWidth,
    this.imageUrl,
    this.imageFit = BoxFit.cover,
    this.semanticLabel,
    this.clipBehavior = Clip.hardEdge,
  });

  /// Creates a card-styled container with default card styling.
  ///
  /// Uses [AppSpacing.cardPadding], [AppRadius.cardRadius], and
  /// [AppElevation.card] for consistent card appearance.
  ///
  /// Example:
  /// ```dart
  /// MyContainer.card(
  ///   child: Column(
  ///     children: [
  ///       Text('Card Title'),
  ///       Text('Card Content'),
  ///     ],
  ///   ),
  /// )
  /// ```
  const MyContainer.card({
    super.key,
    this.child,
    this.color,
    this.height,
    this.width,
    this.maxWidth,
    this.maxHeight,
    this.minHeight,
    this.minWidth,
    this.semanticLabel,
  }) : padding = AppSpacing.md,
       margin = null,
       borderRadius = AppRadius.md,
       borderColor = null,
       borderWidth = null,
       elevation = AppElevation.card,
       imageUrl = null,
       imageFit = BoxFit.cover,
       clipBehavior = Clip.hardEdge;

  /// Creates a container with list item styling.
  ///
  /// Uses [AppSpacing.listItemPadding] for consistent list item appearance.
  ///
  /// Example:
  /// ```dart
  /// MyContainer.listItem(
  ///   child: Row(
  ///     children: [Icon(Icons.star), Text('Item')],
  ///   ),
  /// )
  /// ```
  factory MyContainer.listItem({
    Key? key,
    Widget? child,
    Color? color,
    double? height,
    String? semanticLabel,
  }) {
    return MyContainer(
      key: key,
      padding: AppSpacing.sm,
      margin: AppSpacing.xxs,
      borderRadius: AppRadius.sm,
      height: height,
      color: color,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  /// The widget below this container in the tree.
  final Widget? child;

  /// Background color. If null, uses theme's surface color.
  final Color? color;

  /// Fixed height constraint.
  final double? height;

  /// Fixed width constraint.
  final double? width;

  /// Internal padding using [AppSpacing] values.
  ///
  /// Example: `padding: AppSpacing.md`
  final double? padding;

  /// External margin using [AppSpacing] values.
  ///
  /// Example: `margin: AppSpacing.sm`
  final double? margin;

  /// Border radius using [AppRadius] values.
  ///
  /// Example: `borderRadius: AppRadius.lg`
  final double? borderRadius;

  /// Border color. If null, no border is drawn.
  final Color? borderColor;

  /// Border width in logical pixels. Defaults to 1.0 if [borderColor] is set.
  final double? borderWidth;

  /// Material elevation for shadow. Uses [AppElevation] values.
  ///
  /// Example: `elevation: AppElevation.sm`
  final double? elevation;

  /// Maximum width constraint.
  final double? maxWidth;

  /// Maximum height constraint.
  final double? maxHeight;

  /// Minimum height constraint.
  final double? minHeight;

  /// Minimum width constraint.
  final double? minWidth;

  /// Background image URL (network image).
  final String? imageUrl;

  /// How the background image should be inscribed into the container.
  final BoxFit imageFit;

  /// Semantic label for accessibility (screen readers).
  final String? semanticLabel;

  /// Clip behavior for the container. Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine background color
    final backgroundColor =
        color ??
        (elevation != null && elevation! > 0 ? colorScheme.surface : null);

    // Build box shadow based on elevation
    final boxShadow = elevation != null && elevation! > 0
        ? [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: elevation! * 2,
              offset: Offset(0, elevation! / 2),
              spreadRadius: 0,
            ),
          ]
        : null;

    // Build border
    final border = borderColor != null
        ? Border.all(color: borderColor!, width: borderWidth ?? 1.0)
        : null;

    // Build constraints
    final constraints =
        (maxWidth != null ||
            maxHeight != null ||
            minWidth != null ||
            minHeight != null)
        ? BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
            maxHeight: maxHeight ?? double.infinity,
            minWidth: minWidth ?? 0,
            minHeight: minHeight ?? 0,
          )
        : null;

    Widget container = Container(
      clipBehavior: clipBehavior,
      padding: padding != null ? EdgeInsets.all(padding!) : null,
      margin: margin != null ? EdgeInsets.all(margin!) : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : null,
        boxShadow: boxShadow,
        border: border,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: imageFit)
            : null,
      ),
      width: width,
      height: height,
      constraints: constraints,
      child: child,
    );

    // Wrap with Semantics for accessibility
    if (semanticLabel != null) {
      container = Semantics(
        label: semanticLabel,
        container: true,
        child: container,
      );
    }

    return container;
  }
}
