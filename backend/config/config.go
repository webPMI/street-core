package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

// PaymentProviderConfig contains configuration for payment providers (Stripe, PayPal)
// When no valid keys are configured, payments are disabled gracefully.
type PaymentProviderConfig struct {
	// Stripe Configuration
	StripeEnabled        bool
	StripeSecretKey      string
	StripePublishableKey string
	StripeWebhookSecret  string
	// PayPal Configuration
	PayPalEnabled      bool
	PayPalClientID     string
	PayPalClientSecret string
	PayPalMode         string // "sandbox" or "live"
	// Computed: at least one provider is available
	AnyProviderEnabled bool
}

// Config representa la configuración de toda la aplicación,
// cargada desde variables de entorno.
type Config struct {
	// General
	VERSION    string
	Env        string
	APIVERSION string
	// Servidor
	Port    string
	BaseURL string // Base URL for the application (used for generating URLs)
	// JWT
	JWTSecret            string
	JWTExpiresIn         time.Duration // Access token expiration
	RefreshTokenExpireIn time.Duration // Refresh token expiration
	// Base de Datos
	MongoURI string
	DBName   string
	// Credenciales del usuario de la aplicación (creado en docker-init)
	DBUser     string
	DBPassword string
	// OAuth Configuration
	GoogleClientID        string
	GoogleClientSecret    string
	GoogleRedirectURI     string
	FacebookAppID         string
	FacebookAppSecret     string
	FacebookRedirectURI   string
	OAuthEncryptionKey    string
	OAuthStateExpiry      int
	OAuthAllowedRedirects []string
	// 2FA Encryption (uses same key as OAuth or dedicated key)
	TwoFactorEncryptionKey string
	// CORS
	AllowedOrigins []string
	// Security Headers
	EnableHSTS          bool   // Enable HTTP Strict Transport Security
	HSTSMaxAge          int    // HSTS max-age in seconds (default: 31536000 = 1 year)
	HSTSIncludeSubdomains bool // Include subdomains in HSTS
	HSTSPreload         bool   // Allow HSTS preload
	CSPDefaultSrc       string // Content-Security-Policy default-src directive
	CSPConnectSrc       string // Content-Security-Policy connect-src directive
	CSPImgSrc           string // Content-Security-Policy img-src directive
	CSPStyleSrc         string // Content-Security-Policy style-src directive
	CSPScriptSrc        string // Content-Security-Policy script-src directive
	XFrameOptions       string // X-Frame-Options header (DENY, SAMEORIGIN, ALLOW-FROM)
	ReferrerPolicy      string // Referrer-Policy header
	// Logging
	LogLevel       string
	LogFormat      string
	LogToFile      bool   // Habilitar logging a archivos
	LogFileDir     string // Directorio para archivos de log
	LogMaxFileSize int64  // Tamaño máximo de archivo en MB
	LogMaxAge      int    // Días de retención de logs
	LogToMongo     bool   // Habilitar logging a MongoDB
	LogMongoTTL    int    // TTL en días para logs en MongoDB
	// Admin Bootstrap
	AdminEmail    string
	AdminPassword string
	AdminRole     string
	AdminNickname string
	// Payment Providers Configuration
	Payment PaymentProviderConfig
	// Rate Limiting
	RateLimit RateLimitConfig
	// Timeouts
	Timeouts TimeoutConfig
	// Testing & Development
	TestingMode bool // Enable testing features (routes, endpoints, utilities)
	DebugMode   bool // Enable verbose logging and debug endpoints
}

// RateLimitConfig holds rate limiting configuration
type RateLimitConfig struct {
	Enabled             bool          // Enable/disable rate limiting globally
	GeneralRate         int           // General API limit (requests per hour)
	GeneralWindow       time.Duration // General API window
	AuthRate            int           // Authentication limit (requests per minute)
	AuthWindow          time.Duration // Authentication window
	PasswordResetRate   int           // Password reset limit (requests per time window)
	PasswordResetWindow time.Duration // Password reset window
	FileUploadRate      int           // File upload limit (requests per minute)
	FileUploadWindow    time.Duration // File upload window
	UseRedis            bool          // Use Redis for distributed rate limiting
	RedisAddr           string        // Redis address (if UseRedis is true)
	RedisPassword       string        // Redis password
	RedisDB             int           // Redis database number
}

// TimeoutConfig holds configurable timeout values for various operations.
// This allows adjusting timeouts without code changes.
type TimeoutConfig struct {
	// MongoDB operation timeouts
	MongoConnect    time.Duration // Connection timeout (default: 10s)
	MongoOperation  time.Duration // Standard operation timeout (default: 30s)
	MongoIndex      time.Duration // Index creation timeout (default: 60s)

	// HTTP timeouts
	HTTPClient      time.Duration // HTTP client timeout for external calls (default: 30s)
	HTTPRead        time.Duration // HTTP server read timeout (default: 15s)
	HTTPWrite       time.Duration // HTTP server write timeout (default: 15s)
	HTTPIdle        time.Duration // HTTP server idle timeout (default: 60s)

	// Background operation timeouts
	BackgroundTask  time.Duration // Background task timeout (default: 30s)
	GracefulShutdown time.Duration // Graceful shutdown timeout (default: 30s)
}

// Cfg es la instancia global de la configuración.
var Cfg *Config

// LoadConfig carga las variables de entorno y las mapea al struct Config.
// NOTA: El logger aún NO está inicializado en esta función, se usa después.
func LoadConfig() error {
	// 1. Cargar archivo .env desde el directorio raíz
	envPath := "../.env"
	if err := godotenv.Load(envPath); err != nil {
		// No usar logger aquí, aún no está inicializado
		fmt.Println("⚠️  Advertencia: No se encontró archivo .env")
		fmt.Println("   Leyendo solo variables de entorno del sistema operativo.")
	} else {
		fmt.Println("✅ Archivo .env cargado correctamente")
	}

	// 2. Inicializar configuración
	Cfg = &Config{}

	// 3. Cargar variables de entorno
	Cfg.Env = getEnv("ENV", "development")
	Cfg.Port = getEnv("PORT", "3000")
	Cfg.BaseURL = getEnv("BASE_URL", "") // Optional: used for generating full URLs
	Cfg.APIVERSION = getEnv("API_VERSION", "0.1")
	Cfg.VERSION = getEnv("VERSION", "0.1")
	// JWT Configuration
	Cfg.JWTSecret = getEnv("JWT_SECRET", "")
	if Cfg.JWTSecret == "" || strings.Contains(Cfg.JWTSecret, "INVALID") {
		return fmt.Errorf("JWT_SECRET es requerido y debe ser generado con: openssl rand -hex 32")
	}

	jwtExpHours := getEnvAsInt("JWT_EXP_HOURS", 1)
	Cfg.JWTExpiresIn = time.Duration(jwtExpHours) * time.Hour

	refreshExpDays := getEnvAsInt("REFRESH_TOKEN_EXP_DAYS", 7)
	Cfg.RefreshTokenExpireIn = time.Duration(refreshExpDays) * 24 * time.Hour

	// MongoDB Configuration
	Cfg.MongoURI = getEnv("MONGO_URI", "")
	if Cfg.MongoURI == "" || strings.Contains(Cfg.MongoURI, "INVALID") {
		return fmt.Errorf("MONGO_URI es requerido")
	}
	Cfg.DBName = getEnv("DB_NAME", "fitriders")
	Cfg.DBUser = getEnv("DB_APP_USER", "")
	Cfg.DBPassword = getEnv("DB_APP_PASS", "")

	// OAuth Configuration
	Cfg.GoogleClientID = getEnv("GOOGLE_CLIENT_ID", "")
	Cfg.GoogleClientSecret = getEnv("GOOGLE_CLIENT_SECRET", "")
	Cfg.GoogleRedirectURI = getEnv("GOOGLE_REDIRECT_URI", "")
	Cfg.FacebookAppID = getEnv("FACEBOOK_APP_ID", "")
	Cfg.FacebookAppSecret = getEnv("FACEBOOK_APP_SECRET", "")
	Cfg.FacebookRedirectURI = getEnv("FACEBOOK_REDIRECT_URI", "")
	Cfg.OAuthEncryptionKey = getEnv("OAUTH_ENCRYPTION_KEY", "")
	Cfg.OAuthStateExpiry = getEnvAsInt("OAUTH_STATE_EXPIRY", 10)
	Cfg.OAuthAllowedRedirects = getEnvAsSlice("OAUTH_ALLOWED_REDIRECTS", []string{}, ",")
	// 2FA encryption key - fallback to OAuth key if not provided separately
	Cfg.TwoFactorEncryptionKey = getEnv("TWO_FACTOR_ENCRYPTION_KEY", Cfg.OAuthEncryptionKey)

	// CORS Configuration
	Cfg.AllowedOrigins = getEnvAsSlice("ALLOWED_ORIGINS", []string{"http://localhost:3000"}, ",")

	// Security Headers Configuration
	Cfg.EnableHSTS = getEnvAsBool("ENABLE_HSTS", true)
	Cfg.HSTSMaxAge = getEnvAsInt("HSTS_MAX_AGE", 31536000) // 1 year default
	Cfg.HSTSIncludeSubdomains = getEnvAsBool("HSTS_INCLUDE_SUBDOMAINS", true)
	Cfg.HSTSPreload = getEnvAsBool("HSTS_PRELOAD", true)

	// CSP Configuration - defaults are production-ready but configurable
	if Cfg.Env == "production" {
		Cfg.CSPDefaultSrc = getEnv("CSP_DEFAULT_SRC", "'self'")
		Cfg.CSPConnectSrc = getEnv("CSP_CONNECT_SRC", "'self' https:")
		Cfg.CSPImgSrc = getEnv("CSP_IMG_SRC", "'self' data: https:")
		Cfg.CSPStyleSrc = getEnv("CSP_STYLE_SRC", "'self' 'unsafe-inline'")
		Cfg.CSPScriptSrc = getEnv("CSP_SCRIPT_SRC", "'self' 'unsafe-inline'")
	} else {
		// Development: More permissive defaults
		Cfg.CSPDefaultSrc = getEnv("CSP_DEFAULT_SRC", "'self' 'unsafe-inline' 'unsafe-eval'")
		Cfg.CSPConnectSrc = getEnv("CSP_CONNECT_SRC", "*")
		Cfg.CSPImgSrc = getEnv("CSP_IMG_SRC", "* data:")
		Cfg.CSPStyleSrc = getEnv("CSP_STYLE_SRC", "* 'unsafe-inline'")
		Cfg.CSPScriptSrc = getEnv("CSP_SCRIPT_SRC", "* 'unsafe-inline' 'unsafe-eval'")
	}

	Cfg.XFrameOptions = getEnv("X_FRAME_OPTIONS", "SAMEORIGIN") // DENY, SAMEORIGIN, or ALLOW-FROM
	Cfg.ReferrerPolicy = getEnv("REFERRER_POLICY", "strict-origin-when-cross-origin")

	// Logging Configuration
	Cfg.LogLevel = getEnv("LOG_LEVEL", "info")
	Cfg.LogFormat = getEnv("LOG_FORMAT", "pretty")
	Cfg.LogToFile = getEnvAsBool("LOG_TO_FILE", false)
	Cfg.LogFileDir = getEnv("LOG_FILE_DIR", "./logs")
	Cfg.LogMaxFileSize = int64(getEnvAsInt("LOG_MAX_FILE_SIZE_MB", 10)) * 1024 * 1024 // Convertir MB a bytes
	Cfg.LogMaxAge = getEnvAsInt("LOG_MAX_AGE_DAYS", 7)
	Cfg.LogToMongo = getEnvAsBool("LOG_TO_MONGO", true)     // Habilitado por defecto
	Cfg.LogMongoTTL = getEnvAsInt("LOG_MONGO_TTL_DAYS", 30) // 30 días por defecto

	// Admin Bootstrap (optional)
	Cfg.AdminEmail = getEnv("ADMIN_EMAIL", "")
	Cfg.AdminPassword = getEnv("ADMIN_PASSWORD", "")
	Cfg.AdminRole = getEnv("ADMIN_ROLE", "admin")
	Cfg.AdminNickname = getEnv("ADMIN_NICKNAME", "Administrator")

	// Payment Providers Configuration (optional - graceful degradation)
	Cfg.Payment = loadPaymentConfig()

	// Rate Limiting Configuration
	Cfg.RateLimit = loadRateLimitConfig()

	// Timeout Configuration
	Cfg.Timeouts = loadTimeoutConfig()

	// Testing & Development Modes
	Cfg.TestingMode = getEnvAsBool("TESTING_MODE", true)
	Cfg.DebugMode = Cfg.Env == "development"

	// Disable testing mode in production
	if Cfg.Env == "production" {
		Cfg.TestingMode = false
		if Cfg.LogFormat != "json" {
			fmt.Println("⚠️  Advertencia: LOG_FORMAT debería ser 'json' en producción")
		}
	}

	// 4. Log configuration summary (sin logger, se hará después de inicializarlo)
	fmt.Printf("🚀 Configuración cargada - Entorno: %s, Puerto: %s\n", Cfg.Env, Cfg.Port)
	fmt.Printf("📊 Testing Mode: %v, Debug Mode: %v\n", Cfg.TestingMode, Cfg.DebugMode)

	// 5. Initialize Media Configuration
	InitMediaConfig()

	// 6. Load Feature Flags
	LoadFeatureFlags()

	// 7. Load Agora Configuration
	LoadAgoraConfig()

	return nil
}

// Utility functions for environment variable parsing

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

func getEnvAsInt(key string, defaultValue int) int {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}
	value, err := strconv.Atoi(valueStr)
	if err != nil {
		fmt.Printf("⚠️  Advertencia: %s no es un número válido, usando valor por defecto: %d\n", key, defaultValue)
		return defaultValue
	}
	return value
}

func getEnvAsBool(key string, defaultValue bool) bool {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}
	value, err := strconv.ParseBool(valueStr)
	if err != nil {
		fmt.Printf("⚠️  Advertencia: %s no es un booleano válido, usando valor por defecto: %v\n", key, defaultValue)
		return defaultValue
	}
	return value
}

func getEnvAsSlice(key string, defaultValue []string, separator string) []string {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}
	return strings.Split(valueStr, separator)
}

// loadPaymentConfig loads and validates payment provider configuration.
// Returns a PaymentProviderConfig with enabled flags based on valid credentials.
// This allows the system to gracefully degrade when payment keys are missing.
func loadPaymentConfig() PaymentProviderConfig {
	cfg := PaymentProviderConfig{}

	// Load Stripe Configuration
	cfg.StripeSecretKey = getEnv("STRIPE_SECRET_KEY", "")
	cfg.StripePublishableKey = getEnv("STRIPE_PUBLISHABLE_KEY", "")
	cfg.StripeWebhookSecret = getEnv("STRIPE_WEBHOOK_SECRET", "")

	// Stripe is enabled only if secret key is valid (not empty, not placeholder)
	cfg.StripeEnabled = isValidPaymentKey(cfg.StripeSecretKey)

	// Load PayPal Configuration
	cfg.PayPalClientID = getEnv("PAYPAL_CLIENT_ID", "")
	cfg.PayPalClientSecret = getEnv("PAYPAL_CLIENT_SECRET", "")
	cfg.PayPalMode = getEnv("PAYPAL_MODE", "sandbox") // sandbox or live

	// PayPal is enabled only if both client ID and secret are valid
	cfg.PayPalEnabled = isValidPaymentKey(cfg.PayPalClientID) && isValidPaymentKey(cfg.PayPalClientSecret)

	// At least one provider available
	cfg.AnyProviderEnabled = cfg.StripeEnabled || cfg.PayPalEnabled

	// Log payment configuration status
	if cfg.AnyProviderEnabled {
		if cfg.StripeEnabled {
			fmt.Println("💳 Stripe: habilitado")
		}
		if cfg.PayPalEnabled {
			fmt.Printf("💳 PayPal: habilitado (%s)\n", cfg.PayPalMode)
		}
	} else {
		fmt.Println("💳 Pagos: deshabilitados (no hay proveedores configurados)")
		fmt.Println("   Para habilitar pagos, configura STRIPE_SECRET_KEY o PAYPAL_CLIENT_ID/SECRET en .env")
	}

	return cfg
}

// isValidPaymentKey checks if a payment key is valid (not empty and not a placeholder).
func isValidPaymentKey(key string) bool {
	if key == "" {
		return false
	}
	// Filter out common placeholder values
	placeholders := []string{"INVALID", "YOUR_", "REPLACE_", "xxx", "placeholder"}
	keyLower := strings.ToLower(key)
	for _, p := range placeholders {
		if strings.Contains(keyLower, strings.ToLower(p)) {
			return false
		}
	}
	return true
}

// loadRateLimitConfig loads and validates rate limiting configuration.
// Returns a RateLimitConfig with defaults suitable for production use.
func loadRateLimitConfig() RateLimitConfig {
	cfg := RateLimitConfig{}

	// Global enable/disable
	cfg.Enabled = getEnvAsBool("RATE_LIMIT_ENABLED", true)

	// General API limits (default: 1000 requests/hour)
	cfg.GeneralRate = getEnvAsInt("RATE_LIMIT_GENERAL_RATE", 1000)
	generalWindowMin := getEnvAsInt("RATE_LIMIT_GENERAL_WINDOW_MINUTES", 60)
	cfg.GeneralWindow = time.Duration(generalWindowMin) * time.Minute

	// Authentication limits (default: 10 requests/minute)
	cfg.AuthRate = getEnvAsInt("RATE_LIMIT_AUTH_RATE", 10)
	authWindowMin := getEnvAsInt("RATE_LIMIT_AUTH_WINDOW_MINUTES", 1)
	cfg.AuthWindow = time.Duration(authWindowMin) * time.Minute

	// Password reset limits (default: 3 requests/5 minutes)
	cfg.PasswordResetRate = getEnvAsInt("RATE_LIMIT_PASSWORD_RESET_RATE", 3)
	passwordResetWindowMin := getEnvAsInt("RATE_LIMIT_PASSWORD_RESET_WINDOW_MINUTES", 5)
	cfg.PasswordResetWindow = time.Duration(passwordResetWindowMin) * time.Minute

	// File upload limits (default: 10 requests/minute)
	cfg.FileUploadRate = getEnvAsInt("RATE_LIMIT_FILE_UPLOAD_RATE", 10)
	fileUploadWindowMin := getEnvAsInt("RATE_LIMIT_FILE_UPLOAD_WINDOW_MINUTES", 1)
	cfg.FileUploadWindow = time.Duration(fileUploadWindowMin) * time.Minute

	// Redis configuration (optional - for distributed systems)
	cfg.UseRedis = getEnvAsBool("RATE_LIMIT_USE_REDIS", false)
	cfg.RedisAddr = getEnv("RATE_LIMIT_REDIS_ADDR", "localhost:6379")
	cfg.RedisPassword = getEnv("RATE_LIMIT_REDIS_PASSWORD", "")
	cfg.RedisDB = getEnvAsInt("RATE_LIMIT_REDIS_DB", 0)

	// Log rate limiting configuration
	if cfg.Enabled {
		fmt.Println("🛡️  Rate Limiting: habilitado")
		fmt.Printf("   - General API: %d requests/%d min\n", cfg.GeneralRate, int(cfg.GeneralWindow.Minutes()))
		fmt.Printf("   - Autenticación: %d requests/%d min\n", cfg.AuthRate, int(cfg.AuthWindow.Minutes()))
		fmt.Printf("   - Password Reset: %d requests/%d min\n", cfg.PasswordResetRate, int(cfg.PasswordResetWindow.Minutes()))
		fmt.Printf("   - File Upload: %d requests/%d min\n", cfg.FileUploadRate, int(cfg.FileUploadWindow.Minutes()))
		if cfg.UseRedis {
			fmt.Printf("   - Storage: Redis (%s)\n", cfg.RedisAddr)
		} else {
			fmt.Println("   - Storage: MongoDB (fallback: in-memory)")
		}
	} else {
		fmt.Println("🛡️  Rate Limiting: deshabilitado")
		fmt.Println("   ⚠️  ADVERTENCIA: Rate limiting está deshabilitado. Se recomienda habilitarlo en producción.")
	}

	return cfg
}

// loadTimeoutConfig loads timeout configuration from environment variables.
// All timeouts have sensible defaults that can be overridden.
func loadTimeoutConfig() TimeoutConfig {
	cfg := TimeoutConfig{}

	// MongoDB timeouts
	cfg.MongoConnect = time.Duration(getEnvAsInt("TIMEOUT_MONGO_CONNECT_SECONDS", 10)) * time.Second
	cfg.MongoOperation = time.Duration(getEnvAsInt("TIMEOUT_MONGO_OPERATION_SECONDS", 30)) * time.Second
	cfg.MongoIndex = time.Duration(getEnvAsInt("TIMEOUT_MONGO_INDEX_SECONDS", 60)) * time.Second

	// HTTP timeouts
	cfg.HTTPClient = time.Duration(getEnvAsInt("TIMEOUT_HTTP_CLIENT_SECONDS", 30)) * time.Second
	cfg.HTTPRead = time.Duration(getEnvAsInt("TIMEOUT_HTTP_READ_SECONDS", 15)) * time.Second
	cfg.HTTPWrite = time.Duration(getEnvAsInt("TIMEOUT_HTTP_WRITE_SECONDS", 15)) * time.Second
	cfg.HTTPIdle = time.Duration(getEnvAsInt("TIMEOUT_HTTP_IDLE_SECONDS", 60)) * time.Second

	// Background operation timeouts
	cfg.BackgroundTask = time.Duration(getEnvAsInt("TIMEOUT_BACKGROUND_TASK_SECONDS", 30)) * time.Second
	cfg.GracefulShutdown = time.Duration(getEnvAsInt("TIMEOUT_GRACEFUL_SHUTDOWN_SECONDS", 30)) * time.Second

	return cfg
}
