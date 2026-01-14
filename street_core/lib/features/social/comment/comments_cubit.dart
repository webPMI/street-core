// lib/features/social/comment/comments_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/helpers/logger.dart';
import 'comment_model.dart';
import 'comment_service.dart';
import 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit(this._commentService) : super(CommentsInitial());
  final CommentService _commentService;

  // --------------------------------------------------
  // OPERACIONES DE LECTURA
  // --------------------------------------------------

  /// Cargar comentarios de un post con paginación
  Future<void> fetchComments(String postId, {int limit = 20}) async {
    try {
      AppLogger.debug('[CommentsCubit] Fetching comments for post: $postId', tag: 'Comments');
      emit(CommentsLoading());

      final result = await _commentService.getCommentsPaginated(
        postId,
        page: 1,
        limit: limit,
      );

      final comments = result['items'] as List<CommentModel>;
      final totalItems = result['totalItems'] as int;
      final hasNextPage = result['hasNextPage'] as bool;

      AppLogger.debug(
        '[CommentsCubit] Loaded ${comments.length} comments (total: $totalItems, hasMore: $hasNextPage)',
        tag: 'Comments',
      );

      emit(CommentsLoaded(
        comments,
        currentPage: 1,
        hasMoreComments: hasNextPage,
        totalComments: totalItems,
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentsCubit.fetchComments] Error fetching comments for post: $postId',
        error: e,
        stackTrace: stackTrace,
        tag: 'Comments',
      );
      AppLogger.debug('[CommentsCubit.fetchComments] File: comments_cubit.dart, Line: ~18-31', tag: 'Comments');
      emit(CommentsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Cargar más comentarios (siguiente página)
  Future<void> loadMoreComments(String postId) async {
    final currentState = state;
    if (currentState is! CommentsLoaded) {
      AppLogger.warning('[CommentsCubit] Cannot load more - state is not CommentsLoaded', tag: 'Comments');
      return;
    }

    if (!currentState.hasMoreComments || currentState.isLoadingMore) {
      AppLogger.debug('[CommentsCubit] No more comments to load or already loading', tag: 'Comments');
      return;
    }

    try {
      AppLogger.debug('[CommentsCubit] Loading more comments, page ${currentState.currentPage + 1}', tag: 'Comments');
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.currentPage + 1;
      final result = await _commentService.getCommentsPaginated(
        postId,
        page: nextPage,
        limit: 20,
      );

      final newComments = result['items'] as List<CommentModel>;
      final totalItems = result['totalItems'] as int;
      final hasNextPage = result['hasNextPage'] as bool;

      AppLogger.debug(
        '[CommentsCubit] Loaded ${newComments.length} more comments (hasMore: $hasNextPage)',
        tag: 'Comments',
      );

      final allComments = [...currentState.comments, ...newComments];

      emit(CommentsLoaded(
        allComments,
        currentPage: nextPage,
        hasMoreComments: hasNextPage,
        totalComments: totalItems,
        isLoadingMore: false,
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentsCubit.loadMoreComments] Error loading more comments',
        error: e,
        stackTrace: stackTrace,
        tag: 'Comments',
      );
      emit(currentState.copyWith(isLoadingMore: false));
      emit(CommentsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Refrescar comentarios
  Future<void> refreshComments(String postId) async {
    await fetchComments(postId);
  }

  // --------------------------------------------------
  // OPERACIONES DE ESCRITURA
  // --------------------------------------------------

  /// Agregar un comentario
  Future<void> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    final currentState = state;
    AppLogger.debug('[CommentsCubit] Current state: ${currentState.runtimeType}', tag: 'Comments');

    if (currentState is! CommentsLoaded) {
      AppLogger.warning('[CommentsCubit] Cannot add comment - state is not CommentsLoaded', tag: 'Comments');
      return;
    }

    try {
      AppLogger.info('[CommentsCubit] Adding comment to post: $postId', tag: 'Comments');
      AppLogger.debug('[CommentsCubit] Comment text: "$text"', tag: 'Comments');
      AppLogger.debug('[CommentsCubit] Parent comment: ${parentCommentId ?? "none (root comment)"}', tag: 'Comments');

      emit(currentState.copyWith(isSubmitting: true));

      final newComment = await _commentService.addComment(
        postId: postId,
        text: text,
        parentCommentId: parentCommentId,
      );

      AppLogger.debug('[CommentsCubit] Comment created successfully with ID: ${newComment.id}', tag: 'Comments');

      // Agregar el nuevo comentario a la lista
      final updatedComments = [newComment, ...currentState.comments];
      AppLogger.debug('[CommentsCubit] Updated comments count: ${updatedComments.length}', tag: 'Comments');

      emit(CommentsLoaded(
        updatedComments,
        currentPage: currentState.currentPage,
        hasMoreComments: currentState.hasMoreComments,
        totalComments: currentState.totalComments + 1, // Increment total
      ));
      emit(const CommentsActionSuccess('comment_added_successfully'));
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentsCubit.addComment] Failed to add comment to post: $postId',
        error: e,
        stackTrace: stackTrace,
        tag: 'Comments',
      );
      AppLogger.debug('[CommentsCubit.addComment] File: comments_cubit.dart, Line: ~57-82', tag: 'Comments');
      AppLogger.debug('[CommentsCubit.addComment] Comment text was: "$text"', tag: 'Comments');
      emit(currentState.copyWith(isSubmitting: false));
      emit(CommentsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Eliminar un comentario
  Future<void> deleteComment(String commentId) async {
    final currentState = state;
    if (currentState is! CommentsLoaded) {
      AppLogger.warning('[CommentsCubit] Cannot delete comment - state is not CommentsLoaded', tag: 'Comments');
      return;
    }

    try {
      AppLogger.info('[CommentsCubit] Deleting comment: $commentId', tag: 'Comments');
      await _commentService.deleteComment(commentId);

      // Remover el comentario de la lista
      final updatedComments = currentState.comments
          .where((c) => c.id != commentId)
          .toList();
      AppLogger.debug('[CommentsCubit] Comment deleted. Remaining: ${updatedComments.length}', tag: 'Comments');

      emit(CommentsLoaded(
        updatedComments,
        currentPage: currentState.currentPage,
        hasMoreComments: currentState.hasMoreComments,
        totalComments: currentState.totalComments - 1, // Decrement total
      ));
      emit(const CommentsActionSuccess('comment_deleted_successfully'));
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentsCubit.deleteComment] Failed to delete comment: $commentId',
        error: e,
        stackTrace: stackTrace,
        tag: 'Comments',
      );
      AppLogger.debug('[CommentsCubit.deleteComment] File: comments_cubit.dart, Line: ~97-121', tag: 'Comments');
      emit(CommentsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Editar un comentario
  Future<void> updateComment(String commentId, String newText) async {
    final currentState = state;
    if (currentState is! CommentsLoaded) return;

    try {
      final updatedComment = await _commentService.updateComment(
        commentId,
        newText,
      );

      // Actualizar el comentario en la lista
      final commentIndex = currentState.comments.indexWhere(
        (c) => c.id == commentId,
      );
      if (commentIndex != -1) {
        final updatedComments = List<CommentModel>.from(currentState.comments);
        updatedComments[commentIndex] = updatedComment;
        emit(CommentsLoaded(
          updatedComments,
          currentPage: currentState.currentPage,
          hasMoreComments: currentState.hasMoreComments,
          totalComments: currentState.totalComments,
        ));
        emit(const CommentsActionSuccess('comment_updated_successfully'));
      }
    } catch (e) {
      emit(CommentsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // --------------------------------------------------
  // OPERACIONES DE LIKE
  // --------------------------------------------------

  /// Toggle like en un comentario (optimistic update)
  Future<void> toggleLike(String commentId) async {
    final currentState = state;
    if (currentState is! CommentsLoaded) {
      AppLogger.warning('[CommentsCubit] Cannot toggle like - state is not CommentsLoaded', tag: 'Comments');
      return;
    }

    // Encontrar el comentario
    final commentIndex = currentState.comments.indexWhere(
      (c) => c.id == commentId,
    );
    if (commentIndex == -1) {
      AppLogger.warning('[CommentsCubit] Comment not found for like toggle: $commentId', tag: 'Comments');
      return;
    }

    final comment = currentState.comments[commentIndex];
    final isLiked = comment.isLikedByCurrentUser;

    AppLogger.debug('[CommentsCubit] Toggling like on comment $commentId (currently liked: $isLiked)', tag: 'Comments');

    // Actualización optimista
    final updatedComment = comment.copyWith(
      isLikedByCurrentUser: !isLiked,
      likesCount: isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
    );

    final updatedComments = List<CommentModel>.from(currentState.comments);
    updatedComments[commentIndex] = updatedComment;

    emit(CommentsLoaded(
      updatedComments,
      currentPage: currentState.currentPage,
      hasMoreComments: currentState.hasMoreComments,
      totalComments: currentState.totalComments,
    ));

    // Llamada real al backend
    try {
      if (isLiked) {
        await _commentService.unlikeComment(commentId);
        AppLogger.debug('[CommentsCubit] Successfully unliked comment', tag: 'Comments');
      } else {
        await _commentService.likeComment(commentId);
        AppLogger.debug('[CommentsCubit] Successfully liked comment', tag: 'Comments');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[CommentsCubit.toggleLike] Failed to toggle like on comment: $commentId',
        error: e,
        stackTrace: stackTrace,
        tag: 'Comments',
      );
      AppLogger.debug('[CommentsCubit.toggleLike] File: comments_cubit.dart, Line: ~149-204', tag: 'Comments');
      AppLogger.debug('[CommentsCubit.toggleLike] Action was: ${isLiked ? "unlike" : "like"}', tag: 'Comments');
      // Revertir en caso de error
      emit(currentState);
    }
  }
}
