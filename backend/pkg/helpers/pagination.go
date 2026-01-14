package helpers

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

// ========================
// Pagination Constants
// ========================

const (
	// DefaultPageSize is the default number of items per page
	DefaultPageSize = 20

	// MaxPageSize is the maximum allowed page size to prevent DoS attacks
	MaxPageSize = 100

	// MinPageSize is the minimum allowed page size
	MinPageSize = 1
)

// ========================
// Pagination Functions
// ========================

// NormalizePagination validates and normalizes pagination parameters
// to prevent DoS attacks via unlimited pagination.
//
// Rules:
// - If skip < 0, set to 0
// - If limit <= 0, set to DefaultPageSize
// - If limit > MaxPageSize, set to MaxPageSize
//
// Parameters:
//   - skip: Number of documents to skip (offset)
//   - limit: Maximum number of documents to return (page size)
//
// Returns:
//   - Normalized skip value (>= 0)
//   - Normalized limit value (MinPageSize <= limit <= MaxPageSize)
//
// Example:
//
//	skip, limit := NormalizePagination(-10, 500)
//	// Returns: (0, 100) - skip normalized to 0, limit capped at MaxPageSize
func NormalizePagination(skip, limit int) (int, int) {
	// Normalize skip: must be >= 0
	if skip < 0 {
		skip = 0
	}

	// Normalize limit: must be > 0, default to DefaultPageSize
	if limit <= 0 {
		limit = DefaultPageSize
	}

	// Cap limit at MaxPageSize to prevent DoS attacks
	if limit > MaxPageSize {
		limit = MaxPageSize
	}

	return skip, limit
}

// ParsePaginationParams extracts and normalizes pagination parameters
// from Gin context query params.
//
// Query parameters:
//   - skip: Number of documents to skip (default: 0)
//   - limit: Maximum number of documents to return (default: DefaultPageSize)
//
// This function automatically applies security limits via NormalizePagination
// to prevent DoS attacks from malicious pagination requests.
//
// Example usage in handler:
//
//	func (h *Handler) List(c *gin.Context) {
//	    skip, limit := helpers.ParsePaginationParams(c)
//	    results, err := h.repository.Find(skip, limit)
//	    // ...
//	}
//
// Example requests:
//   - GET /api/items → skip=0, limit=20 (defaults)
//   - GET /api/items?skip=40&limit=10 → skip=40, limit=10
//   - GET /api/items?skip=-5&limit=200 → skip=0, limit=100 (normalized)
//   - GET /api/items?limit=0 → skip=0, limit=20 (default limit)
func ParsePaginationParams(c *gin.Context) (skip, limit int) {
	// Parse skip parameter (default: 0)
	skip = 0
	if skipStr := c.Query("skip"); skipStr != "" {
		if parsedSkip, err := strconv.Atoi(skipStr); err == nil {
			skip = parsedSkip
		}
	}

	// Parse limit parameter (default: 0, will be normalized to DefaultPageSize)
	limit = 0
	if limitStr := c.Query("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil {
			limit = parsedLimit
		}
	}

	// Apply security normalization
	return NormalizePagination(skip, limit)
}

// ========================
// Additional Pagination Helpers
// ========================

// CalculateTotalPages calculates the total number of pages based on
// total count and page size.
//
// Parameters:
//   - totalCount: Total number of documents
//   - pageSize: Number of documents per page
//
// Returns:
//   - Total number of pages (minimum 1)
//
// Example:
//
//	totalPages := CalculateTotalPages(95, 20) // Returns 5
func CalculateTotalPages(totalCount int64, pageSize int) int {
	if totalCount == 0 || pageSize <= 0 {
		return 1
	}

	pages := int(totalCount) / pageSize
	if int(totalCount)%pageSize > 0 {
		pages++
	}

	return pages
}

// CalculatePageNumber calculates the current page number based on
// skip and limit values.
//
// Parameters:
//   - skip: Number of documents skipped
//   - limit: Page size
//
// Returns:
//   - Current page number (1-indexed)
//
// Example:
//
//	pageNum := CalculatePageNumber(40, 20) // Returns 3 (page 3)
func CalculatePageNumber(skip, limit int) int {
	if limit <= 0 {
		limit = DefaultPageSize
	}

	return (skip / limit) + 1
}

// HasNextPage determines if there are more pages available
//
// Parameters:
//   - skip: Current skip value
//   - limit: Page size
//   - totalCount: Total number of documents
//
// Returns:
//   - true if more pages exist, false otherwise
//
// Example:
//
//	hasMore := HasNextPage(40, 20, 100) // Returns true (60 items remaining)
func HasNextPage(skip, limit int, totalCount int64) bool {
	if limit <= 0 {
		limit = DefaultPageSize
	}

	return int64(skip+limit) < totalCount
}

// GetPaginationMetadata returns metadata about pagination state
//
// Parameters:
//   - skip: Current skip value
//   - limit: Page size
//   - totalCount: Total number of documents
//
// Returns:
//   - Map containing: page, pageSize, totalPages, totalCount, hasNextPage
//
// Example:
//
//	metadata := GetPaginationMetadata(40, 20, 95)
//	// Returns: {page: 3, pageSize: 20, totalPages: 5, totalCount: 95, hasNextPage: true}
func GetPaginationMetadata(skip, limit int, totalCount int64) map[string]interface{} {
	skip, limit = NormalizePagination(skip, limit)

	return map[string]interface{}{
		"page":        CalculatePageNumber(skip, limit),
		"pageSize":    limit,
		"totalPages":  CalculateTotalPages(totalCount, limit),
		"totalCount":  totalCount,
		"hasNextPage": HasNextPage(skip, limit, totalCount),
	}
}
