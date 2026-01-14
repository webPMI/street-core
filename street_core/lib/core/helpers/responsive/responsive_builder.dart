import '/core/helpers/responsive/responsive_breakpoints.dart';
import 'package:flutter/material.dart';

/// A responsive wrapper widget that builds different layouts based on screen size.
///
/// This is the enhanced version that uses ResponsiveBreakpoints for more granular control.
///
/// Usage:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, device) {
///     if (device.isMobile) {
///       return MobileLayout();
///     } else if (device.isTablet) {
///       return TabletLayout();
///     } else {
///       return DesktopLayout();
///     }
///   },
/// )
/// ```
///
/// Or use the simplified version:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context, device) => MobileLayout(),
///   tablet: (context, device) => TabletLayout(),
///   desktop: (context, device) => DesktopLayout(),
/// )
/// ```
///
double getWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double getHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

///
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : assert(
         builder != null || mobile != null,
         'Either builder or mobile must be provided',
       );

  /// Main builder function that receives device information
  final Widget Function(BuildContext context, ResponsiveDevice device)? builder;

  /// Builder for mobile layout (< 600px)
  /// Falls back to builder if not provided
  final Widget Function(BuildContext context, ResponsiveDevice device)? mobile;

  /// Builder for tablet layout (600px - 1200px)
  /// Falls back to mobile or builder if not provided
  final Widget Function(BuildContext context, ResponsiveDevice device)? tablet;

  /// Builder for desktop layout (>= 1200px)
  /// Falls back to tablet, mobile, or builder if not provided
  final Widget Function(BuildContext context, ResponsiveDevice device)? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final device = ResponsiveDevice.fromConstraints(constraints);

        // If builder is provided, use it
        if (builder != null) {
          return builder!(context, device);
        }

        // Otherwise use device-specific builders with fallbacks
        if (device.isDesktop && desktop != null) {
          return desktop!(context, device);
        } else if (device.isTablet && tablet != null) {
          return tablet!(context, device);
        } else if (mobile != null) {
          return mobile!(context, device);
        }

        // Final fallback (shouldn't reach here due to assertion)
        return mobile!(context, device);
      },
    );
  }
}

/// Device information class with responsive utilities
///
/// This class provides comprehensive information about the current device
/// and convenient methods for responsive design decisions.
class ResponsiveDevice {
  const ResponsiveDevice({required this.width, required this.height});

  /// Create from BoxConstraints
  factory ResponsiveDevice.fromConstraints(BoxConstraints constraints) {
    return ResponsiveDevice(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
    );
  }

  /// Create from MediaQuery
  factory ResponsiveDevice.fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ResponsiveDevice(width: size.width, height: size.height);
  }
  final double width;
  final double height;

  // Device type detection
  DeviceType get deviceType => ResponsiveBreakpoints.getDeviceType(width);
  LayoutType get layoutType => ResponsiveBreakpoints.getLayoutType(width);

  bool get isMobileSmall => ResponsiveBreakpoints.isMobileSmall(width);
  bool get isMobile => ResponsiveBreakpoints.isMobile(width);
  bool get isTablet => ResponsiveBreakpoints.isTablet(width);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(width);
  bool get isDesktopLarge => ResponsiveBreakpoints.isDesktopLarge(width);

  // Layout helpers
  int get gridColumns => ResponsiveBreakpoints.getGridColumns(width);
  double get spacing => ResponsiveBreakpoints.getSpacing(width);
  double get horizontalPadding =>
      ResponsiveBreakpoints.getHorizontalPadding(width);
  double get verticalPadding => ResponsiveBreakpoints.getVerticalPadding(width);
  double get maxContentWidth => ResponsiveBreakpoints.getMaxContentWidth(width);
  double get borderRadius => ResponsiveBreakpoints.getBorderRadius(width);

  // Font sizes
  double get titleFontSize => ResponsiveBreakpoints.getTitleFontSize(width);
  double get bodyFontSize => ResponsiveBreakpoints.getBodyFontSize(width);

  // UI sizes
  double get appBarHeight => ResponsiveBreakpoints.getAppBarHeight(width);

  /// Get responsive value based on device type
  T value<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  @override
  String toString() =>
      'ResponsiveDevice(width: $width, type: ${deviceType.name})';
}

/// A stateless widget base class with built-in responsive utilities.
///
/// This abstract class provides a convenient way to create responsive widgets
/// by implementing different build methods for each device type.
///
/// Usage:
/// ```dart
/// class MyPage extends ResponsiveWidget {
///   const MyPage({super.key});
///
///   @override
///   Widget buildMobile(BuildContext context, ResponsiveDevice device) {
///     return MobileView(padding: device.horizontalPadding);
///   }
///
///   @override
///   Widget buildTablet(BuildContext context, ResponsiveDevice device) {
///     return TabletView(columns: device.gridColumns);
///   }
///
///   @override
///   Widget buildDesktop(BuildContext context, ResponsiveDevice device) {
///     return DesktopView(maxWidth: device.maxContentWidth);
///   }
/// }
/// ```
abstract class ResponsiveWidget extends StatelessWidget {
  const ResponsiveWidget({super.key});

  /// Build mobile layout (required)
  Widget buildMobile(BuildContext context, ResponsiveDevice device);

  /// Build tablet layout (optional, defaults to mobile)
  Widget buildTablet(BuildContext context, ResponsiveDevice device) =>
      buildMobile(context, device);

  /// Build desktop layout (optional, defaults to tablet)
  Widget buildDesktop(BuildContext context, ResponsiveDevice device) =>
      buildTablet(context, device);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: buildMobile,
      tablet: buildTablet,
      desktop: buildDesktop,
    );
  }
}

/// Extension methods for responsive design on BuildContext
///
/// Provides convenient access to responsive information and utilities
/// directly from the BuildContext.
///
/// Usage:
/// ```dart
/// Widget build(BuildContext context) {
///   final device = context.responsiveDevice;
///   final padding = context.responsive(mobile: 16.0, tablet: 24.0, desktop: 32.0);
///
///   if (context.isMobile) {
///     return MobileLayout();
///   }
///
///   return Container(
///     padding: EdgeInsets.all(device.horizontalPadding),
///     child: Text('Hello', style: TextStyle(fontSize: device.bodyFontSize)),
///   );
/// }
/// ```
extension ResponsiveContext on BuildContext {
  /// Get responsive device information
  ResponsiveDevice get responsiveDevice => ResponsiveDevice.fromContext(this);

  /// Get current device type
  DeviceType get deviceType => responsiveDevice.deviceType;

  /// Get current layout type
  LayoutType get layoutType => responsiveDevice.layoutType;

  /// Check if current device is mobile small
  bool get isMobileSmall => responsiveDevice.isMobileSmall;

  /// Check if current device is mobile
  bool get isMobile => responsiveDevice.isMobile;

  /// Check if current device is tablet
  bool get isTablet => responsiveDevice.isTablet;

  /// Check if current device is desktop
  bool get isDesktop => responsiveDevice.isDesktop;

  /// Check if current device is desktop large
  bool get isDesktopLarge => responsiveDevice.isDesktopLarge;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get number of grid columns for current screen
  int get gridColumns => responsiveDevice.gridColumns;

  /// Get recommended spacing for current screen
  double get spacing => responsiveDevice.spacing;

  /// Get recommended horizontal padding
  double get horizontalPadding => responsiveDevice.horizontalPadding;

  /// Get recommended vertical padding
  double get verticalPadding => responsiveDevice.verticalPadding;

  /// Get maximum content width
  double get maxContentWidth => responsiveDevice.maxContentWidth;

  /// Get recommended border radius
  double get borderRadius => responsiveDevice.borderRadius;

  /// Get title font size
  double get titleFontSize => responsiveDevice.titleFontSize;

  /// Get body font size
  double get bodyFontSize => responsiveDevice.bodyFontSize;

  /// Get app bar height
  double get appBarHeight => responsiveDevice.appBarHeight;

  /// Get responsive value based on device type
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    return responsiveDevice.value(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Responsive Grid widget
///
/// A grid that automatically adjusts its column count based on screen size.
///
/// Usage:
/// ```dart
/// ResponsiveGrid(
///   children: [
///     Card(child: Text('Item 1')),
///     Card(child: Text('Item 2')),
///     Card(child: Text('Item 3')),
///   ],
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, device) {
        final columns = device.value(
          mobile: mobileColumns ?? 1,
          tablet: tabletColumns ?? 2,
          desktop: desktopColumns ?? device.gridColumns,
        );

        final effectiveSpacing = spacing ?? device.spacing;
        final effectiveRunSpacing = runSpacing ?? device.spacing;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: effectiveSpacing,
          mainAxisSpacing: effectiveRunSpacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

/// Responsive Container with centered content
///
/// A container that limits content width on larger screens and centers it.
///
/// Usage:
/// ```dart
/// ResponsiveContainer(
///   child: Column(
///     children: [
///       Text('Content'),
///     ],
///   ),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.applyHorizontalPadding = true,
    this.applyVerticalPadding = false,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool applyHorizontalPadding;
  final bool applyVerticalPadding;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, device) {
        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: device.maxContentWidth),
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: applyHorizontalPadding
                      ? device.horizontalPadding
                      : 0,
                  vertical: applyVerticalPadding ? device.verticalPadding : 0,
                ),
            child: child,
          ),
        );
      },
    );
  }
}
