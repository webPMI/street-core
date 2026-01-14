package helpers

import (
	"context"
	"backend/pkg/errors"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ========================
// ObjectID Helpers
// ========================

// StringToObjectID converts a string ID to MongoDB ObjectID
// Returns AppError if conversion fails
func StringToObjectID(id string) (primitive.ObjectID, error) {
	if id == "" {
		return primitive.NilObjectID, errors.ErrInvalidInput("ID cannot be empty")
	}

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return primitive.NilObjectID, errors.ErrInvalidInput("Invalid ObjectID format")
	}

	return objectID, nil
}

// MustStringToObjectID converts string to ObjectID and returns error if it fails
// DEPRECATED: Use StringToObjectID instead for proper error handling
// This function is kept for backward compatibility but should be avoided
func MustStringToObjectID(id string) (primitive.ObjectID, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return primitive.NilObjectID, errors.ErrInvalidInput("Invalid ObjectID: " + id)
	}
	return objectID, nil
}

// ========================
// Context Helpers
// ========================

const (
	// DefaultTimeout is the default timeout for database operations
	DefaultTimeout = 10 * time.Second
	// ShortTimeout for quick operations like counters
	ShortTimeout = 5 * time.Second
	// LongTimeout for complex operations
	LongTimeout = 30 * time.Second
)

// NewContext creates a context with default timeout (10 seconds)
func NewContext() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), DefaultTimeout)
}

// NewContextWithTimeout creates a context with custom timeout
func NewContextWithTimeout(timeout time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), timeout)
}

// NewShortContext creates a context with short timeout (5 seconds)
func NewShortContext() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), ShortTimeout)
}

// NewLongContext creates a context with long timeout (30 seconds)
func NewLongContext() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), LongTimeout)
}

// ========================
// Slice Helpers
// ========================

// Contains checks if a string slice contains a value
func Contains(slice []string, value string) bool {
	for _, item := range slice {
		if item == value {
			return true
		}
	}
	return false
}

// ContainsObjectID checks if an ObjectID slice contains a value
func ContainsObjectID(slice []primitive.ObjectID, value primitive.ObjectID) bool {
	for _, item := range slice {
		if item == value {
			return true
		}
	}
	return false
}

// RemoveDuplicates removes duplicate strings from a slice
func RemoveDuplicates(slice []string) []string {
	seen := make(map[string]bool)
	result := []string{}

	for _, item := range slice {
		if !seen[item] {
			seen[item] = true
			result = append(result, item)
		}
	}

	return result
}

// ========================
// Pointer Helpers
// ========================

// StringPtr returns a pointer to a string
func StringPtr(s string) *string {
	return &s
}

// IntPtr returns a pointer to an int
func IntPtr(i int) *int {
	return &i
}

// BoolPtr returns a pointer to a bool
func BoolPtr(b bool) *bool {
	return &b
}

// TimePtr returns a pointer to a time.Time
func TimePtr(t time.Time) *time.Time {
	return &t
}

// ObjectIDPtr returns a pointer to an ObjectID
func ObjectIDPtr(id primitive.ObjectID) *primitive.ObjectID {
	return &id
}

// ========================
// Validation Helpers
// ========================

// IsValidObjectID checks if a string is a valid ObjectID
func IsValidObjectID(id string) bool {
	_, err := primitive.ObjectIDFromHex(id)
	return err == nil
}

// IsEmptyObjectID checks if an ObjectID is empty/nil
func IsEmptyObjectID(id primitive.ObjectID) bool {
	return id == primitive.NilObjectID || id.IsZero()
}

// ========================
// Map Helpers
// ========================

// MergeMaps merges multiple maps into one
// Later maps override earlier ones for duplicate keys
func MergeMaps(maps ...map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for _, m := range maps {
		for k, v := range m {
			result[k] = v
		}
	}
	return result
}

// CopyMap creates a shallow copy of a map
func CopyMap(original map[string]interface{}) map[string]interface{} {
	copy := make(map[string]interface{}, len(original))
	for k, v := range original {
		copy[k] = v
	}
	return copy
}

// GetStringValue extracts a string value from a map by key
// Returns empty string if key doesn't exist or value is not a string
func GetStringValue(m map[string]interface{}, key string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

// GetBoolValue extracts a bool value from a map by key
// Returns false if key doesn't exist or value is not a bool
func GetBoolValue(m map[string]interface{}, key string) bool {
	if v, ok := m[key]; ok {
		if b, ok := v.(bool); ok {
			return b
		}
	}
	return false
}

// GetIntValue extracts an int value from a map by key
// Returns 0 if key doesn't exist or value is not numeric
func GetIntValue(m map[string]interface{}, key string) int {
	if v, ok := m[key]; ok {
		switch n := v.(type) {
		case int:
			return n
		case int64:
			return int(n)
		case float64:
			return int(n)
		}
	}
	return 0
}

// GetStringSliceValue extracts a string slice from a map by key
// Returns nil if key doesn't exist or value is not a slice
func GetStringSliceValue(m map[string]interface{}, key string) []string {
	if v, ok := m[key]; ok {
		if slice, ok := v.([]interface{}); ok {
			result := make([]string, 0, len(slice))
			for _, item := range slice {
				if s, ok := item.(string); ok {
					result = append(result, s)
				}
			}
			return result
		}
	}
	return nil
}

// ValidateDateFormat checks if a string is a valid RFC3339 date format
// This is used to validate date filters to prevent injection attacks
func ValidateDateFormat(date string) bool {
	if date == "" {
		return false
	}
	// Try RFC3339 (full format with timezone)
	if _, err := time.Parse(time.RFC3339, date); err == nil {
		return true
	}
	// Try date-only format (YYYY-MM-DD)
	if _, err := time.Parse("2006-01-02", date); err == nil {
		return true
	}
	return false
}
