import '../../../core/widgets/drawer/drawer_config.dart';
import '../public_drawer.dart';

import '../../../../core/widgets/drawer/my_drawer.dart';

import 'package:flutter/material.dart';

import '../consent/consent_banner.dart';

// ============================================================================
// PUBLIC LAYOUT WIDGET
// ============================================================================

/// Main layout wrapper for public pages.
///
/// This layout no longer includes a Scaffold - each page must provide its own.
/// Use `PublicLayout.getDrawer()` to get the configured public drawer widget.
class PublicLayout extends StatelessWidget {
  const PublicLayout({super.key, required this.child});

  /// Child page to display in the body
  final Widget child;

  /// Returns a configured drawer widget for public pages.
  static Widget getDrawer() {
    DrawerConfig.drawerElements = PublicDrawer().getDrawer();
    return MyDrawer();
  }

  /// Convenience getter for drawer.
  static Widget get drawer {
    DrawerConfig.drawerElements = PublicDrawer().getDrawer();
    return MyDrawer();
  }

  @override
  Widget build(BuildContext context) {
    // Setup drawer configuration for when pages request it
    DrawerConfig.drawerElements = PublicDrawer().getDrawer();

    // Return child directly without Scaffold
    return SafeArea(
      child: Scaffold(body: Stack(children: [child, const ConsentBanner()])),
    );
  }
}
