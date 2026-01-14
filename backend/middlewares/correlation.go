package middlewares

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CorrelationIDKey is the context key for the request correlation ID
const CorrelationIDKey = "X-Correlation-ID"

// CorrelationIDHeader is the HTTP header name for correlation ID
const CorrelationIDHeader = "X-Correlation-ID"

// CorrelationIDMiddleware generates a unique correlation ID for each request.
// This ID is used to trace requests across logs and services.
//
// The middleware:
// 1. Checks if a correlation ID was provided in the request header (for distributed tracing)
// 2. Generates a new UUID if none was provided
// 3. Stores the ID in the Gin context for use by handlers
// 4. Adds the ID to the response headers
//
// Usage:
//
//	router.Use(middlewares.CorrelationIDMiddleware())
//
// In handlers:
//
//	correlationID := middlewares.GetCorrelationID(c)
//	logger.Info("Processing request", "correlation_id", correlationID)
func CorrelationIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check if correlation ID was provided (for distributed tracing)
		correlationID := c.GetHeader(CorrelationIDHeader)

		// Generate new ID if not provided
		if correlationID == "" {
			correlationID = uuid.New().String()
		}

		// Store in context for handlers and other middlewares
		c.Set(CorrelationIDKey, correlationID)

		// Add to response headers for client tracing
		c.Header(CorrelationIDHeader, correlationID)

		c.Next()
	}
}

// GetCorrelationID retrieves the correlation ID from the Gin context.
// Returns empty string if not set.
func GetCorrelationID(c *gin.Context) string {
	if id, exists := c.Get(CorrelationIDKey); exists {
		if correlationID, ok := id.(string); ok {
			return correlationID
		}
	}
	return ""
}

// GetCorrelationIDFromContext is an alias for GetCorrelationID for clarity.
func GetCorrelationIDFromContext(c *gin.Context) string {
	return GetCorrelationID(c)
}
