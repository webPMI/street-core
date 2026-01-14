import 'package:equatable/equatable.dart';

/// Base class for all auth states.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - before any authentication check.
class AuthInitial extends AuthState {}

/// Loading state - while checking credentials or making API calls.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Checking session state - verifying existing token.
class AuthCheckingSession extends AuthState {}

/// Authenticated state - user is logged in.
class AuthAuthenticated extends AuthState {}

/// Unauthenticated state - no valid session.
class AuthUnauthenticated extends AuthState {}

/// Success state - for operations like password reset.
class AuthSuccess extends AuthState {
  const AuthSuccess([this.message]);
  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Error state - authentication failed.
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
