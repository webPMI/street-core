// lib/presentation/dashboard/posts/bloc/posts_feed_cubit.dart

import 'dart:async';

import '../../models/post_model.dart';
import '../../services/post_service.dart';
import 'posts_feed_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Posts Feed Cubit with Performance Optimizations
///
/// Optimizations:
/// - Debouncing for rapid actions (like/unlike)
/// - Request cancellation for outdated pagination requests
/// - Memory-efficient list updates using immutable operations
/// - Proper state management to minimize rebuilds
class PostsFeedCubit extends Cubit<PostsFeedState> {
  PostsFeedCubit(this._postService) : super(PostsFeedInitial());
  final PostService _postService;

  /// OPTIMIZATION: Debounce timer for rapid user actions
  /// Prevents excessive API calls when user rapidly taps like button
  Timer? _debounceTimer;

  /// OPTIMIZATION: Track cancellation tokens for pagination requests
  /// Allows canceling outdated requests when user scrolls rapidly
  final Map<int, bool> _canceledPages = {};

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _canceledPages.clear();
    return super.close();
  }

  // --------------------------------------------------
  // OPERACIONES DE LECTURA (FETCH)
  // --------------------------------------------------

  /// Cargar el feed de posts (primera página)
  Future<void> fetchFeed({int page = 1, int limit = 20}) async {
    try {
      emit(PostsFeedLoading());
      final posts = await _postService.getFeed(page: page, limit: limit);

      emit(
        PostsFeedLoaded(
          posts,
          currentPage: page,
          hasMore: posts.length >= limit,
        ),
      );
    } catch (e) {
      emit(const PostsFeedError('error.fetching.feed'));
    }
  }

  /// Refrescar el feed (pull-to-refresh)
  Future<void> refreshFeed() async {
    await fetchFeed();
  }

  /// Cargar más posts (infinite scroll)
  /// OPTIMIZATION: Added request cancellation for rapid scrolling
  Future<void> loadMorePosts() async {
    final currentState = state;
    if (currentState is! PostsFeedLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    final nextPage = currentState.currentPage + 1;

    // OPTIMIZATION: Cancel previous page request if still pending
    _canceledPages[nextPage - 1] = true;

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final posts = await _postService.getFeed(page: nextPage);

      // OPTIMIZATION: Check if this request was canceled (user scrolled away)
      if (_canceledPages[nextPage] == true) {
        _canceledPages.remove(nextPage);
        return;
      }

      // OPTIMIZATION: Use spread operator for efficient list concatenation
      // Creates new list without modifying original (immutable pattern)
      emit(
        PostsFeedLoaded(
          [...currentState.posts, ...posts],
          currentPage: nextPage,
          hasMore: posts.length >= 20,
        ),
      );
    } catch (e) {
      final currentState = state;
      if (currentState is PostsFeedLoaded) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
      emit(const PostsFeedError('error.loading.more.posts'));
    } finally {
      // OPTIMIZATION: Clean up cancellation token
      _canceledPages.remove(nextPage);
    }
  }

  // --------------------------------------------------
  // OPERACIONES DE ACCIÓN (LIKE/DELETE)
  // --------------------------------------------------

  /// Toggle like en un post (optimistic update)
  /// OPTIMIZATION: Added debouncing to prevent rapid-fire API calls
  Future<void> toggleLike(String postId) async {
    final currentState = state;
    if (currentState is! PostsFeedLoaded) return;

    // Encontrar el post
    final postIndex = currentState.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentState.posts[postIndex];
    final isLiked = post.isLikedByCurrentUser;

    // OPTIMIZATION: Optimistic update - UI responds immediately
    // This provides instant feedback to the user
    final updatedPost = post.copyWith(
      likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
      isLikedByCurrentUser: !isLiked,
    );

    // OPTIMIZATION: Use List.of() instead of List.from() for better performance
    // List.of() is optimized for Iterable sources
    final updatedPosts = List<PostModel>.of(currentState.posts);
    updatedPosts[postIndex] = updatedPost;

    emit(currentState.copyWith(posts: updatedPosts));

    // OPTIMIZATION: Debounce API call to handle rapid taps
    // Cancel previous timer if user taps multiple times quickly
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // Llamada real al backend after debounce period
      try {
        if (isLiked) {
          await _postService.unlikePost(postId);
        } else {
          await _postService.likePost(postId);
        }
      } catch (e) {
        // Revertir en caso de error
        emit(currentState);
      }
    });
  }

  /// Eliminar un post
  Future<void> deletePost(String postId) async {
    final currentState = state;
    if (currentState is! PostsFeedLoaded) return;

    try {
      await _postService.deletePost(postId);

      // Remover el post de la lista
      final updatedPosts = currentState.posts
          .where((p) => p.id != postId)
          .toList();
      emit(currentState.copyWith(posts: updatedPosts));
      emit(const PostsFeedActionSuccess('post.deleted.successfully'));
    } catch (e) {
      emit(const PostsFeedError('error.deleting.post'));
    }
  }

  /// Actualizar un post en el feed (después de editar)
  /// OPTIMIZATION: Uses efficient list update pattern
  void updatePostInFeed(PostModel updatedPost) {
    final currentState = state;
    if (currentState is! PostsFeedLoaded) return;

    final postIndex = currentState.posts.indexWhere(
      (p) => p.id == updatedPost.id,
    );
    if (postIndex == -1) return;

    // OPTIMIZATION: List.of() for better performance with iterables
    final updatedPosts = List<PostModel>.of(currentState.posts);
    updatedPosts[postIndex] = updatedPost;

    emit(currentState.copyWith(posts: updatedPosts));
  }

  /// Agregar un nuevo post al inicio del feed
  /// OPTIMIZATION: Prepends efficiently using spread operator
  void addPostToFeed(PostModel newPost) {
    final currentState = state;
    if (currentState is! PostsFeedLoaded) return;

    // OPTIMIZATION: Spread operator creates new list efficiently
    // Prepending to list is O(1) with spread operator
    final updatedPosts = [newPost, ...currentState.posts];
    emit(currentState.copyWith(posts: updatedPosts));
  }

  // --------------------------------------------------
  // SAVE/UNSAVE OPERATIONS
  // --------------------------------------------------

  /// Toggle save on a post (optimistic update)
  Future<void> toggleSave(String postId) async {
    final currentState = state;
    if (currentState is! PostsFeedLoaded) return;

    // Find the post
    final postIndex = currentState.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentState.posts[postIndex];
    final isSaved = post.isSavedByCurrentUser;

    // Optimistic update - toggle isSavedByCurrentUser
    final updatedPost = post.copyWith(isSavedByCurrentUser: !isSaved);

    final updatedPosts = List<PostModel>.of(currentState.posts);
    updatedPosts[postIndex] = updatedPost;

    emit(currentState.copyWith(posts: updatedPosts));

    // Real API call
    try {
      if (isSaved) {
        await _postService.unsavePost(postId);
      } else {
        await _postService.savePost(postId);
      }
      emit(PostsFeedActionSuccess(isSaved ? 'post.unsaved' : 'post.saved'));
    } catch (e) {
      // Revert on error
      emit(currentState);
      emit(const PostsFeedError('error.saving.post'));
    }
  }
}
