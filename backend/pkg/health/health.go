package health

import (
	"context"
	"fmt"
	"net/http"
	"runtime"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

// HealthChecker manages health checks for the application
type HealthChecker struct {
	mongoClient *mongo.Client
	redisClient interface{} // You can add Redis client when implemented
	mu          sync.RWMutex
	lastCheck   time.Time
	isHealthy   bool
}

// HealthStatus represents the health status of the application
type HealthStatus struct {
	Status    string            `json:"status"`
	Timestamp string            `json:"timestamp"`
	Checks    map[string]Check  `json:"checks,omitempty"`
}

// Check represents a single health check result
type Check struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
}

// NewHealthChecker creates a new health checker instance
func NewHealthChecker(mongoClient *mongo.Client) *HealthChecker {
	return &HealthChecker{
		mongoClient: mongoClient,
		isHealthy:   false,
		lastCheck:   time.Time{},
	}
}

// LivenessHandler handles liveness probe (is the service running?)
// This should return 200 if the service is alive, even if dependencies are down
func (h *HealthChecker) LivenessHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, HealthStatus{
			Status:    "UP",
			Timestamp: time.Now().UTC().Format(time.RFC3339),
		})
	}
}

// ReadinessHandler handles readiness probe (can the service accept traffic?)
// This should check all dependencies and return 503 if any are unhealthy
func (h *HealthChecker) ReadinessHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		checks := h.performHealthChecks(c.Request.Context())

		status := "UP"
		httpStatus := http.StatusOK

		// Check if any dependency is down
		for _, check := range checks {
			if check.Status != "UP" {
				status = "DOWN"
				httpStatus = http.StatusServiceUnavailable
				break
			}
		}

		c.JSON(httpStatus, HealthStatus{
			Status:    status,
			Timestamp: time.Now().UTC().Format(time.RFC3339),
			Checks:    checks,
		})
	}
}

// performHealthChecks runs all health checks
func (h *HealthChecker) performHealthChecks(ctx context.Context) map[string]Check {
	checks := make(map[string]Check)

	// MongoDB health check (critical)
	checks["mongodb"] = h.checkMongoDB(ctx)

	// System health checks
	checks["disk"] = h.checkDiskSpace()
	checks["memory"] = h.checkMemory()

	// Optional: Redis (uncomment when Redis is added)
	// checks["redis"] = h.checkRedis(ctx)

	return checks
}

// checkMongoDB verifies MongoDB connection
func (h *HealthChecker) checkMongoDB(ctx context.Context) Check {
	if h.mongoClient == nil {
		return Check{
			Status:  "DOWN",
			Message: "MongoDB client not initialized",
		}
	}

	// Create a context with timeout for the ping
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	// Ping MongoDB
	err := h.mongoClient.Ping(pingCtx, readpref.Primary())
	if err != nil {
		return Check{
			Status:  "DOWN",
			Message: fmt.Sprintf("MongoDB ping failed: %v", err),
		}
	}

	return Check{
		Status:  "UP",
		Message: "MongoDB is healthy",
	}
}

// checkRedis verifies Redis connection (implement when Redis is added)
func (h *HealthChecker) checkRedis(ctx context.Context) Check {
	// Redis not implemented in this project yet
	// When Redis is added, implement the ping check here
	if h.redisClient == nil {
		return Check{
			Status:  "UP",
			Message: "Redis not configured (optional)",
		}
	}
	return Check{
		Status:  "UP",
		Message: "Redis check pending implementation",
	}
}

// checkDiskSpace verifies disk space availability
// Alerts if disk usage is above 90%
func (h *HealthChecker) checkDiskSpace() Check {
	// Get disk usage for root partition
	var path string
	if runtime.GOOS == "windows" {
		path = "C:\\"
	} else {
		path = "/"
	}

	usage, err := disk.Usage(path)
	if err != nil {
		return Check{
			Status:  "WARN",
			Message: fmt.Sprintf("Could not check disk space: %v", err),
		}
	}

	// Alert if disk usage is above 90%
	if usage.UsedPercent > 90 {
		return Check{
			Status:  "WARN",
			Message: fmt.Sprintf("Disk usage critical: %.1f%% used (%.2f GB free)", usage.UsedPercent, float64(usage.Free)/(1024*1024*1024)),
		}
	}

	// Warning if above 80%
	if usage.UsedPercent > 80 {
		return Check{
			Status:  "UP",
			Message: fmt.Sprintf("Disk usage high: %.1f%% used (%.2f GB free)", usage.UsedPercent, float64(usage.Free)/(1024*1024*1024)),
		}
	}

	return Check{
		Status:  "UP",
		Message: fmt.Sprintf("Disk space OK: %.1f%% used (%.2f GB free)", usage.UsedPercent, float64(usage.Free)/(1024*1024*1024)),
	}
}

// checkMemory verifies memory usage
// Alerts if memory usage is above 90%
func (h *HealthChecker) checkMemory() Check {
	vmStat, err := mem.VirtualMemory()
	if err != nil {
		return Check{
			Status:  "WARN",
			Message: fmt.Sprintf("Could not check memory: %v", err),
		}
	}

	// Alert if memory usage is above 90%
	if vmStat.UsedPercent > 90 {
		return Check{
			Status:  "WARN",
			Message: fmt.Sprintf("Memory usage critical: %.1f%% used (%.2f GB available)", vmStat.UsedPercent, float64(vmStat.Available)/(1024*1024*1024)),
		}
	}

	// Warning if above 80%
	if vmStat.UsedPercent > 80 {
		return Check{
			Status:  "UP",
			Message: fmt.Sprintf("Memory usage high: %.1f%% used (%.2f GB available)", vmStat.UsedPercent, float64(vmStat.Available)/(1024*1024*1024)),
		}
	}

	return Check{
		Status:  "UP",
		Message: fmt.Sprintf("Memory OK: %.1f%% used (%.2f GB available)", vmStat.UsedPercent, float64(vmStat.Available)/(1024*1024*1024)),
	}
}

// SetupHealthRoutes sets up health check routes
func SetupHealthRoutes(router *gin.Engine, checker *HealthChecker) {
	health := router.Group("/health")
	{
		// Liveness probe - is the service running?
		health.GET("/live", checker.LivenessHandler())

		// Readiness probe - can the service accept traffic?
		health.GET("/ready", checker.ReadinessHandler())
	}
}
