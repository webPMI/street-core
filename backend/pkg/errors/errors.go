package errors

import (
	"backend/models"
	"errors"
	"fmt"
	"net/http"

	"go.mongodb.org/mongo-driver/mongo"
)

// AppError represents a standardized application error
type AppError struct {
	Code       string                 // Error code (i18n key from models.messages)
	Message    string                 // Internal message for logging
	StatusCode int                    // HTTP status code
	Err        error                  // Underlying error
	Fields     map[string]interface{} // Additional fields for logging/context
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

func (e *AppError) Unwrap() error {
	return e.Err
}

// NewAppError creates a new application error
func NewAppError(code, message string, statusCode int, err error) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		StatusCode: statusCode,
		Err:        err,
		Fields:     make(map[string]interface{}),
	}
}

// WithField adds a field to the error context
func (e *AppError) WithField(key string, value interface{}) *AppError {
	e.Fields[key] = value
	return e
}

// WithFields adds multiple fields to the error context
func (e *AppError) WithFields(fields map[string]interface{}) *AppError {
	for k, v := range fields {
		e.Fields[k] = v
	}
	return e
}

// ========================
// Auth Errors
// ========================

// ErrInvalidCredentials invalid username or password
func ErrInvalidCredentials() *AppError {
	return NewAppError(
		models.InvalidCredentials,
		"Invalid credentials provided",
		http.StatusUnauthorized,
		nil,
	)
}

// ErrAccountLocked account is temporarily locked due to failed login attempts
func ErrAccountLocked(minutesRemaining int) *AppError {
	return NewAppError(
		models.AccountLocked,
		fmt.Sprintf("Account locked for %d minutes", minutesRemaining),
		http.StatusTooManyRequests, // 429
		nil,
	).WithField("minutes_remaining", minutesRemaining)
}

// ErrUnauthorized user is not authenticated
func ErrUnauthorized() *AppError {
	return NewAppError(
		models.Unauthorized,
		"User not authenticated",
		http.StatusUnauthorized,
		nil,
	)
}

// ErrInvalidToken token is invalid or malformed
func ErrInvalidToken() *AppError {
	return NewAppError(
		models.InvalidToken,
		"Invalid or malformed token",
		http.StatusUnauthorized,
		nil,
	)
}

// ErrTokenExpired token has expired
func ErrTokenExpired() *AppError {
	return NewAppError(
		models.TokenExpired,
		"Token has expired",
		http.StatusUnauthorized,
		nil,
	)
}

// ErrTokenRevoked token has been revoked
func ErrTokenRevoked() *AppError {
	return NewAppError(
		models.TokenRevoked,
		"Token has been revoked",
		http.StatusUnauthorized,
		nil,
	)
}

// ========================
// Validation Errors
// ========================

// ErrInvalidEmail email format is invalid
func ErrInvalidEmail() *AppError {
	return NewAppError(
		models.InvalidEmail,
		"Invalid email format",
		http.StatusBadRequest,
		nil,
	)
}

// ErrRequiredField required field is missing
func ErrRequiredField(field string) *AppError {
	return NewAppError(
		models.RequiredField,
		fmt.Sprintf("Required field missing: %s", field),
		http.StatusBadRequest,
		nil,
	).WithField("field", field)
}

// ErrWeakPassword password does not meet strength requirements
func ErrWeakPassword(details []string) *AppError {
	return NewAppError(
		models.WeakPassword,
		"Password does not meet strength requirements",
		http.StatusBadRequest,
		nil,
	).WithField("details", details)
}

// ErrInvalidInput generic validation error
func ErrInvalidInput(message string) *AppError {
	return NewAppError(
		models.InvalidInput,
		message,
		http.StatusBadRequest,
		nil,
	)
}

// ErrJSONParsingFailed failed to parse JSON request
func ErrJSONParsingFailed(err error) *AppError {
	return NewAppError(
		models.JSONParsingFailed,
		"Failed to parse request body",
		http.StatusBadRequest,
		err,
	)
}

// ========================
// Resource Errors
// ========================

// ErrUserNotFound user does not exist
func ErrUserNotFound() *AppError {
	return NewAppError(
		models.UserNotFound,
		"User not found",
		http.StatusNotFound,
		nil,
	)
}

// ErrResourceNotFound generic resource not found
func ErrResourceNotFound(resource string) *AppError {
	return NewAppError(
		models.ResourceNotFound,
		fmt.Sprintf("%s not found", resource),
		http.StatusNotFound,
		nil,
	).WithField("resource", resource)
}

// ========================
// Conflict Errors
// ========================

// ErrEmailAlreadyExists email is already registered
func ErrEmailAlreadyExists() *AppError {
	return NewAppError(
		models.EmailAlreadyExists,
		"Email already registered",
		http.StatusConflict,
		nil,
	)
}

// ErrUsernameAlreadyExists username is already taken
func ErrUsernameAlreadyExists() *AppError {
	return NewAppError(
		models.UsernameAlreadyExists,
		"Username already taken",
		http.StatusConflict,
		nil,
	)
}

// ErrDuplicateResource generic duplicate resource error
func ErrDuplicateResource(resource string) *AppError {
	return NewAppError(
		models.DuplicateResource,
		fmt.Sprintf("%s already exists", resource),
		http.StatusConflict,
		nil,
	).WithField("resource", resource)
}

// ========================
// Permission Errors
// ========================

// ErrPermissionDenied user does not have permission
func ErrPermissionDenied() *AppError {
	return NewAppError(
		models.PermissionDenied,
		"Permission denied",
		http.StatusForbidden,
		nil,
	)
}

// ErrAdminOnly action requires admin privileges
func ErrAdminOnly() *AppError {
	return NewAppError(
		models.AdminOnly,
		"Admin privileges required",
		http.StatusForbidden,
		nil,
	)
}

// ========================
// System Errors
// ========================

// ErrDatabaseError database operation failed
func ErrDatabaseError(operation string, err error) *AppError {
	return NewAppError(
		models.DatabaseError,
		fmt.Sprintf("Database error during %s", operation),
		http.StatusInternalServerError,
		err,
	).WithField("operation", operation)
}

// ErrInternalServer generic internal server error
func ErrInternalServer(message string, err error) *AppError {
	return NewAppError(
		models.ServerError,
		message,
		http.StatusInternalServerError,
		err,
	)
}

// ErrTokenCreationFailed failed to create authentication token
func ErrTokenCreationFailed(err error) *AppError {
	return NewAppError(
		models.TokenCreationFailed,
		"Failed to create authentication token",
		http.StatusInternalServerError,
		err,
	)
}

// ErrTokenRevocationFailed failed to revoke token
func ErrTokenRevocationFailed(err error) *AppError {
	return NewAppError(
		models.TokenRevocationFailed,
		"Failed to revoke authentication token",
		http.StatusInternalServerError,
		err,
	)
}

// ========================
// Helper Functions
// ========================

// IsNotFound checks if error is a not found error
func IsNotFound(err error) bool {
	if err == mongo.ErrNoDocuments {
		return true
	}
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr.StatusCode == http.StatusNotFound
	}
	return false
}

// IsDuplicateKeyError checks if error is a MongoDB duplicate key error
func IsDuplicateKeyError(err error) bool {
	var writeErr mongo.WriteException
	if errors.As(err, &writeErr) {
		for _, e := range writeErr.WriteErrors {
			if e.Code == 11000 {
				return true
			}
		}
	}
	return mongo.IsDuplicateKeyError(err)
}

// FromMongoError converts MongoDB error to AppError
func FromMongoError(err error, operation string) *AppError {
	if err == nil {
		return nil
	}

	if err == mongo.ErrNoDocuments {
		return ErrResourceNotFound(operation)
	}

	if IsDuplicateKeyError(err) {
		// Try to determine which field is duplicated
		if mongo.IsDuplicateKeyError(err) {
			// Check error message for field name
			errMsg := err.Error()
			if contains(errMsg, "email") {
				return ErrEmailAlreadyExists()
			}
			if contains(errMsg, "username") {
				return ErrUsernameAlreadyExists()
			}
		}
		return ErrDuplicateResource(operation)
	}

	return ErrDatabaseError(operation, err)
}

// contains checks if string contains substring (case-insensitive helper)
func contains(s, substr string) bool {
	return len(s) >= len(substr) &&
		(s == substr || len(s) > len(substr) &&
			(s[:len(substr)] == substr || s[len(s)-len(substr):] == substr ||
				findSubstring(s, substr)))
}

func findSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// As is a helper for errors.As
func As(err error, target interface{}) bool {
	return errors.As(err, target)
}

// Is is a helper for errors.Is
func Is(err, target error) bool {
	return errors.Is(err, target)
}
