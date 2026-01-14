// lib/features/social/like/like_service.dart

import '../../../core/helpers/logger.dart';
import 'like_repository.dart';

/// Servicio de Me Gusta - Lógica de negocio para operaciones de me gusta
/// Soporta likes en cualquier tipo de entidad (posts, competitions, events, clubs, etc.)
/// Siguiendo la arquitectura Monolith-by-Features
class LikeService {
  LikeService(this._likeRepository);

  final LikeRepository _likeRepository;

  // ============================================================================
  // GENERIC ENTITY METHODS (NEW - Reusable for any entity)
  // ============================================================================

  /// Toggle like on any entity (post, competition, event, etc.)
  /// Returns true if now liked, false if unliked
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  Future<bool> toggleLikeEntity({
    required String entityType,
    required String entityId,
    required bool isCurrentlyLiked,
  }) async {
    AppLogger.info(
      'Toggling like for $entityType: $entityId (currently: $isCurrentlyLiked)',
      tag: 'LikeService',
    );

    return await _likeRepository.toggleLikeEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }

  /// Give like to any entity
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  Future<void> likeEntity({
    required String entityType,
    required String entityId,
  }) async {
    AppLogger.info('Liking $entityType: $entityId', tag: 'LikeService');
    await _likeRepository.likeEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }

  /// Remove like from any entity
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  Future<void> unlikeEntity({
    required String entityType,
    required String entityId,
  }) async {
    AppLogger.info('Unliking $entityType: $entityId', tag: 'LikeService');
    await _likeRepository.unlikeEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }

  /// Check if entity is liked by current user
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  Future<bool> isEntityLiked({
    required String entityType,
    required String entityId,
  }) async {
    AppLogger.debug(
      'Checking like status for $entityType: $entityId',
      tag: 'LikeService',
    );
    return await _likeRepository.isEntityLiked(
      entityType: entityType,
      entityId: entityId,
    );
  }

  /// Get likes for any entity
  Future<List<dynamic>> getEntityLikes({
    required String entityType,
    required String entityId,
  }) async {
    AppLogger.debug('Fetching likes for $entityType: $entityId', tag: 'LikeService');
    return await _likeRepository.getLikesByEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }

  // ============================================================================
  // POST-SPECIFIC METHODS (Legacy - Backward compatibility)
  // ============================================================================

  /// Alternar me gusta en una publicación
  /// Devuelve true si se dio me gusta, false si se quitó
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  @Deprecated('Use toggleLikeEntity with entityType: "post" instead')
  Future<bool> toggleLike(String postId, bool isCurrentlyLiked) async {
    return toggleLikeEntity(
      entityType: 'post',
      entityId: postId,
      isCurrentlyLiked: isCurrentlyLiked,
    );
  }

  /// Dar me gusta a una publicación
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  @Deprecated('Use likeEntity with entityType: "post" instead')
  Future<void> likePost(String postId) async {
    await likeEntity(entityType: 'post', entityId: postId);
  }

  /// Quitar me gusta a una publicación
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  @Deprecated('Use unlikeEntity with entityType: "post" instead')
  Future<void> unlikePost(String postId) async {
    await unlikeEntity(entityType: 'post', entityId: postId);
  }

  /// Verificar si el usuario actual ha dado like a un post
  /// NOTA: El userId se obtiene automáticamente del token JWT en el backend
  @Deprecated('Use isEntityLiked with entityType: "post" instead')
  Future<bool> isLiked(String postId) async {
    return isEntityLiked(entityType: 'post', entityId: postId);
  }

  /// Obtener lista de likes de un post
  @Deprecated('Use getEntityLikes with entityType: "post" instead')
  Future<List<dynamic>> getLikes(String postId) async {
    return getEntityLikes(entityType: 'post', entityId: postId);
  }
}
