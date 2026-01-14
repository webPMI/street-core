import './pages/data_usage_page.dart';
import './pages/help_center_page.dart';
import './pages/notification_settings_page.dart';
import './pages/privacy_settings_page.dart';
import './pages/settings_page.dart';
import 'package:go_router/go_router.dart';

final settingsRoutes = [
  GoRoute(
    path: 'settings',
    builder: (context, state) => const SettingsPage(),
    routes: [
      GoRoute(
        path: 'privacy', // Matches /dashboard/settings/privacy
        builder: (context, state) => const PrivacySettingsPage(),
      ),
      GoRoute(
        path: 'notifications', // Matches /dashboard/settings/notifications
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: 'data', // Matches /dashboard/settings/data
        builder: (context, state) => const DataUsagePage(),
      ),
      GoRoute(
        path: 'help', // Matches /dashboard/settings/help
        builder: (context, state) => const HelpCenterPage(),
      ),
    ],
  ),
];
