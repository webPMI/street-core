package email

import (
	"os"
	"strconv"
)

// Config holds email service configuration
type Config struct {
	SMTPHost     string
	SMTPPort     int
	SMTPUser     string
	SMTPPassword string
	FromEmail    string
	FromName     string
	Provider     string // "smtp" or "sendgrid"
	SendGridKey  string
	AppURL       string // For generating links in emails
}

// NewConfigFromEnv creates email configuration from environment variables
func NewConfigFromEnv() *Config {
	return &Config{
		SMTPHost:     getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:     getEnvInt("SMTP_PORT", 587),
		SMTPUser:     getEnv("SMTP_USER", ""),
		SMTPPassword: getEnv("SMTP_PASSWORD", ""),
		FromEmail:    getEnv("FROM_EMAIL", "noreply@fitriders.com"),
		FromName:     getEnv("FROM_NAME", "FitRiders"),
		Provider:     getEnv("EMAIL_PROVIDER", "smtp"),
		SendGridKey:  getEnv("SENDGRID_API_KEY", ""),
		AppURL:       getEnv("APP_URL", "http://localhost:3000"),
	}
}

// getEnv gets environment variable with default fallback
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvInt gets integer environment variable with default fallback
func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}
