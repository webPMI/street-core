import 'package:flutter/material.dart';
import 'package:street_core/core/widgets/drawer/drawer_item.dart';

/// Centralized configuration for drawer navigation items.
///
/// Provides a single source of truth for drawer navigation,
/// making it easy to add/remove/reorder items.
class DrawerConfig {
  DrawerConfig._();

  static List<DrawerItem> drawerElements = [
    // Home
    DrawerItem(
      route: '/',
      icon: Icons.home,
      labelKey: 'home',
    ),

    // Competitions Dashboard
    DrawerItem(
      route: '/competitions',
      icon: Icons.emoji_events,
      labelKey: 'competitions',
    ),

    // Divider
    DrawerItem(isDivider: true),
  ];
}
