import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/helpers/logger.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/drawer/drawer_item.dart';
import '../../public/public_drawer.dart';
import '../auth.dart';

/// AuthCubit handles authentication state management.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService, this._userCubit) : super(AuthInitial());

  final AuthService _authService;
  final UserCubit _userCubit;

  /// Initialize authentication - check for existing session.
  void initialize() {
    AppLogger.lifecycle('AuthCubit initialized');
    checkAuthentication();
  }

  void onAuthhenticated() {
    AppLogger.auth('User authenticated');
    AppLogger.state('AuthCubit', 'Authenticated');
    emit(AuthAuthenticated());
    final pd = PublicDrawer.items;
    pd.removeWhere((i) => i.labelKey == 'log.in');
    pd.removeWhere((i) => i.labelKey == 'register');
    bool hasDashboard = false;
    for (final i in pd) {
      if (i.labelKey == 'dashboard') {
        hasDashboard = true;
      }
    }
    if (!hasDashboard) {
      PublicDrawer.items.add(
        DrawerItem(
          icon: Icons.dashboard,
          labelKey: 'dashboard',
          route: AppRoutes.dashboard,
        ),
      );
    }
  }
  //AGREGAMOS SISTEMA DE NAVEGACION SEGUN EL SISTEMA DE AUTH

  void onUnauthhenticated() {
    AppLogger.auth('User unauthenticated');
    AppLogger.state('AuthCubit', 'Unauthenticated');
    emit(AuthUnauthenticated());
    final pd = PublicDrawer.items;
    pd.removeWhere((i) => i.labelKey == 'dashboard');
    for (final i in pd) {
      if (i.labelKey == 'log.in') {
        return;
      }
    }
    PublicDrawer.items.addAll([
      DrawerItem(isDivider: true),
      DrawerItem(icon: Icons.login, labelKey: 'log.in', route: AppRoutes.login),
      DrawerItem(
        icon: Icons.person_add,
        labelKey: 'register',
        route: AppRoutes.register,
      ),
    ]);
  }

  /// Register a new user.
  Future<void> register(Map<String, dynamic> userData) async {
    AppLogger.auth('Register attempt', details: userData['email']);
    try {
      emit(const AuthLoading());
      final user = await _authService.register(userData);
      AppLogger.auth('Register successful', userId: user.id);
      _userCubit.setUser(user);
      onAuthhenticated();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Register failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'AUTH',
      );
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Login with email and password.
  Future<void> login(String email, String password) async {
    AppLogger.auth('Login attempt', details: email);
    emit(const AuthLoading());

    try {
      final user = await _authService.login(email, password);
      AppLogger.auth('Login successful', userId: user.id);
      _userCubit.setUser(user);
      onAuthhenticated();
    } on AuthException catch (e) {
      AppLogger.error('Login failed: ${e.message}', tag: 'AUTH');
      emit(AuthError(e.message));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Login network error',
        error: e,
        stackTrace: stackTrace,
        tag: 'AUTH',
      );
      emit(const AuthError('error.network'));
    }
  }

  /// Request password reset.
  Future<void> resetPassword(String email) async {
    AppLogger.auth('Password reset requested', details: email);
    try {
      emit(const AuthLoading());
      await _authService.resetPasswordRequest(email);
      AppLogger.auth('Password reset email sent');
      emit(const AuthSuccess('password.reset.email.sent'));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Password reset failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'AUTH',
      );
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Check if user has a valid session.
  Future<void> checkAuthentication() async {
    AppLogger.auth('Checking existing session');
    emit(AuthCheckingSession());

    try {
      final token = await _authService.getAuthToken();

      if (token != null && token.isNotEmpty) {
        AppLogger.debug('Found existing token, fetching profile', tag: 'AUTH');
        final user = await _authService
            .fetchCurrentUserProfile(token)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                AppLogger.error('Session check timeout', tag: 'AUTH');
                throw Exception('error.timeout');
              },
            );

        if (user != null) {
          AppLogger.auth('Session restored', userId: user.id);
          _userCubit.setUser(user);
          onAuthhenticated();
          return;
        } else {
          AppLogger.warning('Token valid but no user profile', tag: 'AUTH');
          await _authService.removeAuthToken();
          onUnauthhenticated();
        }
      } else {
        AppLogger.debug('No existing session found', tag: 'AUTH');
        onUnauthhenticated();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Session check failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'AUTH',
      );
      await _authService.removeAuthToken();
      onUnauthhenticated();
    }
  }

  /// Logout the current user.
  Future<void> logout() async {
    AppLogger.auth('Logout initiated');
    emit(const AuthLoading());
    await _authService.logout();
    _userCubit.clearUser();
    AppLogger.auth('Logout completed');
    onUnauthhenticated();
  }

  /// Delete the user's account.
  Future<void> deleteAccount() async {
    AppLogger.auth('Account deletion initiated');
    try {
      emit(const AuthLoading());
      await _authService.deleteAccount();
      _userCubit.clearUser();
      AppLogger.auth('Account deleted successfully');
      onUnauthhenticated();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Account deletion failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'AUTH',
      );
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
