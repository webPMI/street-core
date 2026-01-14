import '/core/helpers/responsive/breakpoints.dart';
import 'package:flutter/material.dart';

/// Centralized spacing constants with responsive scaling
abstract class AppSpacing {
  // ============================================================================
  // BASE SPACING VALUES (for desktop - baseline)
  // ============================================================================

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // ============================================================================
  // SCALE FACTORS BY DEVICE TYPE
  // ============================================================================

  static const double mobileScale = 0.75;
  static const double tabletScale = 0.875;
  static const double desktopScale = 1;

  // ============================================================================
  // SEMANTIC SPACING
  // ============================================================================

  /// Page horizontal padding
  static const double pageHorizontal = md;

  /// Page vertical padding
  static const double pageVertical = lg;

  /// Card internal padding
  static const double cardPadding = md;

  /// List item spacing
  static const double listItemSpacing = sm;

  /// Section spacing
  static const double sectionSpacing = xl;

  /// Form field spacing
  static const double formFieldSpacing = md;
}

/// Extension to get responsive spacing values
extension ResponsiveSpacing on BuildContext {
  /// Get the current spacing scale factor based on screen width
  double get _spacingScale {
    final width = MediaQuery.of(this).size.width;

    if (width >= Breakpoints.desktop) {
      return AppSpacing.desktopScale;
    } else if (width > Breakpoints.mobile) {
      return AppSpacing.tabletScale;
    } else {
      return AppSpacing.mobileScale;
    }
  }

  // ============================================================================
  // RESPONSIVE SPACING GETTERS
  // ============================================================================

  double get spacingXxs => AppSpacing.xxs * _spacingScale;
  double get spacingXs => AppSpacing.xs * _spacingScale;
  double get spacingSm => AppSpacing.sm * _spacingScale;
  double get spacingMd => AppSpacing.md * _spacingScale;
  double get spacingLg => AppSpacing.lg * _spacingScale;
  double get spacingXl => AppSpacing.xl * _spacingScale;
  double get spacingXxl => AppSpacing.xxl * _spacingScale;
  double get spacingXxxl => AppSpacing.xxxl * _spacingScale;

  // ============================================================================
  // RESPONSIVE PADDING GETTERS
  // ============================================================================

  /// Standard page padding (horizontal and vertical)
  EdgeInsets get pagePadding => EdgeInsets.symmetric(
    horizontal: AppSpacing.pageHorizontal * _spacingScale,
    vertical: AppSpacing.pageVertical * _spacingScale,
  );

  /// Horizontal page padding only
  EdgeInsets get pageHorizontalPadding => EdgeInsets.symmetric(
    horizontal: AppSpacing.pageHorizontal * _spacingScale,
  );

  /// Vertical page padding only
  EdgeInsets get pageVerticalPadding =>
      EdgeInsets.symmetric(vertical: AppSpacing.pageVertical * _spacingScale);

  /// Card padding
  EdgeInsets get cardPadding =>
      EdgeInsets.all(AppSpacing.cardPadding * _spacingScale);

  /// Section padding (typically used between major sections)
  EdgeInsets get sectionPadding =>
      EdgeInsets.symmetric(vertical: AppSpacing.sectionSpacing * _spacingScale);

  /// Form padding
  EdgeInsets get formPadding => EdgeInsets.all(AppSpacing.md * _spacingScale);
}

/// Convenience widget for responsive vertical spacing
class ResponsiveGap extends StatelessWidget {
  const ResponsiveGap(this.size, {super.key});

  /// Extra extra small gap (4px base)
  const ResponsiveGap.xxs({super.key}) : size = AppSpacing.xxs;

  /// Extra small gap (8px base)
  const ResponsiveGap.xs({super.key}) : size = AppSpacing.xs;

  /// Small gap (12px base)
  const ResponsiveGap.sm({super.key}) : size = AppSpacing.sm;

  /// Medium gap (16px base)
  const ResponsiveGap.md({super.key}) : size = AppSpacing.md;

  /// Large gap (24px base)
  const ResponsiveGap.lg({super.key}) : size = AppSpacing.lg;

  /// Extra large gap (32px base)
  const ResponsiveGap.xl({super.key}) : size = AppSpacing.xl;

  /// Extra extra large gap (48px base)
  const ResponsiveGap.xxl({super.key}) : size = AppSpacing.xxl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = context._spacingScale;
    return SizedBox(height: size * scale);
  }
}

/// Convenience widget for responsive horizontal spacing
class ResponsiveHGap extends StatelessWidget {
  const ResponsiveHGap(this.size, {super.key});

  /// Extra extra small gap (4px base)
  const ResponsiveHGap.xxs({super.key}) : size = AppSpacing.xxs;

  /// Extra small gap (8px base)
  const ResponsiveHGap.xs({super.key}) : size = AppSpacing.xs;

  /// Small gap (12px base)
  const ResponsiveHGap.sm({super.key}) : size = AppSpacing.sm;

  /// Medium gap (16px base)
  const ResponsiveHGap.md({super.key}) : size = AppSpacing.md;

  /// Large gap (24px base)
  const ResponsiveHGap.lg({super.key}) : size = AppSpacing.lg;

  /// Extra large gap (32px base)
  const ResponsiveHGap.xl({super.key}) : size = AppSpacing.xl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = context._spacingScale;
    return SizedBox(width: size * scale);
  }
}
