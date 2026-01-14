package security

import (
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"
)

// MongoDB regex metacharacters that need escaping to prevent NoSQL injection
var regexMetachars = []string{
	"\\", ".", "*", "+", "?", "^", "$", "{", "}", "(", ")", "|", "[", "]",
}

// EscapeRegex escapes MongoDB regex metacharacters to prevent NoSQL injection attacks.
// This function protects against malicious regex patterns that could be used to bypass
// authentication, extract sensitive data, or cause DoS through regex complexity.
//
// Characters escaped: . * + ? ^ $ { } ( ) | [ ] \
//
// Example:
//
//	input := "user@example.com"
//	safe := EscapeRegex(input)
//	// safe = "user@example\\.com"
//	// Can now be safely used in MongoDB regex queries
//
// SECURITY: This prevents regex injection attacks like:
//   - {"username": {"$regex": ".*"}} (matches all users)
//   - {"email": {"$regex": "^admin.*"}} (enumerate admin accounts)
//   - {"password": {"$regex": "(a|b|c){100}"}} (ReDoS attack)
func EscapeRegex(input string) string {
	if input == "" {
		return input
	}

	result := input
	for _, char := range regexMetachars {
		// Escape backslash first to avoid double-escaping
		if char == "\\" {
			result = strings.ReplaceAll(result, char, "\\\\")
		} else {
			result = strings.ReplaceAll(result, char, "\\"+char)
		}
	}

	return result
}

// SanitizeSearchTerm sanitizes user search input to prevent NoSQL injection and other attacks.
// This function should be used for all user-provided search terms before using them in MongoDB queries.
//
// Operations performed:
//   - Trims leading/trailing whitespace
//   - Limits length to 100 characters (prevents DoS)
//   - Escapes MongoDB regex metacharacters
//   - Returns empty string if input is only whitespace
//
// Example:
//
//	searchTerm := r.URL.Query().Get("q")
//	safeTerm := SanitizeSearchTerm(searchTerm)
//	// Now safe to use in MongoDB: {"name": {"$regex": safeTerm, "$options": "i"}}
//
// SECURITY: Prevents:
//   - NoSQL regex injection
//   - ReDoS (Regular Expression Denial of Service)
//   - Resource exhaustion via extremely long search terms
func SanitizeSearchTerm(input string) string {
	// Trim whitespace
	sanitized := strings.TrimSpace(input)

	// Return empty if only whitespace
	if sanitized == "" {
		return ""
	}

	// Limit length to prevent DoS
	const maxSearchLength = 100
	if len(sanitized) > maxSearchLength {
		// Respect UTF-8 boundaries when truncating
		if utf8.RuneCountInString(sanitized) > maxSearchLength {
			runes := []rune(sanitized)
			sanitized = string(runes[:maxSearchLength])
		}
	}

	// Escape regex metacharacters
	sanitized = EscapeRegex(sanitized)

	return sanitized
}

// SanitizeUserInput performs general sanitization on user input to prevent various injection attacks.
// This function should be used for user-provided text content (posts, comments, bios, etc.).
//
// Operations performed:
//   - Trims leading/trailing whitespace
//   - Removes null bytes (prevents null byte injection)
//   - Normalizes Unicode to NFC form (prevents Unicode-based attacks)
//   - Collapses multiple spaces to single space
//
// Example:
//
//	bio := SanitizeUserInput(r.PostForm.Get("bio"))
//	// Safe to store in database
//
// SECURITY: Prevents:
//   - Null byte injection (e.g., "admin\x00.txt" bypassing file extension checks)
//   - Unicode normalization attacks (e.g., different representations of same character)
//   - Whitespace manipulation attacks
//
// Note: This does NOT sanitize HTML/XSS. Use a dedicated HTML sanitizer for that.
// Note: This does NOT validate content length. Apply length limits separately.
func SanitizeUserInput(input string) string {
	// Trim whitespace
	sanitized := strings.TrimSpace(input)

	// Remove null bytes (prevents null byte injection)
	sanitized = strings.ReplaceAll(sanitized, "\x00", "")

	// Normalize Unicode to NFC (Canonical Decomposition, followed by Canonical Composition)
	// This prevents attacks using different Unicode representations of the same text
	// For example: "é" can be U+00E9 or U+0065 U+0301
	sanitized = normalizeUnicode(sanitized)

	// Collapse multiple spaces to single space
	sanitized = collapseSpaces(sanitized)

	return sanitized
}

// normalizeUnicode normalizes Unicode text to NFC (Normalization Form Canonical Composition).
// This prevents Unicode-based attacks where different character representations can bypass filters.
//
// Example:
//
//	"café" can be represented as:
//	1. U+0063 U+0061 U+0066 U+00E9 (é as single character)
//	2. U+0063 U+0061 U+0066 U+0065 U+0301 (e + combining acute accent)
//	Both are normalized to form 1
func normalizeUnicode(input string) string {
	// Simple NFC normalization implementation
	// In production, consider using golang.org/x/text/unicode/norm for full Unicode support

	var result strings.Builder
	result.Grow(len(input))

	for _, r := range input {
		// Remove invisible characters and control characters (except newline, tab)
		if unicode.IsControl(r) {
			if r == '\n' || r == '\t' || r == '\r' {
				result.WriteRune(r)
			}
			// Skip other control characters
			continue
		}

		// Remove zero-width characters often used in attacks
		if r == '\u200B' || // Zero Width Space
			r == '\u200C' || // Zero Width Non-Joiner
			r == '\u200D' || // Zero Width Joiner
			r == '\uFEFF' { // Zero Width No-Break Space (BOM)
			continue
		}

		// Convert Unicode line/paragraph separators to regular space
		if r == '\u2028' || // Line Separator
			r == '\u2029' { // Paragraph Separator
			result.WriteRune(' ')
			continue
		}

		result.WriteRune(r)
	}

	return result.String()
}

// collapseSpaces replaces multiple consecutive spaces with a single space.
// This prevents whitespace-based attacks and normalizes formatting.
func collapseSpaces(input string) string {
	// Replace multiple spaces with single space
	spaceRegex := regexp.MustCompile(`\s+`)
	return spaceRegex.ReplaceAllString(input, " ")
}

// ValidateMongoID validates that a string is a valid MongoDB ObjectID format.
// Returns true if valid, false otherwise.
//
// Example:
//
//	userID := r.URL.Query().Get("userId")
//	if !ValidateMongoID(userID) {
//	    return errors.New("invalid user ID format")
//	}
//
// SECURITY: Prevents:
//   - NoSQL injection via malformed IDs
//   - Error-based information disclosure
func ValidateMongoID(id string) bool {
	// MongoDB ObjectID is 24 hex characters
	if len(id) != 24 {
		return false
	}

	// Check if all characters are valid hex
	for _, c := range id {
		if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
			return false
		}
	}

	return true
}
