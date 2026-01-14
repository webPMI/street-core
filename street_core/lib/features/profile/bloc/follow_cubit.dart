import 'package:equatable/equatable.dart';
import '../../../core/helpers/logger.dart';
import '../repositories/follow_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Follow Cubit
/// Manages follow/unfollow state for a specific user
class FollowCubit extends Cubit<FollowState> {

  FollowCubit(this._followRepository, this.userId)
      : super(const FollowState.initial());
  final FollowRepository _followRepository;
  final String userId;

  /// Check if current user is following the target user
  Future<void> checkFollowStatus() async {
    try {
      emit(state.copyWith(status: FollowStatus.checking));

      final isFollowing = await _followRepository.isFollowing(userId);

      if (isClosed) return;
      emit(state.copyWith(
        status: FollowStatus.idle,
        isFollowing: isFollowing,
      ));
    } catch (e) {
      AppLogger.error('Error checking follow status', error: e, tag: 'FollowCubit');
      if (isClosed) return;
      emit(state.copyWith(status: FollowStatus.error, errorMessage: e.toString()));
    }
  }

  /// Follow user
  Future<void> followUser() async {
    if (state.status == FollowStatus.loading) return;

    try {
      emit(state.copyWith(status: FollowStatus.loading));

      await _followRepository.followUser(userId);

      if (isClosed) return;
      emit(state.copyWith(
        status: FollowStatus.idle,
        isFollowing: true,
      ));
    } catch (e) {
      AppLogger.error('Error following user', error: e, tag: 'FollowCubit');
      if (isClosed) return;
      emit(state.copyWith(status: FollowStatus.error, errorMessage: e.toString()));

      // Reset to previous state after showing error
      await Future<void>.delayed(const Duration(seconds: 2));
      if (isClosed) return;
      emit(state.copyWith(status: FollowStatus.idle));
    }
  }

  /// Unfollow user
  Future<void> unfollowUser() async {
    if (state.status == FollowStatus.loading) return;

    try {
      emit(state.copyWith(status: FollowStatus.loading));

      await _followRepository.unfollowUser(userId);

      if (isClosed) return;
      emit(state.copyWith(
        status: FollowStatus.idle,
        isFollowing: false,
      ));
    } catch (e) {
      AppLogger.error('Error unfollowing user', error: e, tag: 'FollowCubit');
      if (isClosed) return;
      emit(state.copyWith(status: FollowStatus.error, errorMessage: e.toString()));

      // Reset to previous state after showing error
      await Future<void>.delayed(const Duration(seconds: 2));
      if (isClosed) return;
      emit(state.copyWith(status: FollowStatus.idle));
    }
  }

  /// Toggle follow/unfollow
  Future<void> toggleFollow() async {
    if (state.isFollowing) {
      await unfollowUser();
    } else {
      await followUser();
    }
  }
}

/// Follow Status Enum
enum FollowStatus { initial, checking, loading, idle, error }

/// Follow State
class FollowState extends Equatable {

  const FollowState({
    required this.status,
    required this.isFollowing,
    this.errorMessage,
  });

  const FollowState.initial()
      : status = FollowStatus.initial,
        isFollowing = false,
        errorMessage = null;
  final FollowStatus status;
  final bool isFollowing;
  final String? errorMessage;

  FollowState copyWith({
    FollowStatus? status,
    bool? isFollowing,
    String? errorMessage,
  }) {
    return FollowState(
      status: status ?? this.status,
      isFollowing: isFollowing ?? this.isFollowing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isFollowing, errorMessage];
}
