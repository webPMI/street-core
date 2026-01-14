// lib/features/social/comment/comment_repository.dart

import '../../../core/crud/base_repository.dart';
import '../../../core/services/api_response.dart';
import 'comment_model.dart';
import 'comment_uris.dart';

/// Repositorio de Comentarios - Llamadas API para gestión de comentarios
class CommentRepository extends BaseRepository {
  CommentRepository(super.apiService);

  /// Crear un nuevo comentario en una publicación
  Future<ApiResponse<Comment>> createComment(
    String postId,
    Map<String, dynamic> data,
  ) async {
    return executeSafely<ApiResponse<Comment>>(
      operation: () async {
        final response = await apiService.post(
          CommentUris.createComment(postId),
          data: data,
        );
        return ApiResponse<Comment>.fromJson(
          response.toJson(),
          (json) => Comment.fromJson(json as Map<String, dynamic>),
        );
      },
      errorMessage: 'Error creating comment',
      enableRetry: false,
    );
  }

  /// Obtener comentarios de una publicación
  Future<ApiResponse<List<Comment>>> getPostComments(String postId) async {
    return executeSafely<ApiResponse<List<Comment>>>(
      operation: () async {
        final response = await apiService.get(
          CommentUris.getPostComments(postId),
        );
        return ApiResponse<List<Comment>>.fromJson(response.toJson(), (json) {
          final list = json as List<dynamic>;
          return list
              .map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      },
      errorMessage: 'Error fetching comments',
    );
  }

  /// Obtener comentarios de una publicación con paginación
  Future<Map<String, dynamic>> getPostCommentsPaginated(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    return executeSafely<Map<String, dynamic>>(
      operation: () async {
        final response = await apiService.get(
          CommentUris.getPostComments(postId),
          queryParameters: {
            'page': page.toString(),
            'limit': limit.toString(),
          },
        );

        // Backend returns: { status, message, data: { data, pagination } }
        // La estructura viene de pagination.CreateResponse en Go
        if (response.status == 'success' && response.data != null) {
          final responseData = response.data as Map<String, dynamic>;

          // Handle null data field gracefully
          final dataList = responseData['data'];
          final items = (dataList is List)
              ? dataList
                  .map((e) => Comment.fromJson(e as Map<String, dynamic>))
                  .toList()
              : <Comment>[];

          // Handle null pagination with fallback defaults
          final paginationData = responseData['pagination'];
          final pagination = (paginationData is Map<String, dynamic>)
              ? paginationData
              : {
                  'currentPage': 1,
                  'totalPages': 1,
                  'totalItems': 0,
                  'hasNext': false,
                  'hasPrevious': false,
                };

          return {
            'items': items,
            'currentPage': pagination['currentPage'] as int? ?? 1,
            'totalPages': pagination['totalPages'] as int? ?? 1,
            'totalItems': pagination['totalItems'] as int? ?? 0,
            'hasNextPage': pagination['hasNext'] as bool? ?? false,
            'hasPreviousPage': pagination['hasPrevious'] as bool? ?? false,
          };
        }

        throw Exception('Invalid response format');
      },
      errorMessage: 'Error fetching paginated comments',
    );
  }

  /// Obtener comentario único por ID
  Future<ApiResponse<Comment>> getCommentById(String commentId) async {
    return executeSafely<ApiResponse<Comment>>(
      operation: () async {
        final response = await apiService.get('/comments/$commentId');
        return ApiResponse<Comment>.fromJson(
          response.toJson(),
          (json) => Comment.fromJson(json as Map<String, dynamic>),
        );
      },
      errorMessage: 'Error fetching comment',
    );
  }

  /// Actualizar comentario
  Future<ApiResponse<Comment>> updateComment(
    String commentId,
    Map<String, dynamic> data,
  ) async {
    return executeSafely<ApiResponse<Comment>>(
      operation: () async {
        final response = await apiService.put(
          CommentUris.updateComment(commentId),
          data: data,
        );
        return ApiResponse<Comment>.fromJson(
          response.toJson(),
          (json) => Comment.fromJson(json as Map<String, dynamic>),
        );
      },
      errorMessage: 'Error updating comment',
    );
  }

  /// Eliminar comentario
  Future<ApiResponse<void>> deleteComment(String commentId) async {
    return executeSafely<ApiResponse<void>>(
      operation: () async {
        final response =
            await apiService.delete(CommentUris.deleteComment(commentId));
        return ApiResponse<void>(
          status: response.status,
          message: response.message,
          statusCode: response.statusCode,
        );
      },
      errorMessage: 'Error deleting comment',
    );
  }

  /// Obtener respuestas a un comentario
  Future<List<Comment>> getReplies(String commentId) async {
    return fetchList<Comment>(
      endpoint: CommentUris.getCommentReplies(commentId),
      fromJson: Comment.fromJson,
      errorMessage: 'Error fetching replies',
    );
  }

  /// Dar me gusta a un comentario
  Future<ApiResponse<void>> likeComment(String commentId) async {
    return executeSafely<ApiResponse<void>>(
      operation: () async {
        final response =
            await apiService.post(CommentUris.likeComment(commentId));
        return ApiResponse<void>(
          status: response.status,
          message: response.message,
          statusCode: response.statusCode,
        );
      },
      errorMessage: 'Error liking comment',
    );
  }

  /// Quitar me gusta a un comentario
  Future<ApiResponse<void>> unlikeComment(String commentId) async {
    return executeSafely<ApiResponse<void>>(
      operation: () async {
        final response =
            await apiService.delete(CommentUris.unlikeComment(commentId));
        return ApiResponse<void>(
          status: response.status,
          message: response.message,
          statusCode: response.statusCode,
        );
      },
      errorMessage: 'Error unliking comment',
    );
  }

  /// Verificar si el usuario dio like a un comentario
  Future<bool> isCommentLiked(String commentId) async {
    return executeSafely<bool>(
      operation: () async {
        final response =
            await apiService.get(CommentUris.getCommentLikeStatus(commentId));

        if (response.status == 'success' && response.data != null) {
          return response.data!['isLiked'] as bool? ?? false;
        }

        return false;
      },
      errorMessage: 'Error checking comment like status',
    );
  }

  /// Alternar me gusta en comentario
  Future<void> toggleLike(String commentId, bool isLiked) async {
    if (isLiked) {
      await unlikeComment(commentId);
    } else {
      await likeComment(commentId);
    }
  }
}
