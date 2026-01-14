import 'package:equatable/equatable.dart';

import '../models/post_model.dart';

// Base state for user posts
abstract class UserPostsState extends Equatable {
  const UserPostsState();

  @override
  List<Object?> get props => [];
}

// Initial state
class UserPostsInitial extends UserPostsState {}

// Loading user posts
class UserPostsLoading extends UserPostsState {}

// User posts loaded successfully
class UserPostsLoaded extends UserPostsState {
  const UserPostsLoaded({
    required this.posts,
    this.hasMore = true,
    this.currentPage = 1,
  });
  final List<PostModel> posts;
  final bool hasMore;
  final int currentPage;

  @override
  List<Object?> get props => [posts, hasMore, currentPage];

  UserPostsLoaded copyWith({
    List<PostModel>? posts,
    bool? hasMore,
    int? currentPage,
  }) {
    return UserPostsLoaded(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Loading more posts (pagination)
class UserPostsLoadingMore extends UserPostsState {
  const UserPostsLoadingMore(this.currentPosts);
  final List<PostModel> currentPosts;

  @override
  List<Object?> get props => [currentPosts];
}

// Error loading user posts
class UserPostsError extends UserPostsState {
  // i18n key

  const UserPostsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// Empty state (user has no posts)
class UserPostsEmpty extends UserPostsState {}
