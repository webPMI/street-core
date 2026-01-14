// lib/data/services/api_uri.dart

import '/config/env.dart';

class ApiUris {
  // ============================================================================
  // VERSION CONTROL - Change here to migrate all endpoints
  static const String _apiVersion = Env.apiVersion;

  /// API prefix with version
  static const String api = '/api/$_apiVersion';

  // ============================================================================
  // AUTHENTICATION & AUTHORIZATION
  /// POST /api/version/auth/login
  static const String login = '$api/auth/login';
  static const String register = '$api/auth/register';
  static const String logout = '$api/auth/logout';
  static const String refreshToken = '$api/auth/refresh';
  static const String forgotPassword = '$api/auth/forgot-password';
  static const String resetPassword = '$api/auth/reset-password';
  static const String validateToken = '$api/auth/validate-token';
  // ============================================================================
  // SITE CONFIG (Public - on-demand loading by section)
  // ============================================================================

  /// GET /api/version/site-config (Full config - for admin panel)
  static const String getSiteConfig = '$api/site-config';

  /// GET /api/version/site-config/basic (company + social - for header/footer)
  static const String getSiteConfigBasic = '$api/site-config/basic';

  /// GET /api/version/site-config/contact (contact info only)
  static const String getSiteConfigContact = '$api/site-config/contact';

  /// GET /api/version/site-config/social (social media links only)
  static const String getSiteConfigSocial = '$api/site-config/social';

  /// GET /api/version/site-config/legal (legal texts only - privacy, terms, etc.)
  static const String getSiteConfigLegal = '$api/site-config/legal';

  /// GET /api/version/site-config/company (company info only)
  static const String getSiteConfigCompany = '$api/site-config/company';

  /// GET /api/version/site-config/seo (SEO config only)
  static const String getSiteConfigSeo = '$api/site-config/seo';

  /// GET /api/version/site-config/landing (landing page texts only)
  static const String getSiteConfigLanding = '$api/site-config/landing';

  /// GET /api/version/site-config/app (app config only - maintenance, versions)
  static const String getSiteConfigApp = '$api/site-config/app';

  // ============================================================================
  // USER PROFILE & SETTINGS
  /// GET /api/version/users/me (Obtener el perfil del usuario logueado)
  static const String profile = '$api/users/me';

  /// GET /api/version/users/:id (Get user profile by ID)
  static String getUserById(String userId) => '$api/users/$userId';

  /// PUT /api/version/users/me (Actualizar información básica del perfil)
  static const String updateProfile = '$api/users/me';
  static const String updateSettings = '$api/users/me/settings';
  static const String deleteAccount = '$api/users/me';

  /// PUT /api/version/users/me/change-password (Cambiar contraseña)
  static const String changePassword = '$api/users/me/change-password';
  static const String getSettings = '$api/users/me/settings';

  /// POST /api/media/upload/avatar - Upload user avatar (max 5MB)
  /// Requires: JWT authentication
  /// Content-Type: multipart/form-data
  /// Field name: 'file'
  /// Returns: { url: string, filename: string }
  static const String uploadAvatar = '$api/media/upload/avatar';

  /// POST /api/admin/users/me/upload-photo - Upload/update profile photo
  /// Requires: JWT authentication
  /// Content-Type: multipart/form-data
  static const String uploadProfilePhoto = '$api/admin/users/me/upload-photo';

  // ============================================================================
  // FOLLOW SYSTEM
  /// POST /api/version/users/:id/follow (Follow user)
  static String followUser(String userId) => '$api/users/$userId/follow';

  /// DELETE /api/version/users/:id/follow (Unfollow user)
  static String unfollowUser(String userId) => '$api/users/$userId/follow';

  /// GET /api/version/users/:id/followers (Get user's followers)
  static String getUserFollowers(String userId) =>
      '$api/users/$userId/followers';

  /// GET /api/version/users/:id/following (Get user's following)
  static String getUserFollowing(String userId) =>
      '$api/users/$userId/following';

  /// GET /api/version/users/:id/follow/status (Check follow status with user)
  static String getFollowStatus(String userId) =>
      '$api/users/$userId/follow/status';

  // ============================================================================
  // DASHBOARD & NOTIFICATIONS
  static const String dashboardStats = '$api/dashboard/stats';

  /// GET /notifications
  static const String notifications = '$api/notifications';

  /// GET /api/version/products (Public - no authentication required)
  static const String productsList = '$api/products';

  // ============================================================================
  // MEDIA UPLOAD
  // ============================================================================

  /// POST /api/version/media/upload/image - Upload image (max 10MB)
  /// Requires: JWT authentication
  /// Content-Type: multipart/form-data
  /// Field name: 'file'
  /// Supported formats: jpg, jpeg, png, gif, webp
  /// Returns: { url: string, filename: string }
  static const String uploadImage = '$api/media/upload/image';

  /// POST /api/version/media/upload/video - Upload video (max 500MB)
  /// Requires: JWT authentication
  /// Content-Type: multipart/form-data
  /// Field name: 'file'
  /// Supported formats: mp4, webm, mpeg, mov, avi
  /// Returns: { url: string, filename: string }
  static const String uploadVideo = '$api/media/upload/video';

  /// POST /api/version/media/upload/multiple - Upload multiple files (max 10 files)
  /// Requires: JWT authentication
  /// Content-Type: multipart/form-data
  /// Field name: 'files'
  /// Each file validated separately
  /// Returns: { urls: string[], filenames: string[] }
  static const String uploadMultiple = '$api/media/upload/multiple';

  /// DELETE /api/version/media/:filename - Delete uploaded media
  /// Requires: JWT authentication
  /// Only file owner can delete
  /// Returns: { status: 'success', message: 'file_deleted_successfully' }
  static String deleteMedia(String filename) => '$api/media/$filename';

  // ============================================================================
  // PRIVACY SETTINGS
  // ============================================================================

  /// GET /api/version/users/me/privacy (Get privacy settings - protected)
  static const String userPrivacySettings = '$api/users/me/privacy';

  /// PUT /api/version/users/me/privacy (Update privacy settings - protected)
  static const String updateUserPrivacy = '$api/users/me/privacy';

  /// POST /api/version/users/me/privacy/block (Block user - protected)
  static const String blockUser = '$api/users/me/privacy/block';

  /// DELETE /api/version/users/me/privacy/block/:userId (Unblock user - protected)
  static String unblockUser(String userId) {
    return '$api/users/me/privacy/block/$userId';
  }

  /// GET /api/version/users/me/privacy/blocked (Get blocked users - protected)
  static const String getBlockedUsers = '$api/users/me/privacy/blocked';

  // ============================================================================
  // CONTACT MESSAGES (PUBLIC)
  // ============================================================================

  /// POST /api/version/contact - Submit contact form (public, rate limited)
  static const String submitContactMessage = '$api/contact';
}
