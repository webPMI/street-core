// navigation_service.dart

import '../helpers/device_storage.dart'; // Relative path
import '../di/injection.dart'; // For getIt

import 'app_routes.dart'; // Relative path
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Enhanced navigation service with type-safe navigation
///
/// Provides centralized navigation logic with:
/// - Type-safe navigation methods
/// - Route persistence for protected routes
/// - PublicPage enum support
/// - Navigation history tracking
class NavigationService {
  factory NavigationService() => _instance;
  NavigationService._internal();
  // Singleton pattern
  static final NavigationService _instance = NavigationService._internal();

  // Get StorageService from DI when needed
  StorageService get _storageService => getIt<StorageService>();

  static const _protectedRouteKey = 'last_protected_route';
  // Reserved for future navigation history tracking
  // static const _navigationHistoryKey = 'navigation_history';

  // ============================================================================
  // CORE NAVIGATION
  // ============================================================================

  /// Navigate to any route and save if protected (replaces current route)
  ///
  /// Core navigation method that:
  /// 1. Saves protected routes to device storage
  /// 2. Uses GoRouter for navigation
  /// 3. Tracks navigation history
  void go(BuildContext context, String route, {Object? extra}) {
    saveRoute(route);
    GoRouter.of(context).go(route, extra: extra);
  }

  /// Push a new route onto the stack (preserves back navigation)
  ///
  /// Use this when you want the user to be able to go back.
  /// Example: Navigating to a detail page from a list.
  void push(BuildContext context, String route, {Object? extra}) {
    saveRoute(route);
    GoRouter.of(context).push(route, extra: extra);
  }

  /// Push a new route and get a result back
  ///
  /// Use when you need to receive data from the pushed route.
  Future<T?> pushForResult<T>(BuildContext context, String route, {Object? extra}) {
    saveRoute(route);
    return GoRouter.of(context).push<T>(route, extra: extra);
  }

  /// Pop the current route (go back)
  ///
  /// Optionally pass a result back to the previous route.
  void pop<T>(BuildContext context, [T? result]) {
    GoRouter.of(context).pop(result);
  }

  /// Replace current route with new one
  ///
  /// Use when you don't want the user to go back to the current page.
  /// Example: After login, replace login page with dashboard.
  void replace(BuildContext context, String route, {Object? extra}) {
    saveRoute(route);
    GoRouter.of(context).pushReplacement(route, extra: extra);
  }

  void goWithParams(
    BuildContext context,
    String route,
    Map<String, String> params,
  ) {
    String finalRoute = route;
    params.forEach((key, value) {
      finalRoute = finalRoute.replaceAll(':$key', value);
    });
    go(context, finalRoute);
  }

  void pushWithParams(
    BuildContext context,
    String route,
    Map<String, String> params,
  ) {
    String finalRoute = route;
    params.forEach((key, value) {
      finalRoute = finalRoute.replaceAll(':$key', value);
    });
    push(context, finalRoute);
  }

  // ============================================================================
  // ROUTE PERSISTENCE
  // ============================================================================

  /// Save route to device storage
  ///
  /// Only saves protected routes (those starting with '/dashboard')
  Future<void> saveRoute(String path) async {
    if (path.startsWith('/dashboard')) {
      await _storageService.save(_protectedRouteKey, path);
    }
  }

  /// Get last saved protected route
  Future<String?> getRoute() async {
    return _storageService.read(_protectedRouteKey);
  }

  /// Clear saved route
  Future<void> clearRoute() async {
    await _storageService.delete(_protectedRouteKey);
  }

  // ============================================================================
  // NAVIGATION HELPERS
  // ============================================================================

  /// Go back to previous page
  ///
  /// Uses GoRouter's pop if possible, otherwise navigates to dashboard

  /// Check if can go back
  bool canGoBack(BuildContext context) {
    return GoRouter.of(context).canPop();
  }

  /// Check if current route is dashboard root
  bool isDashboardRoot(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return location == AppRoutes.dashboard;
  }
}
