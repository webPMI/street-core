// lib/features/social/comment/comment_service.dart

import '../../../core/helpers/logger.dart';
import 'comment_model.dart';
import 'comment_repository.dart';

/// Servicio de Comentarios - Lógica de negocio para operaciones de comentarios
/// Siguiendo la arquitectura Monolith-by-Features
class CommentService {
  CommentService(this._repository);

  final CommentRepository _repository;

  /// Añadir un comentario a una publicación
  Future<CommentModel> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    AppLogger.info('Adding comment to post: $postId', tag: 'CommentService');
    AppLogger.debug('Comment text length: ${text.length} chars', tag: 'CommentService');
    AppLogger.debug('Parent comment ID: ${parentCommentId ?? "none"}', tag: 'CommentService');

    // Validate content
    if (text.trim().isEmpty) {
      AppLogger.error('Validation failed: Comment content is empty', tag: 'CommentService');
      throw Exception('Comment content cannot be empty');
    }

    if (text.length > 2000) {
      AppLogger.error('Validation failed: Comment too long (${text.length}/2000)', tag: 'CommentService');
      throw Exception('Comment is too long (max 2000 characters)');
    }

    final commentData = {
      'text': text.trim(),
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    };

    AppLogger.debug('Sending comment data: $commentData', tag: 'CommentService');

    try {
      final response = await _repository.createComment(postId, commentData);

      AppLogger.debug('Response status: ${response.status}', tag: 'CommentService');
      AppLogger.debug('Response statusCode: ${response.statusCode}', tag: 'CommentService');
      AppLogger.debug('Response message: ${response.message}', tag: 'CommentService');
      AppLogger.debug('Response data: ${response.data}', tag: 'CommentService');

      if (response.status == 'success' && response.data != null) {
        AppLogger.info('Comment created successfully: ${response.data!.id}', tag: 'CommentService');
        return response.data!;
      } else {
        AppLogger.error(
          '[CommentService.addComment] Backend returned non-success status',
          tag: 'CommentService',
        );
        AppLogger.debug('[CommentService.addComment] File: comment_service.dart, Line: ~15-54', tag: 'CommentService');
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentService.addComment] Exception creating comment for post: $postId',
        error: e,
        stackTrace: stackTrace,
        tag: 'CommentService',
      );
      AppLogger.debug('[CommentService.addComment] File: comment_service.dart, Line: ~15-54', tag: 'CommentService');
      rethrow;
    }
  }

  /// Obtener comentarios de una publicación
  Future<List<CommentModel>> getComments(String postId) async {
    AppLogger.info(
      'Fetching comments for post: $postId',
      tag: 'CommentService',
    );

    try {
      final response = await _repository.getPostComments(postId);

      AppLogger.debug('Response status: ${response.status}', tag: 'CommentService');
      AppLogger.debug('Response statusCode: ${response.statusCode}', tag: 'CommentService');
      AppLogger.debug('Response message: ${response.message}', tag: 'CommentService');

      if (response.status == 'success') {
        final comments = response.data ?? [];
        AppLogger.info('Fetched ${comments.length} comments', tag: 'CommentService');

        // Log cada comentario para debug
        for (var i = 0; i < comments.length; i++) {
          final c = comments[i];
          final preview = c.text.isEmpty
              ? '(empty)'
              : c.text.length > 30
                  ? '${c.text.substring(0, 30)}...'
                  : c.text;
          AppLogger.debug(
            'Comment $i: id=${c.id}, user=${c.userName}, text="$preview", likes=${c.likesCount}',
            tag: 'CommentService',
          );
        }

        return comments;
      } else {
        AppLogger.error(
          '[CommentService.getComments] Backend returned non-success status',
          tag: 'CommentService',
        );
        AppLogger.debug('[CommentService.getComments] File: comment_service.dart, Line: ~73-113', tag: 'CommentService');
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentService.getComments] Exception fetching comments for post: $postId',
        error: e,
        stackTrace: stackTrace,
        tag: 'CommentService',
      );
      AppLogger.debug('[CommentService.getComments] File: comment_service.dart, Line: ~73-113', tag: 'CommentService');
      rethrow;
    }
  }

  /// Obtener comentarios de una publicación con paginación
  Future<Map<String, dynamic>> getCommentsPaginated(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    AppLogger.info(
      'Fetching paginated comments for post: $postId (page: $page, limit: $limit)',
      tag: 'CommentService',
    );

    try {
      final result = await _repository.getPostCommentsPaginated(
        postId,
        page: page,
        limit: limit,
      );

      final comments = result['items'] as List<CommentModel>;
      final totalItems = result['totalItems'] as int;
      final hasNextPage = result['hasNextPage'] as bool;
      final currentPage = result['currentPage'] as int;

      AppLogger.info(
        'Fetched ${comments.length} comments (page $currentPage, total: $totalItems, hasMore: $hasNextPage)',
        tag: 'CommentService',
      );

      return {
        'items': comments,
        'totalItems': totalItems,
        'hasNextPage': hasNextPage,
        'currentPage': currentPage,
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentService.getCommentsPaginated] Exception fetching paginated comments',
        error: e,
        stackTrace: stackTrace,
        tag: 'CommentService',
      );
      rethrow;
    }
  }

  /// Actualizar un comentario
  Future<CommentModel> updateComment(String commentId, String newText) async {
    AppLogger.info('Updating comment: $commentId', tag: 'CommentService');

    // Validate content
    if (newText.trim().isEmpty) {
      throw Exception('Comment content cannot be empty');
    }

    if (newText.length > 2000) {
      throw Exception('Comment is too long (max 2000 characters)');
    }

    final commentData = {'text': newText.trim()};
    final response = await _repository.updateComment(commentId, commentData);

    if (response.status == 'success' && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message);
    }
  }

  /// Eliminar un comentario
  Future<void> deleteComment(String commentId) async {
    AppLogger.info('Deleting comment: $commentId', tag: 'CommentService');

    final response = await _repository.deleteComment(commentId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }

  /// Dar me gusta a un comentario
  Future<void> likeComment(String commentId) async {
    final response = await _repository.likeComment(commentId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }

  /// Quitar me gusta a un comentario
  Future<void> unlikeComment(String commentId) async {
    final response = await _repository.unlikeComment(commentId);

    if (response.status != 'success') {
      throw Exception(response.message);
    }
  }
}
