package middlewares

import (
	"backend/config"
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// HTTPSRedirectMiddleware redirects HTTP requests to HTTPS in production
// This middleware should be applied before other middlewares
func HTTPSRedirectMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip redirect in development mode
		if config.Cfg.Env != "production" {
			c.Next()
			return
		}

		// Check if request is already HTTPS
		if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
			// Request is already secure, continue
			c.Next()
			return
		}

		// Redirect HTTP to HTTPS
		host := c.Request.Host
		// Remove port if present (will use default HTTPS port 443)
		if strings.Contains(host, ":") {
			host = strings.Split(host, ":")[0]
		}

		target := "https://" + host + c.Request.URL.RequestURI()
		c.Redirect(http.StatusMovedPermanently, target)
		c.Abort()
	}
}

// HSTSMiddleware adds HTTP Strict Transport Security header
// This tells browsers to only use HTTPS for future requests
// Configuration is pulled from environment variables
func HSTSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		cfg := config.Cfg

		// Only add HSTS header if enabled and for HTTPS requests
		if !cfg.EnableHSTS {
			c.Next()
			return
		}

		if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
			// Build HSTS header value from configuration
			hstsValue := fmt.Sprintf("max-age=%d", cfg.HSTSMaxAge)
			if cfg.HSTSIncludeSubdomains {
				hstsValue += "; includeSubDomains"
			}
			if cfg.HSTSPreload {
				hstsValue += "; preload"
			}
			c.Header("Strict-Transport-Security", hstsValue)
		}
		c.Next()
	}
}
