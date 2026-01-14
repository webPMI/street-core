package main

import (
	application "backend/app"
	"backend/config"
	"backend/middlewares"
	"backend/pkg/security"
	"backend/routes"
	"backend/utils"
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// Setup configuration and logging
	setupConfig()

	// Connect to MongoDB
	client, db := config.ConnectMongo()
	defer func() {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := client.Disconnect(ctx); err != nil {
			utils.Error("Error disconnecting from MongoDB", map[string]interface{}{
				"error": err.Error(),
			})
		}
	}()

	// Create indexes
	config.CreateIndexes(db)

	// Initialize media config
	config.InitMediaConfig()

	// Create application container with all dependencies
	container := application.NewContainer(db, client, config.Cfg)

	// Start background jobs (media cleanup, processing, etc.)
	bgCtx, bgCancel := context.WithCancel(context.Background())
	defer bgCancel()
	container.StartBackgroundJobs(bgCtx)

	// Initialize CSRF store
	middlewares.InitCSRFStore(db)

	// Setup Gin router
	router := setupRouter(container)

	// Create server with configurable timeouts
	srv := &http.Server{
		Addr:         ":" + config.Cfg.Port,
		Handler:      router,
		ReadTimeout:  config.Cfg.Timeouts.HTTPRead,
		WriteTimeout: config.Cfg.Timeouts.HTTPWrite,
		IdleTimeout:  config.Cfg.Timeouts.HTTPIdle,
	}

	// Start server in goroutine
	go func() {
		utils.Info("Server starting", map[string]interface{}{
			"port":    config.Cfg.Port,
			"env":     config.Cfg.Env,
			"version": config.Cfg.VERSION,
		})

		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			utils.Fatal("Server failed to start", map[string]interface{}{
				"error": err.Error(),
			})
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	utils.Info("Shutting down server...", nil)

	// Stop background jobs
	bgCancel()

	ctx, cancel := context.WithTimeout(context.Background(), config.Cfg.Timeouts.GracefulShutdown)
	defer cancel()

	// Shutdown HTTP server first
	if err := srv.Shutdown(ctx); err != nil {
		utils.Fatal("Server forced to shutdown", map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Wait for background tasks to complete
	utils.Info("Waiting for background tasks to complete...", nil)
	bgTimeout := config.Cfg.Timeouts.BackgroundTask
	if completed := container.WaitForBackgroundTasks(bgTimeout); !completed {
		utils.Warn("Some background tasks did not complete within timeout", map[string]interface{}{
			"timeout": bgTimeout.String(),
		})
	}

	utils.Info("Server exited gracefully", nil)
}

// setupRouter configures the Gin router with all middlewares and routes
func setupRouter(container *application.Container) *gin.Engine {
	// Set Gin mode based on environment
	if config.Cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Recovery middleware
	router.Use(gin.Recovery())

	// Custom middlewares (order matters!)
	// 1. Correlation ID first - needed for all subsequent logging
	router.Use(middlewares.CorrelationIDMiddleware())
	// 2. HTTP Logger - uses correlation ID for tracing
	router.Use(middlewares.HTTPLoggerMiddleware())
	// 3. CORS - handle preflight requests
	router.Use(middlewares.CORSMiddleware())
	// 4. Security headers
	router.Use(middlewares.SecurityHeadersMiddleware())

	// Rate limiting (if enabled)
	if config.Cfg.RateLimit.Enabled {
		router.Use(middlewares.APIRateLimitMiddleware())
	}

	// HTTPS redirect in production
	if config.Cfg.Env == "production" {
		router.Use(middlewares.HTTPSRedirectMiddleware())
	}

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().UTC(),
		})
	})

	// Static file serving for uploads
	router.Static("/uploads", config.Media.UploadDir)

	// Setup application routes
	routes.SetupRouter(router, container)

	return router
}

// setupConfig loads configuration and initializes logging system
func setupConfig() {
	// Load configuration from environment
	if err := config.LoadConfig(); err != nil {
		fmt.Fprintf(os.Stderr, "Error loading configuration: %v\n", err)
		os.Exit(1)
	}

	// Initialize logger with configured level and format
	utils.InitLogger(config.Cfg.LogLevel, config.Cfg.LogFormat)

	// Enable file logging if configured
	if config.Cfg.LogToFile {
		maxAge := time.Duration(config.Cfg.LogMaxAge) * 24 * time.Hour
		if err := utils.EnableFileLogging(config.Cfg.LogFileDir, config.Cfg.LogMaxFileSize, maxAge); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Could not enable file logging: %v\n", err)
		}
	}

	// Load OAuth configuration (optional - doesn't fail if not configured)
	if err := config.LoadOAuthConfig(); err != nil {
		utils.Warn("OAuth configuration could not be loaded", map[string]interface{}{
			"error": err.Error(),
		})
	}

	// Initialize encryption for sensitive data (OAuth tokens, 2FA secrets)
	// SECURITY: This key must be 32 bytes for AES-256 encryption
	if config.Cfg.OAuthEncryptionKey != "" {
		key := []byte(config.Cfg.OAuthEncryptionKey)
		if len(key) >= 32 {
			if err := security.InitEncryption(key[:32]); err != nil {
				utils.Error("Failed to initialize encryption", map[string]interface{}{
					"error": err.Error(),
				})
			} else {
				utils.Info("Encryption initialized successfully", nil)
			}
		} else {
			utils.Warn("OAuth encryption key too short (needs 32 bytes), encryption disabled", nil)
		}
	} else {
		utils.Warn("No OAuth encryption key configured, sensitive data will not be encrypted", nil)
	}

	// Log application startup
	utils.Info("Starting Street Core Backend", map[string]interface{}{
		"version": config.Cfg.APIVERSION,
		"env":     config.Cfg.Env,
	})
}
