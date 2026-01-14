package middlewares

import (
	"bytes"
	"encoding/json"
	"io"

	"github.com/gin-gonic/gin"
)

// GlobalSanitizationMiddleware applies input sanitization to all request bodies
// This middleware intercepts JSON requests and sanitizes all string fields
func GlobalSanitizationMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip if not JSON content type
		if c.ContentType() != "application/json" {
			c.Next()
			return
		}

		// Skip GET, DELETE, HEAD, OPTIONS methods (no body)
		if c.Request.Method == "GET" || c.Request.Method == "DELETE" ||
			c.Request.Method == "HEAD" || c.Request.Method == "OPTIONS" {
			c.Next()
			return
		}

		// Read the request body
		bodyBytes, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.Next()
			return
		}

		// Restore the request body for handlers
		c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

		// Try to parse as JSON
		var body map[string]interface{}
		if err := json.Unmarshal(bodyBytes, &body); err != nil {
			// Not valid JSON or not an object, skip sanitization
			c.Next()
			return
		}

		// Sanitize all string fields recursively
		sanitizedBody := sanitizeMap(body)

		// Store sanitized body in context for handlers
		c.Set("sanitized_body", sanitizedBody)

		// Marshal back to JSON and replace request body
		sanitizedBytes, err := json.Marshal(sanitizedBody)
		if err != nil {
			c.Next()
			return
		}

		c.Request.Body = io.NopCloser(bytes.NewBuffer(sanitizedBytes))
		c.Request.ContentLength = int64(len(sanitizedBytes))

		c.Next()
	}
}

// sanitizeMap recursively sanitizes all string values in a map
func sanitizeMap(m map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})

	for key, value := range m {
		switch v := value.(type) {
		case string:
			// Sanitize string values
			result[key] = SanitizeInput(v)
		case map[string]interface{}:
			// Recursively sanitize nested maps
			result[key] = sanitizeMap(v)
		case []interface{}:
			// Recursively sanitize arrays
			result[key] = sanitizeArray(v)
		default:
			// Keep other types as-is
			result[key] = value
		}
	}

	return result
}

// sanitizeArray recursively sanitizes all values in an array
func sanitizeArray(arr []interface{}) []interface{} {
	result := make([]interface{}, len(arr))

	for i, value := range arr {
		switch v := value.(type) {
		case string:
			result[i] = SanitizeInput(v)
		case map[string]interface{}:
			result[i] = sanitizeMap(v)
		case []interface{}:
			result[i] = sanitizeArray(v)
		default:
			result[i] = value
		}
	}

	return result
}
