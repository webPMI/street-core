package middlewares

import (
	"backend/config"
	"backend/utils"
	"net/url"
	"strings"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORSMiddleware configures and returns CORS middleware with security best practices
// Configuration is environment-aware:
// - Development: Allows localhost with any port (Flutter Web uses random ports)
// - Production: Strict origin list from ALLOWED_ORIGINS environment variable
func CORSMiddleware() gin.HandlerFunc {
	cfg := config.Cfg
	isProd := cfg.Env == "production"

	// Validate and filter allowed origins
	allowedOrigins := validateAllowedOrigins(cfg.AllowedOrigins, isProd)

	// Configure CORS
	corsConfig := cors.Config{
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With", "X-CSRF-Token"},
		ExposeHeaders:    []string{"Content-Length", "Content-Type", "X-CSRF-Token"},
		AllowCredentials: true,
		MaxAge:           12 * 3600, // 12 hours - reduces preflight requests
	}

	// Environment-specific CORS handling
	if !isProd {
		// Development: Allow any localhost port for Flutter Web development
		corsConfig.AllowOriginFunc = func(origin string) bool {
			return strings.HasPrefix(origin, "http://localhost:") ||
				strings.HasPrefix(origin, "http://127.0.0.1:") ||
				strings.HasPrefix(origin, "http://10.0.2.2:") || // Android emulator
				origin == "http://localhost:3000" ||
				origin == "http://localhost:8080"
		}
		utils.Info("CORS configured for development", map[string]interface{}{
			"mode":    "permissive",
			"pattern": "localhost:* and 127.0.0.1:*",
		})
	} else {
		// Production: Strict origin list
		corsConfig.AllowOrigins = allowedOrigins
		utils.Info("CORS configured for production", map[string]interface{}{
			"mode":           "strict",
			"allowedOrigins": allowedOrigins,
		})
	}

	return cors.New(corsConfig)
}

// validateAllowedOrigins validates and filters allowed origins
// Returns a list of valid origins suitable for the environment
func validateAllowedOrigins(origins []string, isProd bool) []string {
	if len(origins) == 0 {
		// No origins configured - use safe defaults
		if isProd {
			utils.WarnWithTag("Config", "No ALLOWED_ORIGINS configured for production", nil)
			return []string{} // Empty list will block all CORS in production
		}
		// Development defaults
		return []string{
			"http://localhost:3000",
			"http://localhost:8080",
			"http://127.0.0.1:3000",
			"http://127.0.0.1:8080",
			"http://10.0.2.2:3000", // Android emulator
		}
	}

	// Filter and validate each origin
	validOrigins := make([]string, 0, len(origins))
	for _, origin := range origins {
		if validateOrigin(origin, isProd) {
			validOrigins = append(validOrigins, origin)
		} else {
			utils.WarnWithTag("Config", "Skipping invalid origin", map[string]interface{}{
				"origin": origin,
			})
		}
	}

	return validOrigins
}

// validateOrigin validates that an origin is a valid URL and meets security requirements
func validateOrigin(origin string, isProd bool) bool {
	// Parse the URL
	u, err := url.Parse(origin)
	if err != nil {
		utils.WarnWithTag("Config", "Invalid origin URL", map[string]interface{}{
			"origin": origin,
			"error":  err.Error(),
		})
		return false
	}

	// Check if host is empty
	if u.Host == "" {
		utils.WarnWithTag("Config", "Origin missing host", map[string]interface{}{
			"origin": origin,
		})
		return false
	}

	// Reject wildcards (security risk)
	if strings.Contains(origin, "*") {
		utils.WarnWithTag("Config", "Wildcard origins not allowed", map[string]interface{}{
			"origin": origin,
		})
		return false
	}

	// In production, require HTTPS (except localhost for testing)
	if isProd {
		isLocalhost := strings.Contains(u.Host, "localhost") || strings.Contains(u.Host, "127.0.0.1")
		if u.Scheme != "https" && !isLocalhost {
			utils.WarnWithTag("Config", "Production origin must use HTTPS", map[string]interface{}{
				"origin": origin,
			})
			return false
		}
	}

	return true
}
