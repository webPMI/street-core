import '../../core/crud/base_repository.dart';
import '../../core/helpers/logger.dart';
import '../../core/services/api_uris.dart';
import '../models/user_model.dart';

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
        AppLogger.debug('Updating user profile at: ${ApiUris.updateProfile}', tag: 'UserRepository');

        final response = await apiService.useFetch<Map<String, dynamic>>(
          ApiUris.updateProfile,
          method: 'PUT',
          body: data,
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        if (response.status == 'success' && response.data != null) {
          AppLogger.debug('Successfully updated user profile', tag: 'UserRepository');
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
      debugContext: {
        'endpoint': ApiUris.updateProfile,
        'method': 'PUT',
        'dataKeys': data.keys.toList(),
      },
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
        final endpoint =
            '${ApiUris.api}/users/$userId/followers?page=$page&limit=$limit';

        AppLogger.debug('Fetching followers for user: $userId (page: $page, limit: $limit)', tag: 'UserRepository');

        final response = await apiService.useFetch<Map<String, dynamic>>(
          endpoint,
          method: 'GET',
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        AppLogger.debug('Response received - status: ${response.status}, hasData: ${response.data != null}, message: ${response.message}', tag: 'UserRepository');

        if (response.status == 'success') {
          // Handle empty response (no data)
          if (response.data == null) {
            AppLogger.debug('Response data is null, returning empty list', tag: 'UserRepository');
            return [];
          }

          // Backend returns paginated structure: {data: [...], pagination: {...}}
          final dataList = response.data!['data'] as List<dynamic>?;

          if (dataList == null) {
            AppLogger.error('Response data does not contain "data" field. Keys: ${response.data!.keys.toList()}', tag: 'UserRepository');
            return []; // Return empty list instead of throwing
          }

          final result = dataList
              .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
              .toList();
          AppLogger.debug('Successfully fetched ${result.length} followers for user: $userId', tag: 'UserRepository');
          return result;
        } else {
          throw Exception(response.message);
        }
      },
      errorMessage: 'Failed to fetch followers',
      tag: 'UserRepository',
      debugContext: {
        'endpoint': '${ApiUris.api}/users/$userId/followers',
        'method': 'GET',
        'userId': userId,
        'page': page,
        'limit': limit,
      },
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
        final endpoint =
            '${ApiUris.api}/users/$userId/following?page=$page&limit=$limit';

        AppLogger.debug('Fetching following for user: $userId (page: $page, limit: $limit)', tag: 'UserRepository');

        final response = await apiService.useFetch<Map<String, dynamic>>(
          endpoint,
          method: 'GET',
          fromJsonT: (data) => data as Map<String, dynamic>,
        );

        AppLogger.debug('Response received - status: ${response.status}, hasData: ${response.data != null}, message: ${response.message}', tag: 'UserRepository');

        if (response.status == 'success') {
          // Handle empty response (no data)
          if (response.data == null) {
            AppLogger.debug('Response data is null, returning empty list', tag: 'UserRepository');
            return [];
          }

          // Backend returns paginated structure: {data: [...], pagination: {...}}
          final dataList = response.data!['data'] as List<dynamic>?;

          if (dataList == null) {
            AppLogger.error('Response data does not contain "data" field. Keys: ${response.data!.keys.toList()}', tag: 'UserRepository');
            return []; // Return empty list instead of throwing
          }

          final result = dataList
              .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
              .toList();
          AppLogger.debug('Successfully fetched ${result.length} following for user: $userId', tag: 'UserRepository');
          return result;
        } else {
          throw Exception(response.message);
        }
      },
      errorMessage: 'Failed to fetch following',
      tag: 'UserRepository',
      debugContext: {
        'endpoint': '${ApiUris.api}/users/$userId/following',
        'method': 'GET',
        'userId': userId,
        'page': page,
        'limit': limit,
      },
    );
  }
}
