import '../../core/router/app_routes.dart';

class ProfileRoutes {
  // ===========================================================================
  // BASE PATH - Centralized dashboard prefix
  // ===========================================================================
  static String get _base => AppRoutes.dashboard; // '/dashboard'

  // ===========================================================================
  // ABSOLUTE PATHS (for navigation with NavigationService)
  // All routes are under /dashboard
  // ===========================================================================

  // Profile: /dashboard/profile/*
  static String get profile => '$_base/profile';
  static String get profileEdit => '$_base/profile/edit';
  static String get changePassword => '$_base/profile/change-password';
  static String get savedPosts => '$_base/profile/saved';

  // Posts: /dashboard/posts/*
  static String get postsFeed => '$_base/posts';
  static String get postCreate => '$_base/posts/create';
  static String get postDetail => '$_base/posts/:id';

  // ===========================================================================
  // HELPER METHODS (for building routes with parameters)
  // ===========================================================================

  static String getUserProfile(String userId) => '$_base/profile/user/$userId';
  static String getUserFollowers(String userId) =>
      '$_base/profile/user/$userId/followers';
  static String getUserFollowing(String userId) =>
      '$_base/profile/user/$userId/following';
  static String getPostDetail(String postId) => '$_base/posts/$postId';
}
