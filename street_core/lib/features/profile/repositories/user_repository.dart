import '../../../core/crud/base_repository.dart';
import '../../../core/helpers/logger.dart';
import '../../../core/services/api_uris.dart';
import '../../../data/models/user_model.dart';

/// User Repository
/// Handles all user-related API calls (profiles, follow system, etc.)
class UserRepository extends BaseRepository {
  UserRepository(super.apiService);

  /// Get user by ID
  /// Endpoint: GET /api/v1/users/:id
  Future<UserModel> getUserById(String userId) async {
    return fetchById<UserModel>(
      endpoint: '${ApiUris.api}/users/$userId',
      fromJson: UserModel.fromJson,
      errorMessage: 'Failed to fetch user profile',
    );
  }

  /// Get current user profile
  /// Endpoint: GET /api/v1/users/me
  Future<UserModel> getCurrentUser() async {
    return fetchById<UserModel>(
      endpoint: ApiUris.profile,
      fromJson: UserModel.fromJson,
      errorMessage: 'Failed to fetch current user',
      useCache: false, // Don't cache current user
    );
  }

  /// Update current user profile
  /// Endpoint: PUT /api/v1/users/me
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return executeSafely<UserModel>(
      operation: () async {
        AppLogger.info('Updating user profile', tag: 'UserRepository');

        final response = await apiService.useFetch<Map<String, dynamic>>(
          ApiUris.updateProfile,
          method: 'PUT',
          body: data,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          // Invalidate user cache after update
          clearCachePrefix('item_${ApiUris.api}/users/');
          return UserModel.fromJson(response.data!);
        } else {
          throw Exception(response.message);
        }
      },
      errorMessage: 'Failed to update profile',
      tag: 'UserRepository',
      enableRetry: false,
    );
  }

  /// Get user's followers
  /// Endpoint: GET /api/v1/users/:id/followers
  Future<List<UserModel>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return executeSafely<List<UserModel>>(
      operation: () async {
        AppLogger.info(
          'Fetching followers for user: $userId',
          tag: 'UserRepository',
        );

        final endpoint =
            '${ApiUris.api}/users/$userId/followers?page=$page&limit=$limit';
        final response = await apiService.useFetch<List<dynamic>>(
          endpoint,
          method: 'GET',
          fromJsonT: (data) => data as List<dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          return response.data!
              .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(response.message);
        }
      },
      errorMessage: 'Failed to fetch followers',
      tag: 'UserRepository',
    );
  }

  /// Get user's following
  /// Endpoint: GET /api/v1/users/:id/following
  Future<List<UserModel>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return executeSafely<List<UserModel>>(
      operation: () async {
        AppLogger.info(
          'Fetching following for user: $userId',
          tag: 'UserRepository',
        );

        final endpoint =
            '${ApiUris.api}/users/$userId/following?page=$page&limit=$limit';
        final response = await apiService.useFetch<List<dynamic>>(
          endpoint,
          method: 'GET',
          fromJsonT: (data) => data as List<dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          return response.data!
              .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(response.message);
        }
      },
      errorMessage: 'Failed to fetch following',
      tag: 'UserRepository',
    );
  }
}
