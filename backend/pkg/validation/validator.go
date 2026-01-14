package validation

import (
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"time"

	"backend/models"

	"github.com/go-playground/validator/v10"
)

var validate *validator.Validate

// Init initializes the validator with custom validation rules
func Init() *validator.Validate {
	validate = validator.New()

	// Register custom validators
	validate.RegisterValidation("year", validateYear)
	validate.RegisterValidation("http_url", validateHTTPURL)

	return validate
}

// GetValidator returns the initialized validator instance
func GetValidator() *validator.Validate {
	if validate == nil {
		return Init()
	}
	return validate
}

// validateYear validates that a string is a valid 4-digit year between 1800 and current year
func validateYear(fl validator.FieldLevel) bool {
	yearStr := fl.Field().String()
	if yearStr == "" {
		return true // Allow empty for optional fields
	}

	year, err := strconv.Atoi(yearStr)
	if err != nil {
		return false
	}

	currentYear := time.Now().Year()
	return year >= 1800 && year <= currentYear
}

// validateHTTPURL validates that a URL uses HTTP or HTTPS scheme
func validateHTTPURL(fl validator.FieldLevel) bool {
	urlStr := fl.Field().String()
	if urlStr == "" {
		return true // Allow empty for optional fields
	}

	u, err := url.Parse(urlStr)
	if err != nil {
		return false
	}

	return u.Scheme == "http" || u.Scheme == "https"
}

// ValidateStruct validates a struct using the configured validator
func ValidateStruct(s interface{}) error {
	v := GetValidator()
	return v.Struct(s)
}

// FormatValidationError formats validation errors into a user-friendly map
func FormatValidationError(err error) map[string]string {
	errors := make(map[string]string)

	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		for _, e := range validationErrors {
			field := strings.ToLower(e.Field())
			errors[field] = formatFieldError(e)
		}
	}

	return errors
}

// formatFieldError converts a single validation error to a user-friendly message
func formatFieldError(e validator.FieldError) string {
	switch e.Tag() {
	case "required":
		return models.RequiredField
	case "email":
		return models.InvalidEmail
	case "url":
		return models.InvalidURL
	case "http_url":
		return models.InvalidHTTPURL
	case "e164":
		return models.InvalidPhoneFormat
	case "latitude":
		return models.InvalidLatitude
	case "longitude":
		return models.InvalidLongitude
	case "min":
		return fmt.Sprintf("min.length.%s", e.Param())
	case "max":
		return fmt.Sprintf("max.length.%s", e.Param())
	case "len":
		return fmt.Sprintf("must.be.length.%s", e.Param())
	case "numeric":
		return models.MustBeNumeric
	case "alphanum":
		return models.MustBeAlphanumeric
	case "year":
		return models.InvalidYear
	default:
		return models.ValidationError
	}
}

// FormatValidationErrors formats multiple validation errors with detailed information
func FormatValidationErrors(err error) []map[string]interface{} {
	var errorsList []map[string]interface{}

	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		for _, e := range validationErrors {
			errorsList = append(errorsList, map[string]interface{}{
				"field":   strings.ToLower(e.Field()),
				"message": formatFieldError(e),
				"tag":     e.Tag(),
				"value":   e.Value(),
			})
		}
	}

	return errorsList
}
