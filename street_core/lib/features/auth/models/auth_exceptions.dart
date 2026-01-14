// lib/features/auth/models/auth_exceptions.dart

/// Base class for all authentication-related exceptions.
class AuthException implements Exception {
  /// Creates a new exception with a descriptive [message].
  ///
  /// Optionally includes the HTTP [statusCode] if applicable.
  const AuthException(this.message, {this.statusCode});

  /// Error message.
  final String message;

  /// Associated HTTP status code (if exists).
  final int? statusCode;

  @override
  String toString() {
    if (statusCode != null) {
      return 'AuthException [Status $statusCode]: $message';
    }
    return message;
  }
}

/// Exception thrown when credentials (email/password) are incorrect.
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([super.message = ''])
      : super(statusCode: 401);
}

/// Exception thrown when the session token has expired or is invalid.
class TokenExpiredException extends AuthException {
  const TokenExpiredException([
    super.message = 'Session expired. Please log in again.',
  ]) : super(statusCode: 401);
}

/// Exception thrown when attempting to register an email already in use.
class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException([super.message = 'Email already in use.'])
      : super(statusCode: 409);
}
