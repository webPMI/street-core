package cache

import (
	"time"

	"github.com/gin-gonic/gin"
)

// CacheMiddleware is a simple in-memory cache middleware.
// For now, it's a stub that does nothing but pass through, to satisfy compilation.
// A real implementation would check a store.
func CacheMiddleware(duration time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}
