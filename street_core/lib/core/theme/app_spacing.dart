import 'package:flutter/material.dart';

/// Application Spacing System
///
/// Centralized spacing values following an 8pt grid system for consistency.
/// Use these constants throughout the app instead of hardcoded values.
///
/// ## Usage
///
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.md),
///   child: MyWidget(),
/// )
/// ```
class AppSpacing {
  /// Extra extra small spacing: 2.0
  static const double xxs = 2;

  /// Extra small spacing: 4.0
  static const double xs = 4;

  /// Small spacing: 8.0
  static const double sm = 8;

  /// Medium spacing: 16.0 (base unit)
  static const double md = 16;

  /// Large spacing: 24.0
  static const double lg = 24;

  /// Extra large spacing: 32.0
  static const double xl = 32;

  /// Extra extra large spacing: 48.0
  static const double xxl = 48;

  /// Extra extra extra large spacing: 64.0
  static const double xxxl = 64;

  // Edge Insets shortcuts
  static const edgeInsetsXXS = EdgeInsets.all(xxs);
  static const edgeInsetsXS = EdgeInsets.all(xs);
  static const edgeInsetsSM = EdgeInsets.all(sm);
  static const edgeInsetsMD = EdgeInsets.all(md);
  static const edgeInsetsLG = EdgeInsets.all(lg);
  static const edgeInsetsXL = EdgeInsets.all(xl);
  static const edgeInsetsXXL = EdgeInsets.all(xxl);

  // Horizontal shortcuts
  static const horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const horizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical shortcuts
  static const verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const verticalMD = EdgeInsets.symmetric(vertical: md);
  static const verticalLG = EdgeInsets.symmetric(vertical: lg);
  static const verticalXL = EdgeInsets.symmetric(vertical: xl);

  // Common padding combinations
  static const cardPadding = EdgeInsets.all(md);
  static const listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const pagePadding = EdgeInsets.all(lg);
  static const sectionPadding = EdgeInsets.symmetric(vertical: lg);
}

/// Application Border Radius System
///
/// Consistent border radius values for UI elements.
class AppRadius {
  /// Extra small radius: 4.0
  static const double xs = 4;

  /// Small radius: 8.0
  static const double sm = 8;

  /// Medium radius: 12.0
  static const double md = 12;

  /// Large radius: 16.0
  static const double lg = 16;

  /// Extra large radius: 24.0
  static const double xl = 24;

  /// Full circle/pill shape
  static const double full = 9999;

  // BorderRadius shortcuts
  static const borderRadiusXS = BorderRadius.all(Radius.circular(xs));
  static const borderRadiusSM = BorderRadius.all(Radius.circular(sm));
  static const borderRadiusMD = BorderRadius.all(Radius.circular(md));
  static const borderRadiusLG = BorderRadius.all(Radius.circular(lg));
  static const borderRadiusXL = BorderRadius.all(Radius.circular(xl));
  static const borderRadiusFull = BorderRadius.all(Radius.circular(full));

  // Common shapes
  static const cardRadius = borderRadiusMD;
  static const buttonRadius = borderRadiusSM;
  static const inputRadius = borderRadiusSM;
  static const dialogRadius = borderRadiusLG;
  static const sheetRadius = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );
}

/// Application Elevation System
///
/// Material Design elevation levels for shadows and depth.
class AppElevation {
  /// No elevation
  static const double none = 0;

  /// Subtle elevation: 1.0
  static const double xs = 1;

  /// Small elevation: 2.0
  static const double sm = 2;

  /// Medium elevation: 4.0
  static const double md = 4;

  /// Large elevation: 8.0
  static const double lg = 8;

  /// Extra large elevation: 16.0
  static const double xl = 16;

  // Component-specific defaults
  static const double card = sm;
  static const double button = sm;
  static const double dialog = lg;
  static const double appBar = none;
  static const double bottomSheet = lg;
}

/// Application Icon Sizes
///
/// Consistent icon sizing across the app.
class AppIconSize {
  /// Extra small icon: 16.0
  static const double xs = 16;

  /// Small icon: 20.0
  static const double sm = 20;

  /// Medium icon: 24.0
  static const double md = 24;

  /// Large icon: 32.0
  static const double lg = 32;

  /// Extra large icon: 48.0
  static const double xl = 48;

  /// Extra extra large icon: 64.0
  static const double xxl = 64;
}

/// Application Animation Durations
///
/// Consistent animation timing across the app.
class AppDuration {
  /// Very fast: 100ms
  static const instant = Duration(milliseconds: 100);

  /// Fast: 200ms
  static const fast = Duration(milliseconds: 200);

  /// Normal: 300ms
  static const normal = Duration(milliseconds: 300);

  /// Slow: 500ms
  static const slow = Duration(milliseconds: 500);

  /// Very slow: 1000ms
  static const verySlow = Duration(milliseconds: 1000);
}
