package middlewares

import (
	"backend/config"
	"fmt"

	"github.com/gin-gonic/gin"
)

// SecurityHeadersMiddleware adds comprehensive security headers to all responses
// Implements OWASP best practices and modern browser security features
// Headers are configurable via environment variables for flexibility
func SecurityHeadersMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		cfg := config.Cfg
		isProd := cfg.Env == "production"

		// ==========================================
		// CORE SECURITY HEADERS
		// ==========================================

		// Prevent MIME type sniffing
		// Stops browsers from interpreting files as a different MIME type
		c.Header("X-Content-Type-Options", "nosniff")

		// Prevent clickjacking - configurable via environment
		// Options: DENY (no iframes), SAMEORIGIN (same origin iframes only), ALLOW-FROM
		c.Header("X-Frame-Options", cfg.XFrameOptions)

		// Enable XSS protection (legacy, but still useful for older browsers)
		// Modern browsers rely on CSP, but this provides defense-in-depth
		c.Header("X-XSS-Protection", "1; mode=block")

		// ==========================================
		// CONTENT SECURITY POLICY (CSP)
		// ==========================================
		// Prevents XSS, data injection, and unauthorized resource loading
		// Fully configurable via environment variables
		csp := fmt.Sprintf(
			"default-src %s; connect-src %s; img-src %s; style-src %s; script-src %s",
			cfg.CSPDefaultSrc,
			cfg.CSPConnectSrc,
			cfg.CSPImgSrc,
			cfg.CSPStyleSrc,
			cfg.CSPScriptSrc,
		)
		c.Header("Content-Security-Policy", csp)

		// ==========================================
		// REFERRER POLICY
		// ==========================================
		// Controls how much referrer information is sent with requests
		// Configurable via REFERRER_POLICY environment variable
		c.Header("Referrer-Policy", cfg.ReferrerPolicy)

		// ==========================================
		// PERMISSIONS POLICY (formerly Feature Policy)
		// ==========================================
		// Controls which browser features and APIs can be used
		// Denies access to sensitive features by default
		c.Header("Permissions-Policy", "accelerometer=(), ambient-light-sensor=(), autoplay=(), battery=(), camera=(), cross-origin-isolated=(), display-capture=(), document-domain=(), encrypted-media=(), execution-while-not-rendered=(), execution-while-out-of-viewport=(), fullscreen=(), geolocation=(), gyroscope=(), keyboard-map=(), magnetometer=(), microphone=(), midi=(), navigation-override=(), payment=(), picture-in-picture=(), publickey-credentials-get=(), screen-wake-lock=(), sync-xhr=(), usb=(), web-share=(), xr-spatial-tracking=()")

		// ==========================================
		// PRODUCTION-ONLY SECURITY HEADERS
		// ==========================================
		if isProd {
			// HSTS: Enforce HTTPS connections - configurable via environment
			if cfg.EnableHSTS {
				hstsValue := fmt.Sprintf("max-age=%d", cfg.HSTSMaxAge)
				if cfg.HSTSIncludeSubdomains {
					hstsValue += "; includeSubDomains"
				}
				if cfg.HSTSPreload {
					hstsValue += "; preload"
				}
				c.Header("Strict-Transport-Security", hstsValue)
			}

			// Expect-CT: Certificate Transparency enforcement
			// Ensures SSL/TLS certificates are publicly logged
			// max-age: 86400 seconds (24 hours)
			// enforce: Refuse connections with non-compliant certificates
			c.Header("Expect-CT", "max-age=86400, enforce")

			// Cross-Origin-Embedder-Policy (COEP)
			// Prevents documents from loading cross-origin resources that don't grant permission
			// require-corp: Only load resources with CORP header or CORS
			c.Header("Cross-Origin-Embedder-Policy", "require-corp")

			// Cross-Origin-Opener-Policy (COOP)
			// Isolates browsing context from cross-origin windows
			// same-origin: Only same-origin documents can access this window
			c.Header("Cross-Origin-Opener-Policy", "same-origin")

			// Cross-Origin-Resource-Policy (CORP)
			// Controls which origins can load resources from this server
			// same-origin: Only same-origin requests can load resources
			c.Header("Cross-Origin-Resource-Policy", "same-origin")
		}

		c.Next()
	}
}
