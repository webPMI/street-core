import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Retry Helper with Exponential Backoff
///
/// Automatically retries failed operations with increasing delays.
/// Useful for network requests that might fail due to temporary issues.
///
/// **Features:**
/// - Exponential backoff (delays: 1s, 2s, 4s, 8s...)
/// - Configurable max attempts
/// - Jitter to prevent thundering herd
/// - Type-safe async operations
/// - Debug logging
///
/// **Usage:**
/// ```dart
/// final data = await RetryHelper.execute<UserData>(
///   operation: () => api.getUser(id),
///   maxAttempts: 3,
///   operationName: 'fetchUser',
/// );
/// ```
class RetryHelper {
  RetryHelper._(); // Private constructor

  /// Execute an operation with retry and exponential backoff
  ///
  /// **Parameters:**
  /// - [operation]: The async function to execute
  /// - [maxAttempts]: Maximum number of attempts (default: 3)
  /// - [initialDelay]: Starting delay in milliseconds (default: 1000ms = 1s)
  /// - [maxDelay]: Maximum delay between retries (default: 30000ms = 30s)
  /// - [backoffFactor]: Multiplier for delay (default: 2 for exponential)
  /// - [jitter]: Add random jitter to prevent synchronized retries (default: true)
  /// - [operationName]: Name for logging (default: 'operation')
  /// - [retryIf]: Optional condition to determine if retry should happen
  ///
  /// **Returns:** Result of the operation
  ///
  /// **Throws:** The last exception if all attempts fail
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    int initialDelay = 1000, // 1 second
    int maxDelay = 30000, // 30 seconds
    double backoffFactor = 2.0,
    bool jitter = true,
    String operationName = 'operation',
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempt = 0;
    int currentDelay = initialDelay;
    dynamic lastError;

    while (attempt < maxAttempts) {
      attempt++;

      try {
        if (kDebugMode && attempt > 1) {
          AppLogger.debug('Retry attempt $attempt/$maxAttempts for $operationName', tag: 'RetryHelper');
        }

        final result = await operation();

        if (kDebugMode && attempt > 1) {
          AppLogger.debug('Success on attempt $attempt for $operationName', tag: 'RetryHelper');
        }

        return result;
      } catch (e) {
        lastError = e;

        // Check if we should retry this error
        if (retryIf != null && !retryIf(e)) {
          AppLogger.warning('Error not retryable for $operationName', tag: 'RetryHelper');
          rethrow;
        }

        // If this was the last attempt, throw
        if (attempt >= maxAttempts) {
            AppLogger.error('All $maxAttempts attempts failed for $operationName', error: lastError, tag: 'RetryHelper');
          
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delayWithBackoff = min(
          (currentDelay * pow(backoffFactor, attempt - 1)).toInt(),
          maxDelay,
        );

        // Add jitter (random ±25% of delay) to prevent thundering herd
        final actualDelay = jitter
            ? delayWithBackoff +
                Random().nextInt((delayWithBackoff * 0.5).toInt()) -
                (delayWithBackoff * 0.25).toInt()
            : delayWithBackoff;

          AppLogger.debug('Waiting ${actualDelay}ms before attempt ${attempt + 1} for $operationName', tag: 'RetryHelper');
        

        // Wait before next attempt
        await Future.delayed(Duration(milliseconds: actualDelay));
      }
    }

    // This should never be reached, but just in case
    throw lastError ?? Exception('Retry failed for $operationName');
  }

  /// Execute with default retry settings for network requests
  ///
  /// Optimized for typical HTTP requests:
  /// - 3 attempts max
  /// - 1s initial delay
  /// - Exponential backoff
  /// - 10s max delay
  /// - Jitter enabled
  static Future<T> executeNetwork<T>({
    required Future<T> Function() operation,
    String operationName = 'network request',
  }) {
    return execute<T>(
      operation: operation,
      maxAttempts: 3,
      initialDelay: 1000,
      maxDelay: 10000,
      backoffFactor: 2.0,
      jitter: true,
      operationName: operationName,
    );
  }

  /// Execute with conservative retry for critical operations
  ///
  /// Uses longer delays and more attempts:
  /// - 5 attempts max
  /// - 2s initial delay
  /// - Exponential backoff
  /// - 60s max delay
  static Future<T> executeCritical<T>({
    required Future<T> Function() operation,
    String operationName = 'critical operation',
  }) {
    return execute<T>(
      operation: operation,
      maxAttempts: 5,
      initialDelay: 2000,
      maxDelay: 60000,
      backoffFactor: 2.0,
      jitter: true,
      operationName: operationName,
    );
  }

  /// Execute with aggressive retry for non-critical operations
  ///
  /// Fast retries with fewer attempts:
  /// - 2 attempts max
  /// - 500ms initial delay
  /// - 5s max delay
  static Future<T> executeFast<T>({
    required Future<T> Function() operation,
    String operationName = 'fast operation',
  }) {
    return execute<T>(
      operation: operation,
      maxAttempts: 2,
      initialDelay: 500,
      maxDelay: 5000,
      backoffFactor: 2.0,
      jitter: true,
      operationName: operationName,
    );
  }
}

/// Common retry conditions
class RetryConditions {
  RetryConditions._(); // Private constructor

  /// Retry only on network errors
  ///
  /// Returns true if the error appears to be network-related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup');
  }

  /// Retry only on server errors (5xx)
  ///
  /// Returns true if error appears to be a server error
  static bool isServerError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504');
  }

  /// Retry on network or server errors
  static bool isRetryableError(dynamic error) {
    return isNetworkError(error) || isServerError(error);
  }

  /// Never retry - used to explicitly disable retry for certain errors
  static bool never(dynamic error) => false;

  /// Always retry - use with caution
  static bool always(dynamic error) => true;
}
