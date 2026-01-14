package middlewares

import (
	"fmt"
	"strings"
	"time"

	"backend/config"
	"backend/utils"

	"github.com/gin-gonic/gin"
)

// ANSI color codes for terminal output
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorBlue   = "\033[34m"
	colorPurple = "\033[35m"
	colorCyan   = "\033[36m"
	colorWhite  = "\033[37m"
	colorGray   = "\033[90m"

	// Bold variants
	colorBoldRed    = "\033[1;31m"
	colorBoldGreen  = "\033[1;32m"
	colorBoldYellow = "\033[1;33m"
	colorBoldBlue   = "\033[1;34m"
	colorBoldCyan   = "\033[1;36m"
	colorBoldWhite  = "\033[1;37m"
)

// HTTPLoggerMiddleware registra todas las peticiones y respuestas HTTP de forma estructurada.
// IMPORTANT: This middleware should be used AFTER CorrelationIDMiddleware to include
// the correlation ID in all logs for distributed tracing.
func HTTPLoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		rawQuery := c.Request.URL.RawQuery
		method := c.Request.Method
		ip := c.ClientIP()
		userAgent := c.Request.UserAgent()
		origin := c.GetHeader("Origin")
		contentType := c.ContentType()
		requestSize := c.Request.ContentLength

		// Full path with query string
		fullPath := path
		if rawQuery != "" {
			fullPath = path + "?" + rawQuery
		}

		// Get correlation ID (set by CorrelationIDMiddleware)
		correlationID := GetCorrelationID(c)

		// Log de request (nivel DEBUG para no saturar en producción)
		utils.Debug("HTTP Request", map[string]interface{}{
			"correlation_id": correlationID,
			"method":         method,
			"path":           fullPath,
			"ip":             ip,
			"userAgent":      userAgent,
			"origin":         origin,
			"content_type":   contentType,
			"request_size":   requestSize,
		})

		// Procesar request
		c.Next()

		// Calcular latencia
		latency := time.Since(start)
		status := c.Writer.Status()
		responseSize := c.Writer.Size()
		if responseSize < 0 {
			responseSize = 0
		}

		// Get user ID if authenticated
		var userID string
		if uid, exists := c.Get(UserIDKey); exists {
			if uidStr, ok := uid.(string); ok {
				userID = uidStr
			}
		}

		// Development mode: print pretty console output
		if config.Cfg != nil && config.Cfg.Env == "development" {
			printDevLog(method, fullPath, status, latency, ip, userID, requestSize, int64(responseSize), c.Errors.String())
		}

		// Campos comunes para el log de respuesta (siempre incluye correlation_id)
		fields := map[string]interface{}{
			"correlation_id": correlationID,
			"method":         method,
			"path":           fullPath,
			"status":         status,
			"latency_ms":     latency.Milliseconds(),
			"latency":        latency.String(),
			"ip":             ip,
			"request_size":   requestSize,
			"response_size":  responseSize,
		}

		// Add user ID if authenticated
		if userID != "" {
			fields["user_id"] = userID
		}

		// Add errors if any
		if len(c.Errors) > 0 {
			fields["errors"] = c.Errors.String()
		}

		// Log de respuesta según status code
		if status >= 500 {
			utils.Error("HTTP Response - Server Error", fields)
		} else if status >= 400 {
			utils.Warn("HTTP Response - Client Error", fields)
		} else {
			utils.Info("HTTP Response", fields)
		}
	}
}

// printDevLog prints a colorful, easy-to-read log line for development
func printDevLog(method, path string, status int, latency time.Duration, ip, userID string, reqSize, resSize int64, errors string) {
	// Method color
	methodColor := getMethodColor(method)

	// Status color
	statusColor := getStatusColor(status)

	// Latency color (green < 100ms, yellow < 500ms, red >= 500ms)
	latencyColor := colorGreen
	if latency >= 500*time.Millisecond {
		latencyColor = colorRed
	} else if latency >= 100*time.Millisecond {
		latencyColor = colorYellow
	}

	// Format latency
	latencyStr := formatLatency(latency)

	// Format sizes
	reqSizeStr := formatBytesForLog(reqSize)
	resSizeStr := formatBytesForLog(resSize)

	// Method padded to 7 chars
	methodPadded := fmt.Sprintf("%-7s", method)

	// Status with emoji
	statusEmoji := getStatusEmoji(status)

	// User indicator
	userIndicator := ""
	if userID != "" {
		shortUserID := userID
		if len(userID) > 8 {
			shortUserID = userID[:8]
		}
		userIndicator = fmt.Sprintf(" %s👤 %s%s", colorCyan, shortUserID, colorReset)
	}

	// Error indicator
	errorIndicator := ""
	if errors != "" {
		errorIndicator = fmt.Sprintf(" %s⚠ %s%s", colorRed, truncate(errors, 50), colorReset)
	}

	// Print the formatted log
	fmt.Printf("%s│ %s%s%s %s%s%s │ %s%d %s%s │ %s%s%s │ %s↓%s ↑%s%s%s%s\n",
		colorGray,
		methodColor, methodPadded, colorReset,
		colorWhite, truncatePath(path, 50), colorReset,
		statusColor, status, statusEmoji, colorReset,
		latencyColor, latencyStr, colorReset,
		colorGray, reqSizeStr, resSizeStr, colorReset,
		userIndicator,
		errorIndicator,
	)

	// Print separator for errors (5xx)
	if status >= 500 {
		fmt.Printf("%s└── %sERROR: Check logs for details%s\n", colorGray, colorRed, colorReset)
	}
}

// getMethodColor returns the appropriate color for an HTTP method
func getMethodColor(method string) string {
	switch method {
	case "GET":
		return colorBoldBlue
	case "POST":
		return colorBoldGreen
	case "PUT", "PATCH":
		return colorBoldYellow
	case "DELETE":
		return colorBoldRed
	case "OPTIONS":
		return colorGray
	case "HEAD":
		return colorCyan
	default:
		return colorWhite
	}
}

// getStatusColor returns the appropriate color for an HTTP status code
func getStatusColor(status int) string {
	switch {
	case status >= 500:
		return colorBoldRed
	case status >= 400:
		return colorBoldYellow
	case status >= 300:
		return colorCyan
	case status >= 200:
		return colorBoldGreen
	default:
		return colorWhite
	}
}

// getStatusEmoji returns an emoji indicator for the status code
func getStatusEmoji(status int) string {
	switch {
	case status >= 500:
		return " 💥"
	case status >= 400:
		return " ⚠️"
	case status >= 300:
		return " ↪️"
	case status >= 200:
		return " ✓"
	default:
		return ""
	}
}

// formatLatency formats duration in a human-readable way
func formatLatency(d time.Duration) string {
	if d < time.Millisecond {
		return fmt.Sprintf("%6.2fµs", float64(d.Microseconds()))
	} else if d < time.Second {
		return fmt.Sprintf("%6.2fms", float64(d.Microseconds())/1000)
	} else {
		return fmt.Sprintf("%6.2fs ", d.Seconds())
	}
}

// formatBytesForLog formats bytes in a human-readable way for HTTP logging
func formatBytesForLog(bytes int64) string {
	if bytes < 0 {
		return "  0B"
	} else if bytes < 1024 {
		return fmt.Sprintf("%3dB", bytes)
	} else if bytes < 1024*1024 {
		return fmt.Sprintf("%3dK", bytes/1024)
	} else {
		return fmt.Sprintf("%3dM", bytes/(1024*1024))
	}
}

// truncatePath truncates a path to maxLen characters
func truncatePath(path string, maxLen int) string {
	if len(path) <= maxLen {
		return fmt.Sprintf("%-*s", maxLen, path)
	}
	return path[:maxLen-3] + "..."
}

// truncate truncates a string to maxLen characters
func truncate(s string, maxLen int) string {
	// Remove newlines
	s = strings.ReplaceAll(s, "\n", " ")
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen-3] + "..."
}
