/// Retry Policy
///
/// Configurable retry policy for repository operations with
/// exponential backoff support.
library;

import 'dart:async';
import 'dart:math';

import '../exceptions/repository_exception.dart';

/// Configuration for retry behavior
class RetryPolicy {

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
    this.shouldRetry,
  });
  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Initial delay between retries
  final Duration initialDelay;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Whether to add jitter to delays
  final bool useJitter;

  /// Function to determine if an error should trigger a retry
  final bool Function(Exception)? shouldRetry;

  /// Default policy with sensible defaults
  static const RetryPolicy defaultPolicy = RetryPolicy();

  /// No retry policy
  static const RetryPolicy noRetry = RetryPolicy(maxAttempts: 1);

  /// Aggressive retry policy for critical operations
  static const RetryPolicy aggressive = RetryPolicy(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 30),
  );

  /// Calculate delay for a specific attempt
  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;

    // Calculate exponential backoff
    final exponentialDelay = initialDelay.inMilliseconds *
        pow(backoffMultiplier, attempt - 1).toInt();

    // Cap at maxDelay
    final cappedDelay = min(exponentialDelay, maxDelay.inMilliseconds);

    // Add jitter if enabled (up to 25% of the delay)
    if (useJitter) {
      final jitter = (Random().nextDouble() * 0.25 * cappedDelay).toInt();
      return Duration(milliseconds: cappedDelay + jitter);
    }

    return Duration(milliseconds: cappedDelay);
  }

  /// Check if should retry based on exception
  bool shouldRetryException(Exception e) {
    // Use custom function if provided
    if (shouldRetry != null) {
      return shouldRetry!(e);
    }

    // Default: retry RepositoryExceptions that are retryable
    if (e is RepositoryException) {
      return e.isRetryable;
    }

    // Don't retry unknown exceptions by default
    return false;
  }
}

/// Executes an operation with retry logic
class RetryExecutor {

  const RetryExecutor({this.policy = const RetryPolicy()});
  final RetryPolicy policy;

  /// Execute an async operation with retry support
  Future<T> execute<T>({
    required Future<T> Function() operation,
    void Function(int attempt, Exception error, Duration nextDelay)?
        onRetry,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < policy.maxAttempts) {
      attempts++;

      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;

        // Check if we should retry
        if (attempts >= policy.maxAttempts ||
            !policy.shouldRetryException(e)) {
          rethrow;
        }

        // Calculate delay for next attempt
        final delay = policy.getDelayForAttempt(attempts);

        // Notify callback
        onRetry?.call(attempts, e, delay);

        // Wait before retry
        await Future<void>.delayed(delay);
      }
    }

    // Should not reach here, but just in case
    throw lastException ??
        const RepositoryException('Max retry attempts reached');
  }
}
