import '/core/helpers/responsive/breakpoints.dart';
import 'package:flutter/material.dart';

/// Configuration for responsive grid columns
class GridConfig {
  const GridConfig({
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.childAspectRatio,
    this.padding = const EdgeInsets.all(16),
  });

  /// Number of columns for mobile (default: 1)
  final int mobileColumns;

  /// Number of columns for tablet (default: 2)
  final int tabletColumns;

  /// Number of columns for desktop (default: 4)
  final int desktopColumns;

  /// Horizontal spacing between items
  final double crossAxisSpacing;

  /// Vertical spacing between items
  final double mainAxisSpacing;

  /// Child aspect ratio (width / height)
  final double? childAspectRatio;

  /// Padding around the grid
  final EdgeInsets padding;

  /// Preset for card grids
  static const cards = GridConfig(desktopColumns: 3, childAspectRatio: 1.2);

  /// Preset for image galleries (like Instagram)
  static const gallery = GridConfig(
    mobileColumns: 3,
    tabletColumns: 4,
    desktopColumns: 6,
    childAspectRatio: 1,
    crossAxisSpacing: 2,
    mainAxisSpacing: 2,
    padding: EdgeInsets.all(2),
  );

  /// Preset for profile posts grid
  static const profilePosts = GridConfig(
    mobileColumns: 3,
    tabletColumns: 4,
    desktopColumns: 5,
    childAspectRatio: 1,
    crossAxisSpacing: 2,
    mainAxisSpacing: 2,
    padding: EdgeInsets.all(2),
  );

  /// Preset for list-style content
  static const list = GridConfig(
    tabletColumns: 1,
    desktopColumns: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 24,
  );

  /// Preset for dashboard widgets
  static const dashboard = GridConfig(childAspectRatio: 1.5);

  /// Preset for analytics cards
  static const analytics = GridConfig(
    mobileColumns: 2,
    tabletColumns: 3,
    childAspectRatio: 1.3,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );
}

/// A responsive grid that adapts columns based on screen size.
///
/// Usage:
/// ```dart
/// ResponsiveGrid(
///   config: GridConfig.cards,
///   children: items.map((item) => ItemCard(item)).toList(),
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.config = const GridConfig(),
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });
  final List<Widget> children;
  final GridConfig config;

  /// Optional: override columns for specific device type
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  /// Whether the grid should shrink wrap its contents
  final bool shrinkWrap;

  /// The scroll physics
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _getColumns(width);

        return Padding(
          padding: config.padding,
          child: GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: config.crossAxisSpacing,
              mainAxisSpacing: config.mainAxisSpacing,
              childAspectRatio: config.childAspectRatio ?? 1.0,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }

  int _getColumns(double width) {
    if (width >= Breakpoints.desktop) {
      return desktopColumns ?? config.desktopColumns;
    } else if (width > Breakpoints.mobile) {
      return tabletColumns ?? config.tabletColumns;
    } else {
      return mobileColumns ?? config.mobileColumns;
    }
  }
}

/// Get responsive column count for GridView based on screen width
int getResponsiveColumnCount(
  BuildContext context, {
  int mobile = 1,
  int tablet = 2,
  int desktop = 4,
}) {
  final width = MediaQuery.of(context).size.width;

  if (width >= Breakpoints.desktop) {
    return desktop;
  } else if (width > Breakpoints.mobile) {
    return tablet;
  } else {
    return mobile;
  }
}

/// Get responsive column count for posts grid (Instagram-style)
int getPostsGridColumnCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= Breakpoints.desktopLarge) return 6;
  if (width >= Breakpoints.desktopMedium) return 5;
  if (width >= Breakpoints.desktop) return 4;
  if (width >= Breakpoints.tabletMedium) return 4;
  if (width >= Breakpoints.tabletSmall) return 3;
  return 3; // Mobile default
}
