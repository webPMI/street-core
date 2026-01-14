package retry

import (
	"context"
	"fmt"
	"time"

	"backend/utils"
)

// RetryConfig holds configuration for retry behavior
type RetryConfig struct {
	MaxRetries int             // Maximum number of retry attempts
	Backoff    []time.Duration // Backoff durations for each retry
	OnRetry    func(attempt int, err error) // Callback on each retry
}

// DefaultConfig returns a default retry configuration with exponential backoff
func DefaultConfig() *RetryConfig {
	return &RetryConfig{
		MaxRetries: 3,
		Backoff: []time.Duration{
			1 * time.Second,  // First retry after 1s
			5 * time.Second,  // Second retry after 5s
			15 * time.Second, // Third retry after 15s
		},
		OnRetry: func(attempt int, err error) {
			utils.Warn("Retrying operation", map[string]interface{}{
				"attempt": attempt,
				"error":   err.Error(),
			})
		},
	}
}

// WithRetry executes a function with retry logic and exponential backoff
// ctx: context for cancellation
// maxRetries: maximum number of retry attempts (0 = no retries)
// fn: the function to execute
// Returns: error if all retries fail or context is canceled
func WithRetry(ctx context.Context, maxRetries int, fn func() error) error {
	config := DefaultConfig()
	config.MaxRetries = maxRetries
	return WithRetryConfig(ctx, config, fn)
}

// WithRetryConfig executes a function with custom retry configuration
// ctx: context for cancellation
// config: retry configuration
// fn: the function to execute
// Returns: error if all retries fail or context is canceled
func WithRetryConfig(ctx context.Context, config *RetryConfig, fn func() error) error {
	var lastErr error

	for attempt := 0; attempt <= config.MaxRetries; attempt++ {
		// Check context before attempting
		select {
		case <-ctx.Done():
			return fmt.Errorf("retry canceled: %w", ctx.Err())
		default:
		}

		// Execute the function
		lastErr = fn()

		// Success - no retry needed
		if lastErr == nil {
			if attempt > 0 {
				utils.Info("Operation succeeded after retry", map[string]interface{}{
					"attempts": attempt,
				})
			}
			return nil
		}

		// Last attempt failed - return error
		if attempt >= config.MaxRetries {
			break
		}

		// Call retry callback if provided
		if config.OnRetry != nil {
			config.OnRetry(attempt+1, lastErr)
		}

		// Calculate backoff duration
		var backoffDuration time.Duration
		if attempt < len(config.Backoff) {
			backoffDuration = config.Backoff[attempt]
		} else {
			// Use last backoff value if we exceed the array
			backoffDuration = config.Backoff[len(config.Backoff)-1]
		}

		// Wait for backoff duration or context cancellation
		select {
		case <-time.After(backoffDuration):
			// Continue to next retry
		case <-ctx.Done():
			return fmt.Errorf("retry canceled after %d attempts: %w", attempt+1, ctx.Err())
		}
	}

	return fmt.Errorf("operation failed after %d retries: %w", config.MaxRetries, lastErr)
}

// IsRetryable checks if an error is retryable
// Override this function to implement custom retry logic based on error types
func IsRetryable(err error) bool {
	if err == nil {
		return false
	}

	// Add custom logic here to determine if error is retryable
	// For example: network errors, temporary failures, etc.
	return true
}

// WithRetryIf executes a function with retry only if the error is retryable
func WithRetryIf(ctx context.Context, maxRetries int, fn func() error, isRetryable func(error) bool) error {
	config := DefaultConfig()
	config.MaxRetries = maxRetries

	var lastErr error
	for attempt := 0; attempt <= config.MaxRetries; attempt++ {
		select {
		case <-ctx.Done():
			return fmt.Errorf("retry canceled: %w", ctx.Err())
		default:
		}

		lastErr = fn()

		if lastErr == nil {
			return nil
		}

		// Check if error is retryable
		if !isRetryable(lastErr) {
			utils.Info("Error is not retryable, aborting", map[string]interface{}{
				"error": lastErr.Error(),
			})
			return lastErr
		}

		if attempt >= config.MaxRetries {
			break
		}

		if config.OnRetry != nil {
			config.OnRetry(attempt+1, lastErr)
		}

		var backoffDuration time.Duration
		if attempt < len(config.Backoff) {
			backoffDuration = config.Backoff[attempt]
		} else {
			backoffDuration = config.Backoff[len(config.Backoff)-1]
		}

		select {
		case <-time.After(backoffDuration):
		case <-ctx.Done():
			return fmt.Errorf("retry canceled after %d attempts: %w", attempt+1, ctx.Err())
		}
	}

	return fmt.Errorf("operation failed after %d retries: %w", config.MaxRetries, lastErr)
}
