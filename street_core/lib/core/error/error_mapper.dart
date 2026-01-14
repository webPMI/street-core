import '../crud/exceptions/repository_exception.dart';
import './failure.dart';
import 'dart:async';
import 'dart:io' show SocketException;

/// Centralized utility to map technical exceptions to semantic Failures.
class ErrorMapper {
  /// Maps any object [error] to a [Failure] with a localization key.
  static Failure mapToFailure(dynamic error) {
    if (error is RepositoryException) {
      return _handleRepositoryException(error);
    }

    if (error is SocketException || error is TimeoutException) {
      return const NetworkFailure();
    }

    // Default fallback
    return ServerFailure(
      code: 'unknown.error',
      messageKey: 'error.unknown_occurred',
    );
  }

  static Failure _handleRepositoryException(RepositoryException error) {
    final code = error.originalError?.toString() ?? '';
    
    // Auth specific mappings
    if (code.contains('invalid_credentials') || code.contains('user_not_found')) {
      return AuthFailure('auth.error.invalid_credentials', code: code);
    }
    
    if (code.contains('user_already_exists')) {
      return AuthFailure('auth.error.user_exists', code: code);
    }

    // Generic server error carrying the message from API
    return ServerFailure(
      code: code,
      messageKey: _mapCodeToKey(code),
    );
  }

  static String _mapCodeToKey(String code) {
    // This could grow into a large dictionary or use module-specific mappers
    final cleanCode = code.toLowerCase().replaceAll(' ', '.');
    
    // Basic mapping heuristic
    if (cleanCode.contains('not_found')) return 'error.resource_not_found';
    if (cleanCode.contains('unauthorized')) return 'error.unauthorized';
    if (cleanCode.contains('forbidden')) return 'error.forbidden';
    
    return 'error.server_default';
  }
}
