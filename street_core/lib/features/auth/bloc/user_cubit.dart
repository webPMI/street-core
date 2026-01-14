import '../../../core/helpers/logger.dart';
import '../../../data/models/user_model.dart';
import '../../profile/repositories/profile_repository.dart';
import 'user_state.dart';
import '../services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// UserCubit manages the current user's state.
class UserCubit extends Cubit<UserState> {
  UserCubit(this._authService, this._profileRepository) : super(UserInitial());

  final AuthService _authService;
  final ProfileRepository _profileRepository;

  /// Get the auth service (for widgets that need direct access).
  AuthService get authService => _authService;

  /// Set the current user.
  void setUser(UserModel user) {
    if (isClosed) return;
    AppLogger.state('UserCubit', 'UserLoaded', details: 'id=${user.id.substring(0, 8)}...');
    emit(UserLoaded(user));
  }

  /// Clear the current user (on logout).
  void clearUser() {
    if (isClosed) return;
    AppLogger.state('UserCubit', 'UserCleared');
    emit(UserInitial());
  }

  /// Update the user's profile.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state is! UserLoaded) return;
    final currentState = state as UserLoaded;

    AppLogger.debug('Updating profile: ${data.keys.join(', ')}', tag: 'USER');

    if (isClosed) return;
    emit(currentState.copyWith(updateStatus: UserUpdateStatus.loading));

    try {
      final updatedUser = await _profileRepository.updateUser(
        currentState.user.id,
        data,
      );

      if (isClosed) return;
      AppLogger.info('Profile updated successfully', tag: 'USER');
      emit(UserLoaded(updatedUser, updateStatus: UserUpdateStatus.success));

      // Reset status after delay
      await Future<void>.delayed(const Duration(seconds: 3));
      if (isClosed) return;
      emit(
        (state as UserLoaded).copyWith(updateStatus: UserUpdateStatus.initial),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Profile update failed', error: e, stackTrace: stackTrace, tag: 'USER');
      if (isClosed) return;
      emit(currentState.copyWith(updateStatus: UserUpdateStatus.error));

      // Reset status after delay
      await Future<void>.delayed(const Duration(seconds: 3));
      if (isClosed) return;
      emit(
        (state as UserLoaded).copyWith(updateStatus: UserUpdateStatus.initial),
      );
    }
  }

  /// Update specific user fields locally (optimistic update).
  void updateUserField(UserModel Function(UserModel) update) {
    if (state is! UserLoaded) return;
    final currentUser = (state as UserLoaded).user;
    AppLogger.debug('Optimistic user field update', tag: 'USER');
    emit(UserLoaded(update(currentUser)));
  }

  /// Get current user if loaded.
  UserModel? get currentUser {
    if (state is UserLoaded) {
      return (state as UserLoaded).user;
    }
    return null;
  }
}
