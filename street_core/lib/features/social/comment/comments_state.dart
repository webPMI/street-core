// lib/features/social/comment/comments_state.dart

import 'package:equatable/equatable.dart';
import 'comment_model.dart';

/// Clase base para todos los estados de comentarios
abstract class CommentsState extends Equatable {
  const CommentsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CommentsInitial extends CommentsState {}

/// Estado de carga inicial
class CommentsLoading extends CommentsState {}

/// Estado cargado con comentarios (con soporte de paginación)
class CommentsLoaded extends CommentsState {
  const CommentsLoaded(
    this.comments, {
    this.isSubmitting = false,
    this.isLoadingMore = false,
    this.hasMoreComments = true,
    this.currentPage = 1,
    this.totalComments = 0,
  });

  final List<CommentModel> comments;
  final bool isSubmitting; // Indica si se está enviando un comentario
  final bool isLoadingMore; // Indica si se están cargando más comentarios
  final bool hasMoreComments; // Indica si hay más comentarios disponibles
  final int currentPage; // Página actual
  final int totalComments; // Total de comentarios disponibles

  CommentsLoaded copyWith({
    List<CommentModel>? comments,
    bool? isSubmitting,
    bool? isLoadingMore,
    bool? hasMoreComments,
    int? currentPage,
    int? totalComments,
  }) {
    return CommentsLoaded(
      comments ?? this.comments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      currentPage: currentPage ?? this.currentPage,
      totalComments: totalComments ?? this.totalComments,
    );
  }

  @override
  List<Object> get props => [
        comments,
        isSubmitting,
        isLoadingMore,
        hasMoreComments,
        currentPage,
        totalComments,
      ];
}

/// Estado de error
class CommentsError extends CommentsState {
  const CommentsError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

/// Estado de éxito después de una acción
class CommentsActionSuccess extends CommentsState {
  const CommentsActionSuccess(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
