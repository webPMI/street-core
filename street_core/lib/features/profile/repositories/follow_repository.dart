// lib/features/profile/repositories/follow_repository.dart

import '../../../core/crud/base_repository.dart';
import '../../../core/services/api_uris.dart';
import '../../../data/models/paginated_result.dart';
import '../../../data/models/user_model.dart';

/// Repositorio de Seguimiento - Llamadas API para funcionalidad de seguir/dejar de seguir
class FollowRepository extends BaseRepository {
  FollowRepository(super.apiService);

  /// Seguir a un usuario
  Future<void> followUser(String followingId) async {
    await executeAction(
      endpoint: ApiUris.followUser(followingId),
      method: 'POST',
      errorMessage: 'Error following user',
      enableRetry: false,
    );

    // Clear cache for followers/following lists
    clearCachePattern('followers_');
    clearCachePattern('following_');
  }

  /// Dejar de seguir a un usuario
  Future<void> unfollowUser(String followingId) async {
    await executeAction(
      endpoint: ApiUris.unfollowUser(followingId),
      method: 'DELETE',
      errorMessage: 'Error unfollowing user',
      enableRetry: false,
    );

    // Clear cache for followers/following lists
    clearCachePattern('followers_');
    clearCachePattern('following_');
  }

  /// Obtener seguidores de un usuario con paginación
  Future<PaginatedResult<User>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<User>(
      endpoint: ApiUris.getUserFollowers(userId),
      fromJson: User.fromJson,
      page: page,
      limit: limit,
      errorMessage: 'Error fetching followers',
    );
  }

  /// Obtener usuarios que un usuario está siguiendo con paginación
  Future<PaginatedResult<User>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<User>(
      endpoint: ApiUris.getUserFollowing(userId),
      fromJson: User.fromJson,
      page: page,
      limit: limit,
      errorMessage: 'Error fetching following',
    );
  }

  /// Verificar si un usuario está siguiendo a otro usuario
  Future<bool> isFollowing(String followingId) async {
    return executeSafely<bool>(
      operation: () async {
        final response =
            await apiService.get(ApiUris.getFollowStatus(followingId));

        if (response.status == 'success' && response.data != null) {
          return response.data!['isFollowing'] as bool? ?? false;
        }

        return false;
      },
      errorMessage: 'Error checking follow status',
    );
  }

  /// Obtener conteo de seguidores
  Future<int> getFollowersCount(String userId) async {
    return executeSafely<int>(
      operation: () async {
        final response = await apiService.get(
          '${ApiUris.getUserById(userId)}/followers/count',
        );

        if (response.status == 'success' && response.data != null) {
          return response.data!['count'] as int? ?? 0;
        }

        return 0;
      },
      errorMessage: 'Error fetching followers count',
    );
  }

  /// Obtener conteo de seguidos
  Future<int> getFollowingCount(String userId) async {
    return executeSafely<int>(
      operation: () async {
        final response = await apiService.get(
          '${ApiUris.getUserById(userId)}/following/count',
        );

        if (response.status == 'success' && response.data != null) {
          return response.data!['count'] as int? ?? 0;
        }

        return 0;
      },
      errorMessage: 'Error fetching following count',
    );
  }

  /// Obtener seguidores mutuos (usuarios que se siguen mutuamente)
  Future<PaginatedResult<User>> getMutualFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    return fetchPaginatedList<User>(
      endpoint: '/users/$userId/mutual-followers',
      fromJson: User.fromJson,
      page: page,
      limit: limit,
      errorMessage: 'Error fetching mutual followers',
    );
  }

  /// Obtener usuarios sugeridos para seguir
  Future<List<User>> getSuggestedUsers({int limit = 10}) async {
    return fetchList<User>(
      endpoint: '/users/suggested',
      fromJson: User.fromJson,
      errorMessage: 'Error fetching suggested users',
    );
  }
}
