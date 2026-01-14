package utils

import (
	"crypto/sha256"
	"encoding/hex"
	"strings"
)

// NormalizeEmail normalizes email to lowercase and trims whitespace
// This should be used consistently across the application to ensure
// email uniqueness and case-insensitive lookups
func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

// HashEmailForLogging creates a one-way SHA-256 hash of an email
// Use this for logging instead of the actual email to protect PII
// Returns first 16 characters of hex hash (sufficient for log correlation)
func HashEmailForLogging(email string) string {
	normalizedEmail := NormalizeEmail(email)
	hash := sha256.Sum256([]byte(normalizedEmail))
	fullHash := hex.EncodeToString(hash[:])
	// Return first 16 chars for readability while maintaining uniqueness
	return fullHash[:16]
}

// ValidateEmailFormat performs basic email format validation
// Returns true if email looks valid (contains @ and .)
func ValidateEmailFormat(email string) bool {
	email = strings.TrimSpace(email)
	if len(email) < 3 {
		return false
	}
	atIndex := strings.Index(email, "@")
	if atIndex < 1 {
		return false
	}
	dotIndex := strings.LastIndex(email, ".")
	if dotIndex < atIndex+2 || dotIndex >= len(email)-1 {
		return false
	}
	return true
}
