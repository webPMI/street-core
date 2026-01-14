import '../../../core/helpers/logger.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'user_posts_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing posts from a specific user
class UserPostsCubit extends Cubit<UserPostsState> {
  UserPostsCubit(this._postService) : super(UserPostsInitial());
  final PostService _postService;
  static const int _postsPerPage = 20;

  /// Fetch posts for a specific user
  Future<void> fetchUserPosts(String userId, {bool refresh = false}) async {
    if (isClosed) return;

    // Debug logging to trace empty userId issues
    AppLogger.debug(
      'fetchUserPosts called with userId: "$userId" (length: ${userId.length}, trim: "${userId.trim()}")',
      tag: 'UserPostsCubit',
    );

    // Guard against empty userId (check both empty and whitespace-only)
    if (userId.isEmpty || userId.trim().isEmpty) {
      AppLogger.error('Cannot fetch posts: userId is empty or whitespace', tag: 'UserPostsCubit');
      emit(const UserPostsError('invalid.user.id'));
      return;
    }

    // If refreshing, reset to loading state
    if (refresh) {
      emit(UserPostsLoading());
    } else {
      // If not refreshing and already loaded, don't reload
      final currentState = state;
      if (currentState is UserPostsLoaded && !refresh) {
        return;
      }
      emit(UserPostsLoading());
    }

    try {
      // Fetch posts from service
      final posts = await _postService.getUserPosts(userId);

      if (isClosed) return;

      if (posts.isEmpty) {
        emit(UserPostsEmpty());
      } else {
        emit(
          UserPostsLoaded(posts: posts, hasMore: posts.length >= _postsPerPage),
        );
      }
    } catch (e) {
      AppLogger.error('Error fetching user posts: $e', tag: 'UserPostsCubit');
      if (isClosed) return;
      emit(const UserPostsError('error.fetching.user.posts'));
    }
  }

  /// Load more posts (pagination)
  Future<void> loadMore(String userId) async {
    if (isClosed) return;

    // Guard against empty userId
    if (userId.isEmpty) {
      AppLogger.error('Cannot load more posts: userId is empty', tag: 'UserPostsCubit');
      return;
    }

    final currentState = state;
    if (currentState is! UserPostsLoaded) return;
    if (!currentState.hasMore) return; // No more posts to load

    emit(UserPostsLoadingMore(currentState.posts));

    try {
      final nextPage = currentState.currentPage + 1;
      final newPosts = await _postService.getUserPosts(
        userId,
        page: nextPage,
        limit: _postsPerPage,
      );

      if (isClosed) return;

      // Combine existing posts with new ones
      final allPosts = [...currentState.posts, ...newPosts];

      emit(
        UserPostsLoaded(
          posts: allPosts,
          hasMore: newPosts.length >= _postsPerPage,
          currentPage: nextPage,
        ),
      );
    } catch (e) {
      AppLogger.error('Error loading more posts: $e', tag: 'UserPostsCubit');
      if (isClosed) return;

      // Restore previous state on error
      emit(currentState);
    }
  }

  /// Refresh posts
  Future<void> refresh(String userId) async {
    return fetchUserPosts(userId, refresh: true);
  }

  // --------------------------------------------------
  // POST INTERACTIONS
  // --------------------------------------------------

  /// Toggle like on a post (optimistic update)
  Future<void> toggleLike(String postId) async {
    final currentState = state;
    if (currentState is! UserPostsLoaded) return;

    // Find the post
    final postIndex = currentState.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentState.posts[postIndex];
    final isLiked = post.isLikedByCurrentUser;

    // Optimistic update
    final updatedPost = post.copyWith(
      likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
      isLikedByCurrentUser: !isLiked,
    );

    final updatedPosts = List<PostModel>.from(currentState.posts);
    updatedPosts[postIndex] = updatedPost;

    emit(currentState.copyWith(posts: updatedPosts));

    // Real API call
    try {
      if (isLiked) {
        await _postService.unlikePost(postId);
      } else {
        await _postService.likePost(postId);
      }
    } catch (e) {
      // Revert on error
      emit(currentState);
    }
  }

  /// Toggle save on a post (optimistic update)
  Future<void> toggleSave(String postId) async {
    final currentState = state;
    if (currentState is! UserPostsLoaded) return;

    // Find the post
    final postIndex = currentState.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentState.posts[postIndex];
    final isSaved = post.isSavedByCurrentUser;

    // Optimistic update
    final updatedPost = post.copyWith(isSavedByCurrentUser: !isSaved);

    final List<PostModel> updatedPosts = List.from(currentState.posts);
    updatedPosts[postIndex] = updatedPost;

    emit(currentState.copyWith(posts: updatedPosts));

    // Real API call
    try {
      if (isSaved) {
        await _postService.unsavePost(postId);
      } else {
        await _postService.savePost(postId);
      }
    } catch (e) {
      // Revert on error
      emit(currentState);
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    final currentState = state;
    if (currentState is! UserPostsLoaded) return;

    try {
      await _postService.deletePost(postId);

      // Remove post from list
      final updatedPosts = currentState.posts.where((p) => p.id != postId).toList();

      if (updatedPosts.isEmpty) {
        emit(UserPostsEmpty());
      } else {
        emit(currentState.copyWith(posts: updatedPosts));
      }
    } catch (e) {
      AppLogger.error('Error deleting post: $e', tag: 'UserPostsCubit');
      emit(const UserPostsError('error.deleting.post'));
    }
  }
}
