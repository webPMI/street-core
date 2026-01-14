// lib/presentation/dashboard/posts/bloc/posts_feed_state.dart

import 'package:equatable/equatable.dart';

import '../../models/post_model.dart';

/// Clase base para todos los estados del feed de posts
abstract class PostsFeedState extends Equatable {
  const PostsFeedState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cualquier operación
class PostsFeedInitial extends PostsFeedState {}

/// Estado de carga inicial
class PostsFeedLoading extends PostsFeedState {}

/// Estado de éxito al cargar el feed de posts
class PostsFeedLoaded extends PostsFeedState {
  const PostsFeedLoaded(
    this.posts, {
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });
  final List<PostModel> posts;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  PostsFeedLoaded copyWith({
    List<PostModel>? posts,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PostsFeedLoaded(
      posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [posts, currentPage, hasMore, isLoadingMore];
}

/// Estado de error durante cualquier operación
class PostsFeedError extends PostsFeedState {
  const PostsFeedError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

/// Estado de éxito después de una acción (like, delete)
class PostsFeedActionSuccess extends PostsFeedState {
  const PostsFeedActionSuccess(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
