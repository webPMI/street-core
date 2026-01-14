package media

import (
	"github.com/gin-gonic/gin"
)

// SecureMediaHeaders adds security headers for media file serving
func SecureMediaHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Prevent MIME type sniffing
		c.Header("X-Content-Type-Options", "nosniff")

		// Prevent clickjacking
		c.Header("X-Frame-Options", "DENY")

		// Prevent referrer leakage
		c.Header("Referrer-Policy", "no-referrer")

		// Content Security Policy for media files
		c.Header("Content-Security-Policy", "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; media-src 'self'; object-src 'none'; script-src 'none'; frame-ancestors 'none'")

		// Prevent caching of sensitive content
		c.Header("Cache-Control", "private, no-cache, no-store, must-revalidate")
		c.Header("Pragma", "no-cache")
		c.Header("Expires", "0")

		c.Next()
	}
}
