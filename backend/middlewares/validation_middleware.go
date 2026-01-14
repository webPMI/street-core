package middlewares

import (
	"fmt"
	"html"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/microcosm-cc/bluemonday"
)

// ValidationError represents a single validation error
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// ValidateStruct validates a struct and returns formatted errors
func ValidateStruct(data interface{}) []ValidationError {
	validate := validator.New()
	var validationErrors []ValidationError

	err := validate.Struct(data)
	if err != nil {
		// Check if it's validation errors
		if validationErr, ok := err.(validator.ValidationErrors); ok {
			for _, fieldErr := range validationErr {
				validationErrors = append(validationErrors, ValidationError{
					Field:   fieldErr.Field(),
					Message: getErrorMessage(fieldErr),
				})
			}
		}
	}

	return validationErrors
}

// getErrorMessage converts validator error to user-friendly message
func getErrorMessage(fieldErr validator.FieldError) string {
	field := fieldErr.Field()
	tag := fieldErr.Tag()

	switch tag {
	case "required":
		return fmt.Sprintf("El campo '%s' es obligatorio", field)
	case "email":
		return fmt.Sprintf("El campo '%s' debe ser un email válido", field)
	case "min":
		return fmt.Sprintf("El campo '%s' debe tener al menos %s caracteres", field, fieldErr.Param())
	case "max":
		return fmt.Sprintf("El campo '%s' no debe exceder %s caracteres", field, fieldErr.Param())
	case "oneof":
		return fmt.Sprintf("El campo '%s' debe ser uno de: %s", field, fieldErr.Param())
	case "gte":
		return fmt.Sprintf("El campo '%s' debe ser mayor o igual a %s", field, fieldErr.Param())
	case "lte":
		return fmt.Sprintf("El campo '%s' debe ser menor o igual a %s", field, fieldErr.Param())
	case "alphanum":
		return fmt.Sprintf("El campo '%s' solo puede contener letras y números", field)
	case "url":
		return fmt.Sprintf("El campo '%s' debe ser una URL válida", field)
	default:
		return fmt.Sprintf("El campo '%s' no es válido", field)
	}
}

// ValidationMiddleware creates a middleware for automatic request validation
// Usage: router.POST("/endpoint", ValidationMiddleware(&YourStruct{}), YourHandler)
func ValidationMiddleware(structType interface{}) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Bind JSON to struct
		if err := c.ShouldBindJSON(structType); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Datos de entrada inválidos",
				"message": "La solicitud contiene datos mal formados o incompletos",
				"details": err.Error(),
			})
			c.Abort()
			return
		}

		// Validate struct
		if validationErrors := ValidateStruct(structType); len(validationErrors) > 0 {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Validación fallida",
				"message": "Los datos proporcionados no cumplen con los requisitos",
				"errors":  validationErrors,
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// SanitizeInput removes potentially dangerous characters from input strings
// SECURITY FIX: Added HTML entity escaping to prevent XSS attacks
func SanitizeInput(input string) string {
	// Escape HTML entities to prevent XSS (e.g., < becomes &lt;)
	input = html.EscapeString(input)

	// Remove null bytes
	input = strings.ReplaceAll(input, "\x00", "")

	// Trim whitespace
	input = strings.TrimSpace(input)

	return input
}

// SanitizeHTML removes potentially dangerous HTML/XSS from user-generated content
// Uses bluemonday's UGC (User Generated Content) policy which allows safe HTML tags
func SanitizeHTML(input string) string {
	// Create a UGC policy that allows common safe HTML tags
	policy := bluemonday.UGCPolicy()

	// Sanitize the input
	sanitized := policy.Sanitize(input)

	// Remove null bytes and trim whitespace
	sanitized = strings.ReplaceAll(sanitized, "\x00", "")
	sanitized = strings.TrimSpace(sanitized)

	return sanitized
}

// SanitizeStrictText removes ALL HTML tags and potentially dangerous content
// Use this for fields that should contain plain text only (like chat messages)
func SanitizeStrictText(input string) string {
	// Use StrictPolicy which strips all HTML
	policy := bluemonday.StrictPolicy()

	// Sanitize the input
	sanitized := policy.Sanitize(input)

	// Remove null bytes and trim whitespace
	sanitized = strings.ReplaceAll(sanitized, "\x00", "")
	sanitized = strings.TrimSpace(sanitized)

	return sanitized
}

// Common weak passwords that should be rejected
var commonWeakPasswords = map[string]bool{
	"password":     true,
	"12345678":     true,
	"password123":  true,
	"admin123":     true,
	"qwerty123":    true,
	"letmein":      true,
	"welcome":      true,
	"monkey":       true,
	"dragon":       true,
	"master":       true,
	"sunshine":     true,
	"princess":     true,
	"football":     true,
	"iloveyou":     true,
	"123456789":    true,
	"password1":    true,
	"abc123":       true,
	"qwerty":       true,
	"12345":        true,
	"password1234": true,
}

// ValidatePasswordStrength checks if password meets minimum security requirements
func ValidatePasswordStrength(password string) []string {
	var errors []string

	// SECURITY: Removed debug logging to prevent password disclosure in logs

	// Check minimum length
	if len(password) < 8 {
		errors = append(errors, "La contraseña debe tener al menos 8 caracteres")
	}

	// Check maximum length (prevent DoS on bcrypt)
	if len(password) > 128 {
		errors = append(errors, "La contraseña no debe exceder 128 caracteres")
	}

	// Check for common weak passwords
	lowerPassword := strings.ToLower(password)
	if commonWeakPasswords[lowerPassword] {
		errors = append(errors, "Esta contraseña es demasiado común y fácil de adivinar")
	}

	// Check character complexity
	hasUpper := false
	hasLower := false
	hasDigit := false
	hasSpecial := false

	for _, char := range password {
		switch {
		case 'A' <= char && char <= 'Z':
			hasUpper = true
		case 'a' <= char && char <= 'z':
			hasLower = true
		case '0' <= char && char <= '9':
			hasDigit = true
		case strings.ContainsRune("!@#$%^&*()_+-=[]{}|;:,.<>?", char):
			hasSpecial = true
		}
	}

	if !hasUpper {
		errors = append(errors, "La contraseña debe contener al menos una letra mayúscula")
	}
	if !hasLower {
		errors = append(errors, "La contraseña debe contener al menos una letra minúscula")
	}
	if !hasDigit {
		errors = append(errors, "La contraseña debe contener al menos un número")
	}
	if !hasSpecial {
		errors = append(errors, "La contraseña debe contener al menos un carácter especial")
	}

	return errors
}
