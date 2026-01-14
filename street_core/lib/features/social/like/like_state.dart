// lib/features/social/like/like_state.dart

import 'package:equatable/equatable.dart';

/// Clase base para todos los estados de likes
abstract class LikeState extends Equatable {
  const LikeState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class LikeInitial extends LikeState {
  const LikeInitial();
}

/// Estado de carga
class LikeLoading extends LikeState {
  const LikeLoading();
}

/// Estado exitoso con información de like actualizada
class LikeSuccess extends LikeState {
  const LikeSuccess({
    required this.isLiked,
    required this.likesCount,
  });

  final bool isLiked;
  final int likesCount;

  @override
  List<Object?> get props => [isLiked, likesCount];
}

/// Estado de error
class LikeError extends LikeState {
  const LikeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
