package middlewares

import (
	"context"
	"runtime"
	"sync"
	"time"

	"backend/utils"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"
)

// PerformanceMetrics holds performance statistics
type PerformanceMetrics struct {
	mu                  sync.RWMutex
	TotalRequests       int64
	SlowRequests        int64
	AverageResponseTime float64
	MaxResponseTime     time.Duration
	MinResponseTime     time.Duration
	requestTimes        []time.Duration
}

var metrics = &PerformanceMetrics{
	requestTimes:    make([]time.Duration, 0, 1000),
	MinResponseTime: time.Hour, // Start with high value
}

// PerformanceMonitoringMiddleware tracks request performance
func PerformanceMonitoringMiddleware(slowThreshold time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method

		// Process request
		c.Next()

		// Calculate latency
		latency := time.Since(start)

		// Update metrics
		metrics.mu.Lock()
		metrics.TotalRequests++
		metrics.requestTimes = append(metrics.requestTimes, latency)

		// Keep only last 1000 requests for average calculation
		if len(metrics.requestTimes) > 1000 {
			metrics.requestTimes = metrics.requestTimes[1:]
		}

		// Update min/max
		if latency > metrics.MaxResponseTime {
			metrics.MaxResponseTime = latency
		}
		if latency < metrics.MinResponseTime {
			metrics.MinResponseTime = latency
		}

		// Calculate average
		var total time.Duration
		for _, t := range metrics.requestTimes {
			total += t
		}
		metrics.AverageResponseTime = float64(total) / float64(len(metrics.requestTimes)) / float64(time.Millisecond)

		// Log slow requests
		if latency > slowThreshold {
			metrics.SlowRequests++
			metrics.mu.Unlock()
			utils.Warn("Solicitud lenta detectada", map[string]interface{}{
				"method":      method,
				"path":        path,
				"latency":     latency.String(),
				"latencyMs":   latency.Milliseconds(),
				"threshold":   slowThreshold.String(),
				"thresholdMs": slowThreshold.Milliseconds(),
				"status":      c.Writer.Status(),
			})
		} else {
			metrics.mu.Unlock()
		}

		// Set response header with timing
		c.Header("X-Response-Time", latency.String())
	}
}

// GetPerformanceMetrics returns current performance statistics
func GetPerformanceMetrics() map[string]interface{} {
	metrics.mu.RLock()
	defer metrics.mu.RUnlock()

	return map[string]interface{}{
		"total_requests":        metrics.TotalRequests,
		"slow_requests":         metrics.SlowRequests,
		"average_response_time": metrics.AverageResponseTime,
		"max_response_time":     metrics.MaxResponseTime.Milliseconds(),
		"min_response_time":     metrics.MinResponseTime.Milliseconds(),
		"slow_request_percent":  calculateSlowPercent(),
	}
}

// calculateSlowPercent calculates the percentage of slow requests
func calculateSlowPercent() float64 {
	if metrics.TotalRequests == 0 {
		return 0
	}
	return (float64(metrics.SlowRequests) / float64(metrics.TotalRequests)) * 100
}

// ResetMetrics clears all performance metrics
func ResetMetrics() {
	metrics.mu.Lock()
	defer metrics.mu.Unlock()

	metrics.TotalRequests = 0
	metrics.SlowRequests = 0
	metrics.AverageResponseTime = 0
	metrics.MaxResponseTime = 0
	metrics.MinResponseTime = time.Hour
	metrics.requestTimes = make([]time.Duration, 0, 1000)
}

// MemoryMonitoringMiddleware logs memory usage for requests
func MemoryMonitoringMiddleware(threshold uint64) gin.HandlerFunc {
	return func(c *gin.Context) {
		var m1 runtime.MemStats
		runtime.ReadMemStats(&m1)

		c.Next()

		var m2 runtime.MemStats
		runtime.ReadMemStats(&m2)

		// Calculate memory allocated during request
		allocated := m2.Alloc - m1.Alloc

		// Log if threshold exceeded
		if allocated > threshold {
			utils.Warn("Alto uso de memoria detectado", map[string]interface{}{
				"method":         c.Request.Method,
				"path":           c.Request.URL.Path,
				"allocatedMB":    float64(allocated) / 1024 / 1024,
				"thresholdMB":    float64(threshold) / 1024 / 1024,
				"allocatedBytes": allocated,
				"thresholdBytes": threshold,
			})
		}

		// Add memory info to response header
		c.Header("X-Memory-Allocated", formatBytes(allocated))
	}
}

// ConnectionPoolMonitoringMiddleware monitors MongoDB connection pool
func ConnectionPoolMonitoringMiddleware(db *mongo.Database) gin.HandlerFunc {
	return func(c *gin.Context) {
		// This is a passive middleware - just adds pool stats to context
		// Actual monitoring happens in the metrics endpoint
		c.Next()
	}
}

// GetConnectionPoolStats returns MongoDB connection pool statistics
func GetConnectionPoolStats(client *mongo.Client) map[string]interface{} {
	if client == nil {
		return map[string]interface{}{
			"status": "not_configured",
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	// Ping to check connection
	err := client.Ping(ctx, nil)
	connected := err == nil

	return map[string]interface{}{
		"connected": connected,
		"status":    getConnectionStatus(connected),
	}
}

// GetMemoryStats returns current memory statistics
func GetMemoryStats() map[string]interface{} {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	return map[string]interface{}{
		"alloc":         formatBytes(m.Alloc),
		"total_alloc":   formatBytes(m.TotalAlloc),
		"sys":           formatBytes(m.Sys),
		"num_gc":        m.NumGC,
		"goroutines":    runtime.NumGoroutine(),
		"alloc_bytes":   m.Alloc,
		"sys_bytes":     m.Sys,
		"heap_alloc":    formatBytes(m.HeapAlloc),
		"heap_sys":      formatBytes(m.HeapSys),
		"heap_idle":     formatBytes(m.HeapIdle),
		"heap_in_use":   formatBytes(m.HeapInuse),
		"heap_released": formatBytes(m.HeapReleased),
		"heap_objects":  m.HeapObjects,
	}
}

// formatBytes converts bytes to human-readable format
func formatBytes(bytes uint64) string {
	const unit = 1024
	if bytes < unit {
		return string(rune(bytes)) + " B"
	}
	div, exp := uint64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return string(rune(bytes/div)) + " " + "KMGTPE"[exp:exp+1] + "iB"
}

// getConnectionStatus returns connection status string
func getConnectionStatus(connected bool) string {
	if connected {
		return "healthy"
	}
	return "disconnected"
}

// QueryTimingMiddleware logs database query timing (to be used in services)
type QueryTimer struct {
	start time.Time
	query string
}

// NewQueryTimer creates a new query timer
func NewQueryTimer(query string) *QueryTimer {
	return &QueryTimer{
		start: time.Now(),
		query: query,
	}
}

// End logs the query execution time if it exceeds threshold
func (qt *QueryTimer) End(threshold time.Duration) {
	elapsed := time.Since(qt.start)
	if elapsed > threshold {
		utils.Warn("Consulta de base de datos lenta", map[string]interface{}{
			"query":       qt.query,
			"duration":    elapsed.String(),
			"durationMs":  elapsed.Milliseconds(),
			"threshold":   threshold.String(),
			"thresholdMs": threshold.Milliseconds(),
		})
	}
}

// LogSlowQuery logs a slow database query
func LogSlowQuery(query string, duration time.Duration, threshold time.Duration) {
	if duration > threshold {
		utils.Warn("Consulta de base de datos lenta", map[string]interface{}{
			"query":       query,
			"duration":    duration.String(),
			"durationMs":  duration.Milliseconds(),
			"threshold":   threshold.String(),
			"thresholdMs": threshold.Milliseconds(),
		})
	}
}
