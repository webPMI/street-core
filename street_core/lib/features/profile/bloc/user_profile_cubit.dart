import '../../../core/helpers/logger.dart';
import '../repositories/follow_repository.dart';
import '../repositories/profile_repository.dart';
import 'user_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing another user's profile view
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._profileRepository, this._followRepository)
    : super(UserProfileInitial());

  final ProfileRepository _profileRepository;
  final FollowRepository _followRepository;

  /// Fetch user profile by ID
  Future<void> fetchUserProfile(String userId) async {
    if (isClosed) return;

    emit(UserProfileLoading());

    try {
      // Get user by ID from repository
      final user = await _profileRepository.getUserById(userId);

      // Check if following
      bool isFollowing = false;
      try {
        isFollowing = await _followRepository.isFollowing(userId);
      } catch (e) {
        AppLogger.warning(
          'Could not check follow status: $e',
          tag: 'UserProfileCubit',
        );
      }

      if (isClosed) return;

      // Get stats
      int followersCount = 0;
      int followingCount = 0;
      int postsCount = 0;

      try {
        final stats = await _profileRepository.getUserStats(userId);
        followersCount = stats['followersCount'] ?? 0;
        followingCount = stats['followingCount'] ?? 0;
        postsCount = stats['postsCount'] ?? 0;
      } catch (e) {
        AppLogger.warning(
          'Could not fetch user stats: $e',
          tag: 'UserProfileCubit',
        );
        // Fallback to user model counts if available (legacy compatibility)
        // User model currently doesn't have these fields in User.dart but may have them in UserModel
      }

      emit(
        UserProfileLoaded(
          user: user,
          isFollowing: isFollowing,
          followersCount: followersCount,
          followingCount: followingCount,
          postsCount: postsCount,
        ),
      );
    } catch (e) {
      AppLogger.error(
        'Error fetching user profile: $e',
        tag: 'UserProfileCubit',
      );
      if (isClosed) return;
      emit(const UserProfileError('error.fetching.user.profile'));
    }
  }

  /// Toggle follow/unfollow for a user
  Future<void> toggleFollow(String userId) async {
    if (isClosed) return;

    final currentState = state;
    if (currentState is! UserProfileLoaded) return;

    try {
      // Toggle follow status
      final newFollowStatus = !currentState.isFollowing;
      final newFollowersCount = newFollowStatus
          ? currentState.followersCount + 1
          : currentState.followersCount - 1;

      // Call backend API to follow/unfollow
      if (newFollowStatus) {
        await _followRepository.followUser(userId);
      } else {
        await _followRepository.unfollowUser(userId);
      }

      if (isClosed) return;

      // Update state with new follow status
      emit(
        UserProfileFollowSuccess(
          user: currentState.user,
          isFollowing: newFollowStatus,
          followersCount: newFollowersCount,
          followingCount: currentState.followingCount,
          postsCount: currentState.postsCount,
        ),
      );

      // Return to loaded state after brief delay
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (isClosed) return;

      emit(
        UserProfileLoaded(
          user: currentState.user,
          isFollowing: newFollowStatus,
          followersCount: newFollowersCount,
          followingCount: currentState.followingCount,
          postsCount: currentState.postsCount,
        ),
      );
    } catch (e) {
      AppLogger.error('Error toggling follow: $e', tag: 'UserProfileCubit');
      if (isClosed) return;
      emit(const UserProfileError('error.following.user'));

      // Restore previous state
      await Future<void>.delayed(const Duration(seconds: 2));
      if (isClosed) return;
      emit(currentState);
    }
  }
}
