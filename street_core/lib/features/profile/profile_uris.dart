import 'package:street_core/config/env.dart';

class ProfileUris {
  // ============================================================================
  // VERSION CONTROL - Change here to migrate all endpoints
  static const String _apiVersion = Env.apiVersion;

  /// API prefix with version
  static const String api = '/api/$_apiVersion';
  // ============================================================================
  // POSTS (Social Media)
  // ============================================================================

  /// GET /api/version/users/{userId}/posts (Obtener posts de un usuario)
  static String getUserPosts(String userId) {
    assert(userId.isNotEmpty, 'userId cannot be empty');
    return '$api/users/$userId/posts';
  }

  /// POST /api/version/posts (Crear un nuevo post)
  static const String createPost = '$api/posts';

  /// GET /api/version/posts/{id} (Obtener detalles de un post)
  static String getPostDetail(String id) {
    return '$api/posts/$id';
  }

  /// PUT /api/version/posts/{id} (Actualizar un post)
  static String updatePost(String id) {
    return '$api/posts/$id';
  }

  /// DELETE /api/version/posts/{id} (Eliminar un post)
  static String deletePost(String id) {
    return '$api/posts/$id';
  }

  /// POST /api/version/posts/{id}/like (Dar like a un post)
  static String likePost(String id) {
    return '$api/posts/$id/like';
  }

  /// DELETE /api/version/posts/{id}/like (Quitar like de un post)
  static String unlikePost(String id) {
    return '$api/posts/$id/like';
  }

  /// GET /api/version/posts (Obtener feed de posts - usar endpoint correcto)
  static const String postsFeed = '$api/posts';

  /// POST /api/posts/{id}/save (Guardar un post)
  static String savePost(String id) {
    return '$api/posts/$id/save';
  }

  /// DELETE /api/posts/{id}/save (Dejar de guardar un post)
  static String unsavePost(String id) {
    return '$api/posts/$id/save';
  }

  /// GET /api/version/posts/saved (Obtener posts guardados)
  static const String getSavedPosts = '$api/posts/saved';

  /// GET /api/version/posts/{id}/save/status (Verificar si el post está guardado)
  static String getSaveStatus(String postId) => '$api/posts/$postId/save/status';

  // ============================================================================
  // COMMENTS (Social Media)
  // ============================================================================

  /// GET /api/version/posts/{postId}/comments (Obtener comentarios de un post)
  static String getPostComments(String postId) {
    return '$api/posts/$postId/comments';
  }

  /// POST /api/version/posts/{postId}/comments (Crear un comentario)
  static String createComment(String postId) {
    return '$api/posts/$postId/comments';
  }

  /// PUT /api/version/comments/{commentId} (Actualizar un comentario)
  static String updateComment(String commentId) => '$api/comments/$commentId';

  /// DELETE /api/version/comments/{commentId} (Eliminar un comentario)
  static String deleteComment(String commentId) => '$api/comments/$commentId';

  /// GET /api/version/comments/{commentId}/replies (Obtener respuestas de un comentario)
  static String getCommentReplies(String commentId) =>
      '$api/comments/$commentId/replies';

  // ============================================================================
  // LIKES
  // ============================================================================

  /// GET /api/version/posts/{id}/likes (Obtener usuarios que dieron like)
  static String getPostLikes(String postId) => '$api/posts/$postId/likes';

  /// GET /api/version/posts/{id}/like/status (Verificar si el usuario dio like)
  static String getLikeStatus(String postId) => '$api/posts/$postId/like/status';

  /// GET /api/version/likes/me (Obtener posts que el usuario le dio like)
  static const String getMyLikes = '$api/likes/me';

  // ============================================================================
  // COMMENT LIKES
  // ============================================================================

  /// POST /api/version/comments/{commentId}/like (Dar like a un comentario)
  static String likeComment(String commentId) =>
      '$api/comments/$commentId/like';

  /// DELETE /api/version/comments/{commentId}/like (Quitar like de un comentario)
  static String unlikeComment(String commentId) =>
      '$api/comments/$commentId/like';

  /// GET /api/version/comments/{commentId}/likes (Obtener usuarios que dieron like)
  static String getCommentLikes(String commentId) =>
      '$api/comments/$commentId/likes';

  /// GET /api/version/comments/{commentId}/like/status (Verificar si el usuario dio like)
  static String getCommentLikeStatus(String commentId) =>
      '$api/comments/$commentId/like/status';

  // ============================================================================
  // USER SEARCH
  // ============================================================================

  /// GET /api/version/users/search (Search users by query)
  static String searchUsers({String? query, int limit = 10}) =>
      '$api/users/search?q=${Uri.encodeComponent(query ?? "")}&limit=$limit';
}
