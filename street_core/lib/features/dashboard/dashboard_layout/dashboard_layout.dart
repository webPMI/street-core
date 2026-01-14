import 'package:street_core/features/dashboard/dashboard_layout/dashboard_drawer.dart';

import '../../../core/widgets/drawer/my_drawer.dart';
import 'package:flutter/material.dart';

/// Main layout wrapper for dashboard pages.
///
/// This layout no longer includes a Scaffold - each page must provide its own.
/// Use `DashboardLayout.drawer` to get the configured drawer widget.
///
/// Each page should provide its own AppBar in its Scaffold.
class DashboardLayout extends StatelessWidget {
  const DashboardLayout({
    super.key,
    required this.child,
    this.animateTransitions = true,
  });
  final Widget child;
  final bool animateTransitions;

  /// Returns a configured drawer widget for dashboard pages.
  /// Call `DashboardDrawer.setup(context)` before using this.
  static Widget getDrawer(BuildContext context) {
    DashboardDrawer.setup(context);
    return MyDrawer();
  }

  /// Convenience getter for drawer (requires context in build method).
  /// Prefer using `getDrawer(context)` in page's Scaffold.
  static Widget get drawer => MyDrawer();

  @override
  Widget build(BuildContext context) {
    // Setup drawer configuration for when pages request it
    DashboardDrawer.setup(context);

    // Return child directly without Scaffold
    return animateTransitions ? _buildAnimatedChild() : child;
  }

  Widget _buildAnimatedChild() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
