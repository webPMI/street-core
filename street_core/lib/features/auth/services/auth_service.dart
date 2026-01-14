import 'package:street_core/core/services/csrf_service.dart';

import '../../../core/services/api_uris.dart';
import '../../../data/models/user_model.dart';
import '/core/helpers/device_storage.dart';
import '/core/helpers/logger.dart';
import '/core/services/api_service.dart';
import '/core/services/cache_service.dart';
import '/features/auth/models/auth_exceptions.dart';
import '/features/auth/models/auth_tokens.dart';

/// Auth service handles all authentication-related API calls and storage.
class AuthService {
  AuthService(this._apiService, this._storageService, this._cacheService);

  final ApiService _apiService;
  final StorageService _storageService;
  final CacheService _cacheService;

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'current_user_profile';
  static const String _userProfileCacheKey = 'user_profile';

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  /// Login with email and password.
  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.useFetch<Map<String, dynamic>>(
      ApiUris.login,
      method: 'POST',
      requiredToken: false,
      body: {'email': email, 'password': password},
      fromJsonT: (data) => Map<String, dynamic>.from(data),
    );

    if (response.status == 'success' && response.data != null) {
      final tokens = AuthTokens.fromJson(response.data!);
      final userJson = response.data!['user'] as Map<String, dynamic>;

      // Save tokens
      await _saveTokens(tokens);

      // Save user locally
      await _storageService.saveJson(_userKey, userJson);

      // Invalidate cache
      invalidateUserCache();

      return UserModel.fromJson(userJson);
    } else {
      throw AuthException(response.message);
    }
  }

  // ==========================================================================
  // REGISTER
  // ==========================================================================

  /// Register a new user.
  Future<UserModel> register(Map<String, dynamic> userData) async {
    // Map 'username' to 'nickName' for backend compatibility
    if (userData.containsKey('username')) {
      userData['nickName'] = userData.remove('username');
    }

    final response = await _apiService.useFetch<Map<String, dynamic>>(
      ApiUris.register,
      method: 'POST',
      requiredToken: false,
      body: userData,
    );

    if (response.status == 'success' && response.data != null) {
      final tokens = AuthTokens.fromJson(response.data!);
      final userJson = response.data!['user'] as Map<String, dynamic>;

      // Save tokens
      await _saveTokens(tokens);

      // Save user locally
      await _storageService.saveJson(_userKey, userJson);

      // Invalidate cache
      invalidateUserCache();

      return UserModel.fromJson(userJson);
    } else {
      throw AuthException(response.message);
    }
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  /// Logout the current user.
  Future<void> logout() async {
    try {
      final refreshToken = await _storageService.readSecure(_refreshTokenKey);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiService.useFetch(
          ApiUris.logout,
          method: 'POST',
          requiredToken: false,
          body: {'refreshToken': refreshToken},
        );
      }
      CsrfService().clearToken();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Logout API call failed',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      await _clearSession();
    }
  }

  // ==========================================================================
  // SESSION MANAGEMENT
  // ==========================================================================

  /// Get the current auth token.
  Future<String?> getAuthToken() async {
    return _storageService.readSecure(_tokenKey);
  }

  /// Remove the auth token.
  Future<void> removeAuthToken() async {
    await _storageService.deleteSecure(_tokenKey);
  }

  /// Fetch the current user's profile.
  Future<UserModel?> fetchCurrentUserProfile(String token) async {
    try {
      return await _cacheService.getOrFetch<UserModel?>(
        key: _userProfileCacheKey,
        ttl: CacheTTL.userProfile,
        fetchFn: _fetchUserProfileFromApi,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch user profile',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<UserModel?> _fetchUserProfileFromApi() async {
    final response = await _apiService.useFetch<Map<String, dynamic>>(
      ApiUris.profile,
      method: 'GET',
    );

    if (response.status == 'success' && response.data != null) {
      // Extract user from nested response: {"user": {...}}
      final userJson = response.data!['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        AppLogger.error('User data missing from profile response');
        return null;
      }

      final user = UserModel.fromJson(userJson);
      await _storageService.saveJson(_userKey, userJson);
      return user;
    }

    if (response.statusCode == 401) {
      await logout();
      return null;
    }

    return null;
  }

  /// Refresh the access token.
  Future<bool> refreshAccessToken() async {
    return _apiService.refreshToken();
  }

  // ==========================================================================
  // PROFILE MANAGEMENT
  // ==========================================================================

  /// Update user profile.
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.useFetch<Map<String, dynamic>>(
      ApiUris.updateProfile,
      method: 'PUT',
      body: data,
      fromJsonT: (data) => Map<String, dynamic>.from(data),
    );

    if (response.status == 'success' && response.data != null) {
      // Extract user from nested response: {"user": {...}}
      final userJson = response.data!['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw AuthException('user_data_missing');
      }

      await _storageService.saveJson(_userKey, userJson);
      invalidateUserCache();
      return UserModel.fromJson(userJson);
    } else {
      throw AuthException(response.message);
    }
  }

  /// Change password.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final response = await _apiService.useFetch<Map<String, dynamic>>(
      ApiUris.changePassword,
      method: 'PUT',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );

    if (response.status != 'success') {
      throw AuthException(response.message);
    }

    // Force re-login after password change
    await logout();
  }

  /// Request password reset.
  Future<void> resetPasswordRequest(String email) async {
    final response = await _apiService.useFetch<Map<String, dynamic>>(
      ApiUris.resetPassword,
      method: 'POST',
      requiredToken: false,
      body: {'email': email},
    );

    if (response.status != 'success') {
      throw AuthException(response.message);
    }
  }

  // ==========================================================================
  // ACCOUNT MANAGEMENT
  // ==========================================================================

  /// Delete the user's account.
  Future<void> deleteAccount() async {
    final response = await _apiService.useFetch<Map<String, dynamic>>(
      ApiUris.deleteAccount,
      method: 'DELETE',
    );

    if (response.status != 'success') {
      throw AuthException(response.message);
    }

    await _clearSession();
  }

  // ==========================================================================
  // CACHE MANAGEMENT
  // ==========================================================================

  /// Invalidate user-related cache.
  void invalidateUserCache() {
    _cacheService.invalidate(_userProfileCacheKey);
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  Future<void> _saveTokens(AuthTokens tokens) async {
    await _storageService.saveSecure(_tokenKey, tokens.accessToken);
    await _storageService.saveSecure(_refreshTokenKey, tokens.refreshToken);
  }

  Future<void> _clearSession() async {
    await _storageService.deleteSecure(_tokenKey);
    await _storageService.deleteSecure(_refreshTokenKey);
    await _storageService.delete(_userKey);
    invalidateUserCache();
  }
}
