import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:street_core/core/widgets/drawer/drawer_item.dart';

import '../../../core/lang/context_tr.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/buttons/animated_nav_button.dart';
import '../../../core/widgets/drawer/drawer_config.dart';
import '../../../core/widgets/my_text.dart';

/// Desktop navigation bar with public page links
///
/// Displays navigation buttons for all public pages with:
/// - Active state highlighting
/// - Compact mode (icons only) or full mode (icons + labels)
/// - Centralized navigation using NavigationService
///
/// Usage:
/// ```dart
/// PublicNavBar(
///   activePage: PublicPage.home,
///   isCompact: screenWidth < 1400,
/// )
/// ```
class PublicNavBar extends StatelessWidget {
  PublicNavBar({super.key, required this.isCompact});

  /// Whether to show compact mode (icons only)
  final bool isCompact;

  /// Navigation service from GetIt
  final NavigationService _navService = GetIt.I<NavigationService>();

  static const double _iconSize = 20;
  static const double _compactSpacing = 4;
  static const double _normalSpacing = 8;

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Iterate over all navigation items using NavigationConfig
        ...DrawerConfig.drawerElements.expand(
          (item) => [
            if (item.isDivider != true)
              if (item.route != null)
                AnimatedNavButton(
                  isActive: currentLocation == item.route,
                  onPressed: item.route != null
                      ? () => _navService.go(context, item.route!)
                      : item.onTap,

                  label: item.labelKey,
                  child: _buildButtonChild(context, item),
                ),
            SizedBox(width: isCompact ? _compactSpacing : _normalSpacing),
          ],
        ),
      ],
    );
  }

  /// Builds button child based on compact/full mode
  Widget _buildButtonChild(BuildContext context, DrawerItem item) {
    if (isCompact) {
      return Tooltip(
        message: context.tr(item.labelKey ?? ''),
        child: Icon(item.icon),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: _iconSize),
        const SizedBox(width: 6),
        MyText(item.labelKey ?? ''),
      ],
    );
  }
}
