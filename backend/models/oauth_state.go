package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// OAuthState represents a CSRF protection token for OAuth flows
// These tokens are short-lived (10 minutes) and single-use
// Implements OWASP OAuth 2.0 Security Best Practices (2025)
type OAuthState struct {
	ID primitive.ObjectID `json:"id" bson:"_id,omitempty"`

	// 🔒 SECURITY: State parameter for CSRF protection
	State string `json:"state" bson:"state" validate:"required"` // UUID v4 (36 characters)

	// Provider for this OAuth flow
	Provider OAuthProvider `json:"provider" bson:"provider" validate:"required,oneof=google facebook"`

	// 🔒 SECURITY: PKCE (Proof Key for Code Exchange) RFC 7636
	// Protects against authorization code interception attacks
	CodeVerifier string `json:"-" bson:"codeVerifier" validate:"required"` // 43-128 characters, base64url

	// Redirect URI for this flow (must match on callback)
	RedirectURI string `json:"redirectUri" bson:"redirectUri" validate:"required,url"`

	// Optional: Store user session ID for additional validation
	SessionID string `json:"-" bson:"sessionId,omitempty"`

	// Timestamps
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	ExpiresAt time.Time `json:"expiresAt" bson:"expiresAt"` // TTL index will auto-delete
}

// PrepareForInsert sets up a new OAuth state token before insertion
func (os *OAuthState) PrepareForInsert(expiryMinutes int) {
	now := time.Now()
	os.ID = primitive.NewObjectID()
	os.CreatedAt = now
	os.ExpiresAt = now.Add(time.Duration(expiryMinutes) * time.Minute)
}

// IsExpired checks if the state token has expired
func (os *OAuthState) IsExpired() bool {
	return time.Now().After(os.ExpiresAt)
}

// IsValid performs comprehensive validation on the state token
func (os *OAuthState) IsValid() bool {
	// Check if expired
	if os.IsExpired() {
		return false
	}

	// Check required fields are present
	if os.State == "" || os.CodeVerifier == "" || os.RedirectURI == "" {
		return false
	}

	// Verify state format (should be UUID)
	if len(os.State) < 32 {
		return false
	}

	// Verify code verifier length (RFC 7636: 43-128 characters)
	verifierLen := len(os.CodeVerifier)
	if verifierLen < 43 || verifierLen > 128 {
		return false
	}

	return true
}
