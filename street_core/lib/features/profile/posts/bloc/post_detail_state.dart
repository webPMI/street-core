// lib/presentation/dashboard/posts/bloc/post_detail_state.dart

import 'package:equatable/equatable.dart';
import '../../models/post_model.dart';

/// Clase base para todos los estados de detalle de post
abstract class PostDetailState extends Equatable {
  const PostDetailState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PostDetailInitial extends PostDetailState {}

/// Estado de carga
class PostDetailLoading extends PostDetailState {}

/// Estado cargado con el post
class PostDetailLoaded extends PostDetailState {
  const PostDetailLoaded(this.post);
  final PostModel post;

  PostDetailLoaded copyWith({PostModel? post}) {
    return PostDetailLoaded(post ?? this.post);
  }

  @override
  List<Object> get props => [post];
}

/// Estado de error
class PostDetailError extends PostDetailState {
  const PostDetailError(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

/// Estado de éxito después de una acción
class PostDetailActionSuccess extends PostDetailState {
  const PostDetailActionSuccess(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
