package middlewares

import (
	"time"

	"backend/utils"

	"github.com/gin-gonic/gin"
)

// AuditLog creates a middleware that logs audit events with structured data.
// Use this for security-sensitive operations that need an audit trail.
func AuditLog(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()

		// Process request
		c.Next()

		// Capture audit data after request completes
		duration := time.Since(startTime)
		statusCode := c.Writer.Status()

		// Build audit log entry
		auditData := map[string]interface{}{
			"action":      action,
			"method":      c.Request.Method,
			"path":        c.Request.URL.Path,
			"ip":          c.ClientIP(),
			"status_code": statusCode,
			"duration_ms": duration.Milliseconds(),
			"user_agent":  c.Request.UserAgent(),
		}

		// Add user ID if authenticated
		if userID, exists := c.Get(UserIDKey); exists {
			if userIDStr, ok := userID.(string); ok && userIDStr != "" {
				auditData["user_id"] = userIDStr
			}
		}

		// Add correlation ID if available
		if correlationID := GetCorrelationID(c); correlationID != "" {
			auditData["correlation_id"] = correlationID
		}

		// Log with appropriate level based on status
		if statusCode >= 400 {
			utils.Warn("Audit: "+action, auditData)
		} else {
			utils.Info("Audit: "+action, auditData)
		}
	}
}

// AuditLogWithReason creates an audit log with a custom reason field.
// Useful for operations like blocking users where context matters.
func AuditLogWithReason(action string, reasonExtractor func(*gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()

		// Process request
		c.Next()

		// Capture audit data after request completes
		duration := time.Since(startTime)
		statusCode := c.Writer.Status()

		// Build audit log entry
		auditData := map[string]interface{}{
			"action":      action,
			"method":      c.Request.Method,
			"path":        c.Request.URL.Path,
			"ip":          c.ClientIP(),
			"status_code": statusCode,
			"duration_ms": duration.Milliseconds(),
		}

		// Add reason if extractor provided
		if reasonExtractor != nil {
			if reason := reasonExtractor(c); reason != "" {
				auditData["reason"] = reason
			}
		}

		// Add user ID if authenticated
		if userID, exists := c.Get(UserIDKey); exists {
			if userIDStr, ok := userID.(string); ok && userIDStr != "" {
				auditData["user_id"] = userIDStr
			}
		}

		// Add correlation ID if available
		if correlationID := GetCorrelationID(c); correlationID != "" {
			auditData["correlation_id"] = correlationID
		}

		// Log with appropriate level based on status
		if statusCode >= 400 {
			utils.Warn("Audit: "+action, auditData)
		} else {
			utils.Info("Audit: "+action, auditData)
		}
	}
}
