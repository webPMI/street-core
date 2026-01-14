import '../../core/router/app_routes.dart';

/// Settings Routes Configuration
///
/// Centralizes all settings-related route paths.
/// Following Monolith-by-Features architecture (ADR-005).
class SettingsRoutes {
  // ===========================================================================
  // BASE PATH - Centralized dashboard prefix
  // ===========================================================================
  static String get _base => AppRoutes.dashboard; // '/dashboard'

  // ===========================================================================
  // ABSOLUTE PATHS (for navigation with go_router)
  // All routes are under /dashboard/settings/*
  // ===========================================================================

  /// Main settings page: /dashboard/settings
  static String get settings => '$_base/settings';

  /// Privacy settings: /dashboard/settings/privacy
  static String get privacy => '$settings/privacy';

  /// Notification settings: /dashboard/settings/notifications
  static String get notifications => '$settings/notifications';

  /// Data usage settings: /dashboard/settings/data
  static String get data => '$settings/data';

  /// Help center: /dashboard/settings/help
  static String get help => '$settings/help';
}
