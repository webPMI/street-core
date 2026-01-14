package response

import (
	"backend/models"
	"backend/pkg/errors"
	"backend/utils"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
)

// Response represents a standard API response
type Response struct {
	Status  string      `json:"status"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Details interface{} `json:"details,omitempty"`
}

// Success sends a successful response
func Success(c *gin.Context, statusCode int, message string, data interface{}) {
	c.JSON(statusCode, Response{
		Status:  "success",
		Message: message,
		Data:    data,
	})
}

// SuccessWithoutMessage sends a successful response without message
func SuccessWithoutMessage(c *gin.Context, statusCode int, data interface{}) {
	c.JSON(statusCode, Response{
		Status: "success",
		Data:   data,
	})
}

// Created sends a 201 Created response
func Created(c *gin.Context, message string, data interface{}) {
	Success(c, http.StatusCreated, message, data)
}

// OK sends a 200 OK response
func OK(c *gin.Context, message string, data interface{}) {
	Success(c, http.StatusOK, message, data)
}

// NoContent sends a 204 No Content response
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// Error sends an error response
func Error(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, Response{
		Status:  "error",
		Message: message,
	})
}

// ErrorWithDetails sends an error response with additional details
func ErrorWithDetails(c *gin.Context, statusCode int, message string, details interface{}) {
	c.JSON(statusCode, Response{
		Status:  "error",
		Message: message,
		Details: details,
	})
}

// HandleError handles an error and sends appropriate response
// This is the primary error handler that should be used throughout the app.
// It automatically includes the correlation ID in logs for distributed tracing.
func HandleError(c *gin.Context, err error) {
	if err == nil {
		return
	}

	// Get correlation ID for tracing
	correlationID := getCorrelationID(c)

	// Check if it's an AppError
	var appErr *errors.AppError
	if errors.As(err, &appErr) {
		// Log error with fields including correlation ID
		logErrorWithCorrelation(appErr, correlationID, c.Request.URL.Path)

		// Send response with error code (i18n key)
		if len(appErr.Fields) > 0 {
			ErrorWithDetails(c, appErr.StatusCode, appErr.Code, appErr.Fields)
		} else {
			Error(c, appErr.StatusCode, appErr.Code)
		}
		return
	}

	// Check if it's a validation error
	var validationErrs validator.ValidationErrors
	if errors.As(err, &validationErrs) {
		details := formatValidationErrors(validationErrs)
		ErrorWithDetails(c, http.StatusBadRequest, models.ValidationFailed, details)
		return
	}

	// Unknown error - log and send generic error
	utils.Error("Unexpected error", map[string]interface{}{
		"correlation_id": correlationID,
		"error":          err.Error(),
		"path":           c.Request.URL.Path,
	})

	Error(c, http.StatusInternalServerError, models.ServerError)
}

// getCorrelationID extracts correlation ID from Gin context
func getCorrelationID(c *gin.Context) string {
	if id, exists := c.Get("X-Correlation-ID"); exists {
		if correlationID, ok := id.(string); ok {
			return correlationID
		}
	}
	return ""
}

// BadRequest sends a 400 Bad Request response
func BadRequest(c *gin.Context, message string) {
	Error(c, http.StatusBadRequest, message)
}

// Unauthorized sends a 401 Unauthorized response
func Unauthorized(c *gin.Context, message string) {
	Error(c, http.StatusUnauthorized, message)
}

// Forbidden sends a 403 Forbidden response
func Forbidden(c *gin.Context, message string) {
	Error(c, http.StatusForbidden, message)
}

// NotFound sends a 404 Not Found response
func NotFound(c *gin.Context, message string) {
	Error(c, http.StatusNotFound, message)
}

// Conflict sends a 409 Conflict response
func Conflict(c *gin.Context, message string) {
	Error(c, http.StatusConflict, message)
}

// TooManyRequests sends a 429 Too Many Requests response
func TooManyRequests(c *gin.Context, message string) {
	Error(c, http.StatusTooManyRequests, message)
}

// InternalServerError sends a 500 Internal Server Error response
func InternalServerError(c *gin.Context, message string) {
	Error(c, http.StatusInternalServerError, message)
}

// ========================
// Helper Functions
// ========================

// logErrorWithCorrelation logs an AppError with correlation ID for distributed tracing
func logErrorWithCorrelation(err *errors.AppError, correlationID, path string) {
	fields := make(map[string]interface{})

	// Copy existing fields
	for k, v := range err.Fields {
		fields[k] = v
	}

	// Add standard fields
	fields["correlation_id"] = correlationID
	fields["code"] = err.Code
	fields["status_code"] = err.StatusCode
	fields["path"] = path

	// Don't log the underlying error message if it contains sensitive info
	if err.Err != nil {
		fields["internal_error"] = err.Message
	}

	// Log as error if status code is 5xx, warn for 4xx
	if err.StatusCode >= 500 {
		utils.Error(err.Message, fields)
	} else if err.StatusCode >= 400 {
		utils.Warn(err.Message, fields)
	}
}

// formatValidationErrors formats validator.ValidationErrors for response
func formatValidationErrors(errs validator.ValidationErrors) map[string]string {
	errors := make(map[string]string)
	for _, err := range errs {
		errors[err.Field()] = formatValidationTag(err)
	}
	return errors
}

// formatValidationTag formats a validation error tag into a readable message
func formatValidationTag(err validator.FieldError) string {
	switch err.Tag() {
	case "required":
		return models.RequiredField
	case "email":
		return models.InvalidEmail
	case "min":
		return models.ValueTooShort
	case "max":
		return models.ValueTooLong
	case "gte":
		return models.ValueTooSmall
	case "lte":
		return models.ValueTooLarge
	case "url":
		return models.InvalidURL
	case "uuid":
		return models.InvalidUUID
	default:
		return models.InvalidValue
	}
}
