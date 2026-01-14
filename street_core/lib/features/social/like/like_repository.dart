// lib/features/social/like/like_repository.dart

import '../../../core/crud/base_repository.dart';
import '../../../core/helpers/logger.dart';
import 'like_model.dart';
import 'like_uris.dart';

/// Repositorio de Me Gusta - Llamadas API para gestión de me gusta
/// Soporta likes en cualquier tipo de entidad (posts, competitions, events, clubs, etc.)
class LikeRepository extends BaseRepository {
  LikeRepository(super.apiService);

  // ============================================================================
  // GENERIC ENTITY METHODS (NEW - Reusable for any entity)
  // ============================================================================

  /// Toggle like on any entity (post, competition, event, etc.)
  /// Returns true if now liked, false if unliked
  Future<bool> toggleLikeEntity({
    required String entityType,
    required String entityId,
  }) async {
    AppLogger.debug(
      'Toggling like on $entityType: $entityId',
      tag: 'LikeRepository',
    );

    // First check if already liked
    final isLiked = await isEntityLiked(
      entityType: entityType,
      entityId: entityId,
    );

    final endpoint = isLiked
        ? LikeUris.unlikeEntity(entityType, entityId)
        : LikeUris.likeEntity(entityType, entityId);
    final method = isLiked ? 'DELETE' : 'POST';

    await executeAction(
      endpoint: endpoint,
      method: method,
      errorMessage: 'Error toggling like on $entityType',
      enableRetry: false,
    );

    // Clear cache
    clearCachePattern('likes_${entityType}_$entityId');

    AppLogger.info(
      'Successfully toggled like on $entityType: $entityId (now: ${!isLiked})',
      tag: 'LikeRepository',
    );

    return !isLiked;
  }

  /// Give like to any entity
  Future<void> likeEntity({
    required String entityType,
    required String entityId,
  }) async {
    AppLogger.debug(
      'Liking $entityType: $entityId',
      tag: 'LikeRepository',
    );

    await executeAction(
      endpoint: LikeUris.likeEntity(entityType, entityId),
      method: 'POST',
      errorMessage: 'Error liking $entityType',
      enableRetry: false,
    );

    clearCachePattern('likes_${entityType}_$entityId');

    AppLogger.info('Successfully liked $entityType: $entityId', tag: 'LikeRepository');
  }

  /// Remove like from any entity
  Future<void> unlikeEntity({
    required String entityType,
    required String entityId,
  }) async {
    AppLogger.debug(
      'Unliking $entityType: $entityId',
      tag: 'LikeRepository',
    );

    await executeAction(
      endpoint: LikeUris.unlikeEntity(entityType, entityId),
      method: 'DELETE',
      errorMessage: 'Error unliking $entityType',
      enableRetry: false,
    );

    clearCachePattern('likes_${entityType}_$entityId');

    AppLogger.info('Successfully unliked $entityType: $entityId', tag: 'LikeRepository');
  }

  /// Check if entity is liked by current user
  Future<bool> isEntityLiked({
    required String entityType,
    required String entityId,
  }) async {
    return executeSafely<bool>(
      operation: () async {
        final response = await apiService.get(
          LikeUris.checkEntityLikeStatus(entityType, entityId),
        );

        if (response.status == 'success' && response.data != null) {
          return response.data!['isLiked'] as bool? ?? false;
        }

        return false;
      },
      errorMessage: 'Error checking like status for $entityType',
    );
  }

  /// Get likes for any entity
  Future<List<Like>> getLikesByEntity({
    required String entityType,
    required String entityId,
  }) async {
    return fetchList<Like>(
      endpoint: LikeUris.getEntityLikes(entityType, entityId),
      fromJson: Like.fromJson,
      errorMessage: 'Error fetching likes for $entityType',
      useCache: true,
    );
  }

  // ============================================================================
  // POST-SPECIFIC METHODS (Legacy - Backward compatibility)
  // ============================================================================

  /// Alternar me gusta en una publicación (dar me gusta si no lo tiene, quitar si lo tiene)
  /// NOTA: userId ya no es necesario - el backend usa el token JWT para identificar al usuario
  @Deprecated('Use toggleLikeEntity with entityType: "post" instead')
  Future<void> toggleLike({
    required String postId,
  }) async {
    await toggleLikeEntity(entityType: 'post', entityId: postId);
  }

  /// Dar me gusta a una publicación
  /// NOTA: userId ya no es necesario - el backend usa el token JWT para identificar al usuario
  @Deprecated('Use likeEntity with entityType: "post" instead')
  Future<void> likePost({
    required String postId,
  }) async {
    await likeEntity(entityType: 'post', entityId: postId);
  }

  /// Quitar me gusta a una publicación
  /// NOTA: userId ya no es necesario - el backend usa el token JWT para identificar al usuario
  @Deprecated('Use unlikeEntity with entityType: "post" instead')
  Future<void> unlikePost({
    required String postId,
  }) async {
    await unlikeEntity(entityType: 'post', entityId: postId);
  }

  /// Obtener me gustas de una publicación
  @Deprecated('Use getLikesByEntity with entityType: "post" instead')
  Future<List<Like>> getLikesByPost(String postId) async {
    return getLikesByEntity(entityType: 'post', entityId: postId);
  }

  /// Verificar si el usuario ha dado me gusta a una publicación
  /// NOTA: userId ya no es necesario - el backend usa el token JWT para identificar al usuario
  @Deprecated('Use isEntityLiked with entityType: "post" instead')
  Future<bool> isPostLiked({
    required String postId,
  }) async {
    return isEntityLiked(entityType: 'post', entityId: postId);
  }

  /// Obtener publicaciones que le gustan al usuario actual
  /// NOTA: userId ya no es necesario - el backend usa el token JWT para identificar al usuario
  Future<List<String>> getLikedPostIds() async {
    return executeSafely<List<String>>(
      operation: () async {
        final response = await apiService.get(LikeUris.getMyLikes);

        if (response.status == 'success' && response.data != null) {
          final postIds = response.data!['postIds'] as List<dynamic>? ?? [];
          return postIds.map((id) => id.toString()).toList();
        }

        return [];
      },
      errorMessage: 'Error fetching liked posts',
    );
  }
}
