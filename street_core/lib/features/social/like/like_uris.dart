// lib/features/social/like/like_uris.dart

import 'package:street_core/config/env.dart';

/// URIs for like-related API endpoints
/// Centralized URI management for the like feature
class LikeUris {
  // ============================================================================
  // VERSION CONTROL - Change here to migrate all endpoints
  static const String _apiVersion = Env.apiVersion;

  /// API prefix with version
  static const String _api = '/api/$_apiVersion';
  // ============================================================================

  // ============================================================================
  // POST LIKES
  // ============================================================================

  /// POST /api/version/posts/{postId}/like - Like a post
  static String likePost(String postId) {
    assert(postId.isNotEmpty, 'postId cannot be empty');
    return '$_api/posts/$postId/like';
  }

  /// DELETE /api/version/posts/{postId}/like - Unlike a post
  static String unlikePost(String postId) {
    assert(postId.isNotEmpty, 'postId cannot be empty');
    return '$_api/posts/$postId/like';
  }

  /// GET /api/version/posts/{postId}/like/status - Check if user has liked a post
  static String checkLikeStatus(String postId) {
    assert(postId.isNotEmpty, 'postId cannot be empty');
    return '$_api/posts/$postId/like/status';
  }

  /// GET /api/version/posts/{postId}/likes - Get users who liked a post
  static String getPostLikes(String postId) {
    assert(postId.isNotEmpty, 'postId cannot be empty');
    return '$_api/posts/$postId/likes';
  }

  /// GET /api/version/likes/me - Get all posts liked by current user
  static const String getMyLikes = '$_api/likes/me';

  // ============================================================================
  // GENERIC ENTITY LIKES (for future use - comments, videos, etc.)
  // ============================================================================

  /// POST /api/version/{entityType}s/{entityId}/like - Like any entity type
  static String likeEntity(String entityType, String entityId) {
    assert(entityType.isNotEmpty, 'entityType cannot be empty');
    assert(entityId.isNotEmpty, 'entityId cannot be empty');
    return '$_api/${entityType}s/$entityId/like';
  }

  /// DELETE /api/version/{entityType}s/{entityId}/like - Unlike any entity
  static String unlikeEntity(String entityType, String entityId) {
    assert(entityType.isNotEmpty, 'entityType cannot be empty');
    assert(entityId.isNotEmpty, 'entityId cannot be empty');
    return '$_api/${entityType}s/$entityId/like';
  }

  /// GET /api/version/{entityType}s/{entityId}/like/status - Check like status
  static String checkEntityLikeStatus(String entityType, String entityId) {
    assert(entityType.isNotEmpty, 'entityType cannot be empty');
    assert(entityId.isNotEmpty, 'entityId cannot be empty');
    return '$_api/${entityType}s/$entityId/like/status';
  }

  /// GET /api/version/{entityType}s/{entityId}/likes - Get entity likes
  static String getEntityLikes(String entityType, String entityId) {
    assert(entityType.isNotEmpty, 'entityType cannot be empty');
    assert(entityId.isNotEmpty, 'entityId cannot be empty');
    return '$_api/${entityType}s/$entityId/likes';
  }
}
