import 'package:equatable/equatable.dart';

import '../../../data/models/user_model.dart';

/// Enum for user update status.
enum UserUpdateStatus { initial, loading, success, error }

/// Base class for user states.
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no user loaded.
class UserInitial extends UserState {}

/// Loading state - fetching user data.
class UserLoading extends UserState {}

/// Loaded state - user data available.
class UserLoaded extends UserState {
  const UserLoaded(this.user, {this.updateStatus = UserUpdateStatus.initial});

  final UserModel user;
  final UserUpdateStatus updateStatus;

  @override
  List<Object?> get props => [user, updateStatus];

  UserLoaded copyWith({User? user, UserUpdateStatus? updateStatus}) {
    return UserLoaded(
      user ?? this.user,
      updateStatus: updateStatus ?? this.updateStatus,
    );
  }
}

/// Error state - failed to load user.
class UserError extends UserState {
  const UserError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
