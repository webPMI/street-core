import 'package:flutter/material.dart';
import 'package:street_core/core/widgets/drawer/drawer_item.dart';
import 'package:street_core/features/competitions/competition_routes.dart';
import 'package:street_core/features/dashboard/dashboard_layout/dashboard_drawer.dart';
import 'package:street_core/features/public/public_drawer.dart';

void setupCompeNavigation() {
  // Routes are now registered at compile-time in public_routes.dart and dashboard_routes.dart

  // Add drawer items for navigation
  PublicDrawer.items.add(
    DrawerItem(
      icon: Icons.emoji_events,
      labelKey: 'competitions',
      route: CompetitionRoutes.competitions,
    ),
  );
  //
  DashboardDrawer.baseElements.add(
    DrawerItem(
      icon: Icons.emoji_events,
      labelKey: 'competitions',
      route: CompetitionRoutes
          .dashboardCompetitionsNav, // Use absolute path for navigation
    ),
  );
}
