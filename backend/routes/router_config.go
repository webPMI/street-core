package routes

import (
	application "backend/app"
	"backend/config"
	"backend/middlewares"
	"backend/models"
	"backend/utils"
	"time"

	"github.com/gin-contrib/gzip"
	"github.com/gin-gonic/gin"
)

func SetRouter(container *application.Container) *gin.Engine {
	router := gin.Default()

	// 🔒 SECURITY: Limit request body size to prevent DOS attacks
	// Increased to 512 MB to support video uploads (max video size is 500MB)
	router.MaxMultipartMemory = 512 << 20 // 512 MB

	// 🔒 SECURITY: Add security headers to all responses
	router.Use(middlewares.SecurityHeadersMiddleware())

	// 🔒 SECURITY: Global input sanitization middleware
	router.Use(middlewares.GlobalSanitizationMiddleware())

	// 🚀 PERFORMANCE: Enable gzip compression for responses > 1KB
	router.Use(gzip.Gzip(gzip.DefaultCompression, gzip.WithExcludedExtensions([]string{".png", ".jpg", ".jpeg", ".gif", ".mp4", ".webm"})))

	// 🚀 PERFORMANCE: Request performance monitoring (log slow requests > 1s)
	router.Use(middlewares.PerformanceMonitoringMiddleware(1 * time.Second))

	// 🚀 PERFORMANCE: Memory monitoring (log requests using > 10MB)
	router.Use(middlewares.MemoryMonitoringMiddleware(10 * 1024 * 1024)) // 10 MB threshold

	// 🔒 SECURITY: CORS middleware with environment-aware configuration
	router.Use(middlewares.CORSMiddleware())

	// 🔧 Debug middleware to log OPTIONS requests in development
	if config.Cfg.Env != "production" {
		router.Use(func(c *gin.Context) {
			if c.Request.Method == "OPTIONS" {
				utils.Info("OPTIONS request received", map[string]interface{}{
					"path":   c.Request.URL.Path,
					"origin": c.GetHeader("Origin"),
				})
			}
			c.Next()
		})
	}

	// 🔧 Handle OPTIONS requests and 404s
	router.NoRoute(func(c *gin.Context) {
		if c.Request.Method == "OPTIONS" {
			c.Status(204)
			return
		}
		c.JSON(404, gin.H{
			"status":  "error",
			"message": models.RouteNotFound,
		})
	})

	// 🔒 SECURITY: HTTPS Redirect (production only)
	router.Use(middlewares.HTTPSRedirectMiddleware())
	utils.Info("HTTPS redirect middleware habilitado", map[string]interface{}{
		"activeInProduction": true,
	})

	// 🔒 SECURITY: HSTS Header
	router.Use(middlewares.HSTSMiddleware())
	utils.Info("HSTS middleware habilitado", map[string]interface{}{
		"maxAge": "31536000 segundos",
	})

	// 🔍 LOG: Middleware para registrar todas las solicitudes HTTP
	router.Use(middlewares.HTTPLoggerMiddleware())

	// 4. SERVIR ARCHIVOS ESTÁTICOS (uploads)
	router.Static("/uploads", config.Media.UploadDir)
	//log.Printf("📁 Static files served from: %s", config.Media.UploadDir)

	// 5. REGISTRO CENTRALIZADO DE TODAS LAS RUTAS
	SetupRouter(router, container)

	return router
}
