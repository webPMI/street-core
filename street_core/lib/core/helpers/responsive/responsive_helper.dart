import 'package:flutter/material.dart';

/// Responsive helper class for managing layout adaptations across different screen sizes
///
/// Breakpoints:
/// - Mobile: < 600px
/// - Tablet: 600px - 1024px
/// - Desktop: > 1024px
class ResponsiveHelper {

  ResponsiveHelper(this.context);
  final BuildContext context;

  /// Get screen width
  double get width => MediaQuery.of(context).size.width;

  /// Get screen height
  double get height => MediaQuery.of(context).size.height;

  /// Check if device is mobile (< 600px)
  bool get isMobile => width < 600;

  /// Check if device is tablet (600px - 1024px)
  bool get isTablet => width >= 600 && width < 1024;

  /// Check if device is desktop (> 1024px)
  bool get isDesktop => width >= 1024;

  /// Check if device is mobile or tablet
  bool get isMobileOrTablet => width < 1024;

  /// Get appropriate padding for the current screen size
  EdgeInsets get pagePadding {
    if (isMobile) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
  }

  /// Get appropriate content padding
  EdgeInsets get contentPadding {
    if (isMobile) {
      return const EdgeInsets.all(12);
    } else if (isTablet) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  /// Get appropriate spacing for the current screen size
  double get spacing {
    if (isMobile) {
      return 8;
    } else if (isTablet) {
      return 12;
    } else {
      return 16;
    }
  }

  /// Get number of columns for grid layouts
  int get gridColumns {
    if (isMobile) {
      return 1;
    } else if (isTablet) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get appropriate font size multiplier
  double get fontSizeMultiplier {
    if (isMobile) {
      return 1;
    } else if (isTablet) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Get appropriate icon size
  double get iconSize {
    if (isMobile) {
      return 24;
    } else if (isTablet) {
      return 28;
    } else {
      return 32;
    }
  }

  /// Get max width for centered content (useful for forms, text)
  double get maxContentWidth {
    if (isMobile) {
      return double.infinity;
    } else if (isTablet) {
      return 720;
    } else {
      return 1200;
    }
  }

  /// Get appropriate card elevation
  double get cardElevation {
    if (isMobile) {
      return 2;
    } else {
      return 4;
    }
  }

  /// Get appropriate border radius
  double get borderRadius {
    if (isMobile) {
      return 8;
    } else if (isTablet) {
      return 12;
    } else {
      return 16;
    }
  }
}
