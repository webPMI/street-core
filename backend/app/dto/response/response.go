package response

import (
	"backend/models"
	"math"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response status constants
const (
	StatusSuccess = "success"
	StatusError   = "error"
)

// SuccessResponse represents a successful API response
type SuccessResponse struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
	Data    any    `json:"data,omitempty"`
}

// ErrorResponse represents an error API response
type ErrorResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Details any    `json:"details,omitempty"`
}

// PaginatedResponse represents a paginated API response
type PaginatedResponse struct {
	Status string           `json:"status"`
	Data   PaginationResult `json:"data"`
}

// PaginationResult contains paginated data and metadata
type PaginationResult struct {
	Items      any                `json:"items"`
	Pagination PaginationMetadata `json:"pagination"`
}

// PaginationMetadata contains pagination information
type PaginationMetadata struct {
	Page       int   `json:"page"`
	Limit      int   `json:"limit"`
	Total      int64 `json:"total"`
	TotalPages int   `json:"totalPages"`
	HasNext    bool  `json:"hasNext"`
	HasPrev    bool  `json:"hasPrev"`
}

// ValidationError represents a validation error detail
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
	Value   string `json:"value,omitempty"`
}

// Success sends a successful JSON response
func Success(c *gin.Context, statusCode int, message string, data any) {
	c.JSON(statusCode, SuccessResponse{
		Status:  StatusSuccess,
		Message: message,
		Data:    data,
	})
}

// SuccessWithoutMessage sends a successful JSON response without message
func SuccessWithoutMessage(c *gin.Context, statusCode int, data any) {
	c.JSON(statusCode, SuccessResponse{
		Status: StatusSuccess,
		Data:   data,
	})
}

// Error sends an error JSON response
func Error(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, ErrorResponse{
		Status:  StatusError,
		Message: message,
	})
}

// ErrorWithDetails sends an error JSON response with details
func ErrorWithDetails(c *gin.Context, statusCode int, message string, details any) {
	c.JSON(statusCode, ErrorResponse{
		Status:  StatusError,
		Message: message,
		Details: details,
	})
}

// ValidationErrors sends a validation error JSON response
func ValidationErrors(c *gin.Context, errors []ValidationError) {
	c.JSON(http.StatusBadRequest, ErrorResponse{
		Status:  StatusError,
		Message: models.ValidationFailed,
		Details: errors,
	})
}

// Paginated sends a paginated JSON response with improved validation
func Paginated(c *gin.Context, statusCode int, items any, page, limit int, total int64) {
	// Validate inputs
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10 // Default limit
	}
	if total < 0 {
		total = 0
	}

	// Calculate total pages safely
	var totalPages int
	if limit > 0 {
		totalPages = int(math.Ceil(float64(total) / float64(limit)))
	}
	if totalPages < 1 {
		totalPages = 1
	}

	c.JSON(statusCode, PaginatedResponse{
		Status: StatusSuccess,
		Data: PaginationResult{
			Items: items,
			Pagination: PaginationMetadata{
				Page:       page,
				Limit:      limit,
				Total:      total,
				TotalPages: totalPages,
				HasNext:    page < totalPages,
				HasPrev:    page > 1,
			},
		},
	})
}

// Created sends a successful creation response (201)
func Created(c *gin.Context, message string, data any) {
	Success(c, http.StatusCreated, message, data)
}

// OK sends a successful OK response (200)
func OK(c *gin.Context, message string, data any) {
	Success(c, http.StatusOK, message, data)
}

// NoContent sends a successful no content response (204)
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// BadRequest sends a bad request error (400)
func BadRequest(c *gin.Context, message string) {
	Error(c, http.StatusBadRequest, message)
}

// Unauthorized sends an unauthorized error (401)
func Unauthorized(c *gin.Context, message string) {
	Error(c, http.StatusUnauthorized, message)
}

// Forbidden sends a forbidden error (403)
func Forbidden(c *gin.Context, message string) {
	Error(c, http.StatusForbidden, message)
}

// NotFound sends a not found error (404)
func NotFound(c *gin.Context, message string) {
	Error(c, http.StatusNotFound, message)
}

// Conflict sends a conflict error (409)
func Conflict(c *gin.Context, message string) {
	Error(c, http.StatusConflict, message)
}

// InternalServerError sends an internal server error (500)
func InternalServerError(c *gin.Context, message string) {
	Error(c, http.StatusInternalServerError, message)
}
