import 'package:flutter/material.dart';

import '../my_text.dart';

/// Drawer menu item component
///
/// Reusable list tile for drawer items with:
/// - Icon
/// - Translated label
/// - Active state highlighting
/// - Tap callback
class DrawerItem extends StatelessWidget {
  const DrawerItem({
    super.key,
    this.icon,
    this.labelKey,
    this.isActive,
    this.onTap,
    this.route,
    this.isDivider,
    this.child,
  });
  final IconData? icon;
  final String? labelKey;
  final bool? isActive;
  final VoidCallback? onTap;
  final String? route;
  final bool? isDivider;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = isActive ?? route != null;

    if (child != null) {
      return child!;
    }
    if (isDivider == true) {
      return Divider();
    }
    return ColoredBox(
      color: active
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: active ? theme.colorScheme.primary : null),
        title: MyText(
          labelKey ?? '',
          color: active ? theme.colorScheme.primary : null,
        ),

        onTap: onTap,
      ),
    );
  }
}
