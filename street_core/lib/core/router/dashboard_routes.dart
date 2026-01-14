import 'package:go_router/go_router.dart';
import 'package:street_core/features/settings/settings_routes.dart';
import 'app_routes.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/dashboard/dashboard_layout/dashboard_layout.dart';

// Import feature routers directly (routes must be available at compile time)
import '../../features/profile/profile_router.dart';
import '../../features/competitions/competition_router.dart';
import '../../features/tournaments/tournament_router.dart';

final privateRoutes = [
  ShellRoute(
    builder: (context, state, child) {
      return DashboardLayout(child: child);
    },
    routes: [
      // Ruta principal: /dashboard con todas las subrutas anidadas
      GoRoute(
        path: AppRoutes.dashboard, // Path: /dashboard
        builder: (context, state) => const DashboardPage(),
        routes: [
          // Profile feature routes (relative paths under /dashboard)
          ...profileRouter,
          // Competitions feature routes (relative paths under /dashboard)
          ...privateCompetitionRoutes,
          // Tournaments feature routes (relative paths under /dashboard)
          ...privateTournamentRoutes,
          // Add more routes as needed
          ...settingsRoutes,
        ],
      ),
    ],
  ),
];
