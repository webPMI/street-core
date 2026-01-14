import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

// Base state for viewing another user's profile
abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

// Initial state
class UserProfileInitial extends UserProfileState {}

// Loading user profile
class UserProfileLoading extends UserProfileState {}

// User profile loaded successfully
class UserProfileLoaded extends UserProfileState {
  const UserProfileLoaded({
    required this.user,
    this.isFollowing = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });
  final User user;
  final bool isFollowing;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  @override
  List<Object?> get props => [
    user,
    isFollowing,
    followersCount,
    followingCount,
    postsCount,
  ];

  UserProfileLoaded copyWith({
    User? user,
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) {
    return UserProfileLoaded(
      user: user ?? this.user,
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
    );
  }
}

// Error loading user profile
class UserProfileError extends UserProfileState {
  // i18n key

  const UserProfileError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// Follow/Unfollow action success (temporary state)
class UserProfileFollowSuccess extends UserProfileState {
  const UserProfileFollowSuccess({
    required this.user,
    required this.isFollowing,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
  });
  final User user;
  final bool isFollowing;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  @override
  List<Object?> get props => [
    user,
    isFollowing,
    followersCount,
    followingCount,
    postsCount,
  ];
}
