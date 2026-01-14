import 'package:street_core/config/env.dart';

/// URIs for comment-related API endpoints
/// This module is entity-agnostic and can handle comments on any type of entity
/// (posts, competitions, events, etc.)
class CommentUris {
  // ============================================================================
  // VERSION CONTROL - Change here to migrate all endpoints
  static const String _apiVersion = Env.apiVersion;

  /// API prefix with version
  static const String _api = '/api/$_apiVersion';

  // ============================================================================
  // GENERIC ENTITY COMMENTS
  // ============================================================================

  /// Get comments for any entity type
  /// Example: getEntityComments('post', '123') → '/api/v2/posts/123/comments'
  static String getEntityComments(String entityType, String entityId) {
    assert(entityType.isNotEmpty, 'entityType cannot be empty');
    assert(entityId.isNotEmpty, 'entityId cannot be empty');
    return '$_api/${entityType}s/$entityId/comments';
  }

  /// Create comment for any entity type
  static String createEntityComment(String entityType, String entityId) {
    assert(entityType.isNotEmpty, 'entityType cannot be empty');
    assert(entityId.isNotEmpty, 'entityId cannot be empty');
    return '$_api/${entityType}s/$entityId/comments';
  }

  // ============================================================================
  // LEGACY POST COMMENTS (backward compatibility)
  // ============================================================================

  /// GET /api/v2/posts/{postId}/comments - Get comments for a post
  static String getPostComments(String postId) {
    assert(postId.isNotEmpty, 'postId cannot be empty');
    return '$_api/posts/$postId/comments';
  }

  /// POST /api/v2/posts/{postId}/comments - Create comment on a post
  static String createComment(String postId) {
    assert(postId.isNotEmpty, 'postId cannot be empty');
    return '$_api/posts/$postId/comments';
  }

  // ============================================================================
  // COMMENT OPERATIONS (entity-agnostic)
  // ============================================================================

  /// GET /api/v2/comments/{commentId} - Get a specific comment
  static String getCommentById(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId';
  }

  /// PUT /api/v2/comments/{commentId} - Update a comment
  static String updateComment(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId';
  }

  /// DELETE /api/v2/comments/{commentId} - Delete a comment
  static String deleteComment(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId';
  }

  /// GET /api/v2/comments/{commentId}/replies - Get replies to a comment
  static String getCommentReplies(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId/replies';
  }

  // ============================================================================
  // COMMENT LIKES
  // ============================================================================

  /// POST /api/v2/comments/{commentId}/like - Like a comment
  static String likeComment(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId/like';
  }

  /// DELETE /api/v2/comments/{commentId}/like - Unlike a comment
  static String unlikeComment(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId/like';
  }

  /// GET /api/v2/comments/{commentId}/likes - Get users who liked a comment
  static String getCommentLikes(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId/likes';
  }

  /// GET /api/v2/comments/{commentId}/like/status - Check if user liked a comment
  static String getCommentLikeStatus(String commentId) {
    assert(commentId.isNotEmpty, 'commentId cannot be empty');
    return '$_api/comments/$commentId/like/status';
  }
}
