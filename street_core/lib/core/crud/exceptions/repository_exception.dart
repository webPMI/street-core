/// Repository Exception
///
/// Custom exception for repository operations, providing more context
/// than generic exceptions.
library;

/// Exception thrown when a repository operation fails
class RepositoryException implements Exception {

  const RepositoryException(
    this.message, {
    this.code,
    this.statusCode,
    this.originalError,
    this.stackTrace,
    this.type = RepositoryErrorType.unknown,
  });

  /// Create a network error
  factory RepositoryException.network(
    String message, {
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RepositoryException(
      message,
      code: 'NETWORK_ERROR',
      originalError: originalError,
      stackTrace: stackTrace,
      type: RepositoryErrorType.network,
    );
  }

  /// Create a server error
  factory RepositoryException.server(
    String message, {
    String? code,
    int? statusCode,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RepositoryException(
      message,
      code: code ?? 'SERVER_ERROR',
      statusCode: statusCode,
      originalError: originalError,
      stackTrace: stackTrace,
      type: RepositoryErrorType.server,
    );
  }

  /// Create a parse/deserialization error
  factory RepositoryException.parse(
    String message, {
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RepositoryException(
      message,
      code: 'PARSE_ERROR',
      originalError: originalError,
      stackTrace: stackTrace,
      type: RepositoryErrorType.parse,
    );
  }

  /// Create a not found error
  factory RepositoryException.notFound(
    String message, {
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RepositoryException(
      message,
      code: 'NOT_FOUND',
      originalError: originalError,
      stackTrace: stackTrace,
      type: RepositoryErrorType.notFound,
    );
  }

  /// Create a validation error
  factory RepositoryException.validation(
    String message, {
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RepositoryException(
      message,
      code: 'VALIDATION_ERROR',
      originalError: originalError,
      stackTrace: stackTrace,
      type: RepositoryErrorType.validation,
    );
  }

  /// Create an unauthorized error
  factory RepositoryException.unauthorized(
    String message, {
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RepositoryException(
      message,
      code: 'UNAUTHORIZED',
      originalError: originalError,
      stackTrace: stackTrace,
      type: RepositoryErrorType.unauthorized,
    );
  }

  /// Create a timeout error
  factory RepositoryException.timeout(
    String message, {
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RepositoryException(
      message,
      code: 'TIMEOUT',
      originalError: originalError,
      stackTrace: stackTrace,
      type: RepositoryErrorType.timeout,
    );
  }
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final RepositoryErrorType type;

  /// Check if this error is retryable
  bool get isRetryable {
    return type == RepositoryErrorType.network ||
        type == RepositoryErrorType.timeout ||
        type == RepositoryErrorType.server;
  }

  @override
  String toString() {
    final buffer = StringBuffer('RepositoryException: $message');
    if (code != null) {
      buffer.write(' (code: $code)');
    }
    return buffer.toString();
  }
}

/// Types of repository errors
enum RepositoryErrorType {
  /// Network connectivity issues
  network,

  /// Server returned an error
  server,

  /// Failed to parse response
  parse,

  /// Resource not found
  notFound,

  /// Validation failed
  validation,

  /// User not authorized
  unauthorized,

  /// Request timed out
  timeout,

  /// Unknown error
  unknown,
}
