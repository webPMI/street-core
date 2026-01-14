// lib/presentation/dashboard/posts/bloc/post_detail_cubit.dart

import '../../models/post_model.dart';
import '../../services/post_service.dart';
import 'post_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._service) : super(PostDetailInitial());
  final PostService _service;

  // --------------------------------------------------
  // OPERACIONES DE LECTURA
  // --------------------------------------------------

  /// Cargar un post por ID
  Future<void> fetchPost(String postId) async {
    try {
      emit(PostDetailLoading());
      final post = await _service.getPostById(postId);
      emit(PostDetailLoaded(post));
    } catch (e) {
      emit(const PostDetailError('error.fetching.post'));
    }
  }

  // --------------------------------------------------
  // OPERACIONES DE ACCIÓN
  // --------------------------------------------------

  /// Toggle like en el post (optimistic update)
  Future<void> toggleLike() async {
    final currentState = state;
    if (currentState is! PostDetailLoaded) return;

    final post = currentState.post;
    final isLiked = post.isLikedByCurrentUser;

    // Actualización optimista
    final updatedPost = post.copyWith(
      likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
      isLikedByCurrentUser: !isLiked,
    );

    emit(PostDetailLoaded(updatedPost));

    // Llamada real al backend
    try {
      if (isLiked) {
        await _service.unlikePost(post.id);
      } else {
        await _service.likePost(post.id);
      }
    } catch (e) {
      // Revertir en caso de error
      emit(PostDetailLoaded(post));
    }
  }

  /// Eliminar el post
  Future<void> deletePost() async {
    final currentState = state;
    if (currentState is! PostDetailLoaded) return;

    try {
      await _service.deletePost(currentState.post.id);
      emit(const PostDetailActionSuccess('post.deleted.successfully'));
    } catch (e) {
      emit(const PostDetailError('error.deleting.post'));
    }
  }

  /// Actualizar el post actual (después de editar o comentar)
  void updatePost(PostModel updatedPost) {
    emit(PostDetailLoaded(updatedPost));
  }

  /// Incrementar contador de comentarios
  void incrementCommentsCount() {
    final currentState = state;
    if (currentState is! PostDetailLoaded) return;

    final updatedPost = currentState.post.copyWith(
      commentsCount: currentState.post.commentsCount + 1,
    );
    emit(PostDetailLoaded(updatedPost));
  }

  /// Decrementar contador de comentarios
  void decrementCommentsCount() {
    final currentState = state;
    if (currentState is! PostDetailLoaded) return;

    final updatedPost = currentState.post.copyWith(
      commentsCount: currentState.post.commentsCount - 1,
    );
    emit(PostDetailLoaded(updatedPost));
  }
}
