package utils

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
)

// 🔒 SECURITY: PKCE (Proof Key for Code Exchange) Implementation
// RFC 7636: https://tools.ietf.org/html/rfc7636
//
// PKCE protects against authorization code interception attacks
// Required for OAuth 2.1 and recommended for all OAuth 2.0 flows
//
// Flow:
// 1. Client generates code_verifier (43-128 chars, random)
// 2. Client calculates code_challenge = SHA256(code_verifier)
// 3. Client sends code_challenge in authorization request
// 4. Server returns authorization code
// 5. Client sends code + code_verifier in token request
// 6. Server verifies SHA256(code_verifier) == code_challenge

// GenerateCodeVerifier generates a cryptographically secure PKCE code verifier
// Returns a 43-character base64url-encoded random string
//
// RFC 7636 Requirements:
// - Length: 43-128 characters
// - Characters: [A-Z] [a-z] [0-9] - . _ ~
// - Method: Cryptographically secure random number generator
func GenerateCodeVerifier() (string, error) {
	// Generate 32 random bytes (will encode to 43 characters in base64url)
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", errors.New("failed to generate random bytes for code verifier")
	}

	// Encode to base64url without padding (RFC 7636 requirement)
	verifier := base64.RawURLEncoding.EncodeToString(b)

	// Verify length (should be exactly 43 characters for 32 bytes)
	if len(verifier) < 43 || len(verifier) > 128 {
		return "", errors.New("code verifier length out of range")
	}

	return verifier, nil
}

// GenerateCodeChallenge creates a code challenge from a code verifier
// Uses SHA256 hashing as specified in RFC 7636
//
// challenge = BASE64URL(SHA256(ASCII(code_verifier)))
//
// Parameters:
//   - verifier: The code verifier (43-128 characters)
//
// Returns:
//   - The base64url-encoded SHA256 hash of the verifier
func GenerateCodeChallenge(verifier string) string {
	// Hash the verifier using SHA256
	h := sha256.New()
	h.Write([]byte(verifier))
	hashed := h.Sum(nil)

	// Encode to base64url without padding
	challenge := base64.RawURLEncoding.EncodeToString(hashed)

	return challenge
}

// ValidateCodeVerifier validates a code verifier against a code challenge
// This is used by the server to verify the PKCE flow
//
// Parameters:
//   - verifier: The code verifier sent by the client
//   - challenge: The code challenge stored by the server
//
// Returns:
//   - true if SHA256(verifier) == challenge
//   - false otherwise
func ValidateCodeVerifier(verifier string, challenge string) bool {
	// Validate verifier length (RFC 7636)
	if len(verifier) < 43 || len(verifier) > 128 {
		return false
	}

	// Generate challenge from verifier
	computedChallenge := GenerateCodeChallenge(verifier)

	// Constant-time comparison to prevent timing attacks
	return computedChallenge == challenge
}

// IsValidCodeVerifier checks if a string is a valid PKCE code verifier
// according to RFC 7636 requirements
func IsValidCodeVerifier(verifier string) bool {
	// Check length requirement
	if len(verifier) < 43 || len(verifier) > 128 {
		return false
	}

	// Check character set: [A-Z] [a-z] [0-9] - . _ ~
	for _, c := range verifier {
		if !((c >= 'A' && c <= 'Z') ||
			(c >= 'a' && c <= 'z') ||
			(c >= '0' && c <= '9') ||
			c == '-' || c == '.' || c == '_' || c == '~') {
			return false
		}
	}

	return true
}
