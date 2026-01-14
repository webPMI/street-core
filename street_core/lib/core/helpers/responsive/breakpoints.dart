/// Centralized breakpoint constants for responsive design.
///
/// Device Categories:
/// - Mobile: 320px - 480px (compact phones to standard phones)
/// - Tablet: 481px - 1024px (large phones, tablets portrait/landscape)
/// - Desktop: 1025px+ (laptops, desktops, large tablets landscape)
abstract class Breakpoints {
  // ============================================================================
  // PRIMARY BREAKPOINTS
  // ============================================================================

  /// Maximum width for mobile devices (phones)
  static const double mobile = 480;

  /// Maximum width for tablet devices
  static const double tablet = 1024;

  /// Minimum width for desktop/web (above this is desktop)
  static const double desktop = 1025;

  // ============================================================================
  // SECONDARY BREAKPOINTS (for fine-tuning)
  // ============================================================================

  /// Very small mobile devices (compact phones)
  static const double mobileSmall = 320;

  /// Standard mobile phones
  static const double mobileMedium = 375;

  /// Large mobile phones / phablets
  static const double mobileLarge = 480;

  /// Small tablets (portrait)
  static const double tabletSmall = 600;

  /// Standard tablets
  static const double tabletMedium = 768;

  /// Large tablets (landscape)
  static const double tabletLarge = 1024;

  /// Small desktop / laptop
  static const double desktopSmall = 1280;

  /// Standard desktop
  static const double desktopMedium = 1440;

  /// Large desktop / wide screens
  static const double desktopLarge = 1920;

  // ============================================================================
  // NAVIGATION BREAKPOINTS
  // ============================================================================

  /// Below this: use drawer navigation
  static const double navigationDrawer = 1200;

  /// Between navigationDrawer and this: use compact nav (icons only)
  static const double navigationCompact = 1400;

  // ============================================================================
  // CONTENT WIDTH CONSTRAINTS
  // ============================================================================

  /// Maximum content width for readability
  static const double maxContentWidth = 1200;

  /// Maximum form width
  static const double maxFormWidth = 600;

  /// Maximum card width
  static const double maxCardWidth = 400;
}

/// Represents the current device type based on screen width
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Extended device size for more granular control
enum DeviceSize {
  mobileSmall, // 320px - 374px
  mobileMedium, // 375px - 479px
  mobileLarge, // 480px (edge case)
  tabletSmall, // 481px - 599px
  tabletMedium, // 600px - 767px
  tabletLarge, // 768px - 1024px
  desktopSmall, // 1025px - 1279px
  desktopMedium, // 1280px - 1439px
  desktopLarge, // 1440px+
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Get device type from width
DeviceType getDeviceType(double width) {
  if (width <= Breakpoints.mobile) return DeviceType.mobile;
  if (width <= Breakpoints.tablet) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// Get number of grid columns based on width
int getGridColumns(double width) {
  if (width <= Breakpoints.mobile) return 1;
  if (width <= Breakpoints.tabletSmall) return 2;
  if (width <= Breakpoints.tablet) return 3;
  if (width <= Breakpoints.desktopMedium) return 4;
  return 5;
}

/// Get appropriate horizontal padding
double getHorizontalPadding(double width) {
  if (width <= Breakpoints.mobile) return 12;
  if (width <= Breakpoints.tablet) return 16;
  if (width <= Breakpoints.desktopMedium) return 24;
  return 32;
}
