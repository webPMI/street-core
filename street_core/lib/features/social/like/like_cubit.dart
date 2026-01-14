// lib/features/social/like/like_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/helpers/logger.dart';
import 'like_service.dart';
import 'like_state.dart';

/// Cubit para gestionar el estado de likes en cualquier entidad
/// Soporta posts, competitions, events, clubs, etc.
/// Implementa actualización optimista para mejor UX
class LikeCubit extends Cubit<LikeState> {
  LikeCubit(this._likeService) : super(const LikeInitial());

  final LikeService _likeService;

  /// Toggle like on any entity with optimistic update
  ///
  /// [entityType] - Type of entity (post, competition, event, etc.)
  /// [entityId] - ID of the entity
  /// [isCurrentlyLiked] - Current like status (true if already liked)
  /// [currentCount] - Current likes count
  Future<void> toggleLikeEntity({
    required String entityType,
    required String entityId,
    required bool isCurrentlyLiked,
    required int currentCount,
  }) async {
    // Optimistic update: update UI immediately
    final newIsLiked = !isCurrentlyLiked;
    final newCount = newIsLiked ? currentCount + 1 : currentCount - 1;
    emit(LikeSuccess(isLiked: newIsLiked, likesCount: newCount));

    try {
      AppLogger.debug(
        'Toggling like for $entityType: $entityId (currently: $isCurrentlyLiked)',
        tag: 'LikeCubit',
      );

      final actualIsLiked = await _likeService.toggleLikeEntity(
        entityType: entityType,
        entityId: entityId,
        isCurrentlyLiked: isCurrentlyLiked,
      );

      // Verify optimistic update was correct
      if (actualIsLiked != newIsLiked) {
        AppLogger.warning(
          'Optimistic update mismatch for $entityType. Expected: $newIsLiked, Got: $actualIsLiked',
          tag: 'LikeCubit',
        );
        final correctedCount = actualIsLiked ? currentCount + 1 : currentCount - 1;
        emit(LikeSuccess(isLiked: actualIsLiked, likesCount: correctedCount));
      }

      AppLogger.info(
        'Like toggled successfully for $entityType: $entityId',
        tag: 'LikeCubit',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error toggling like for $entityType: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'LikeCubit',
      );

      // Revert optimistic update
      emit(LikeSuccess(isLiked: isCurrentlyLiked, likesCount: currentCount));
      emit(LikeError(e.toString()));
    }
  }

  /// Check like status for any entity
  ///
  /// [entityType] - Type of entity (post, competition, event, etc.)
  /// [entityId] - ID of the entity
  Future<void> checkLikeStatus({
    required String entityType,
    required String entityId,
  }) async {
    emit(const LikeLoading());

    try {
      final isLiked = await _likeService.isEntityLiked(
        entityType: entityType,
        entityId: entityId,
      );
      emit(LikeSuccess(
        isLiked: isLiked,
        likesCount: 0, // Count will be updated separately from the entity
      ));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error checking like status for $entityType: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'LikeCubit',
      );
      emit(LikeError(e.toString()));
    }
  }

  // ============================================================================
  // LEGACY METHODS (Backward compatibility for posts)
  // ============================================================================

  /// Toggle like en un post con actualización optimista
  /// @deprecated Use toggleLikeEntity with entityType: 'post' instead
  @Deprecated('Use toggleLikeEntity with entityType: "post" instead')
  Future<void> toggleLike(
    String postId,
    bool isCurrentlyLiked,
    int currentCount,
  ) async {
    return toggleLikeEntity(
      entityType: 'post',
      entityId: postId,
      isCurrentlyLiked: isCurrentlyLiked,
      currentCount: currentCount,
    );
  }

  /// Verificar el estado de like de un post
  /// @deprecated Use checkLikeStatus with entityType: 'post' instead
  @Deprecated('Use checkLikeStatus with entityType: "post" instead')
  Future<void> checkLikeStatusPost(String postId) async {
    return checkLikeStatus(entityType: 'post', entityId: postId);
  }
}
