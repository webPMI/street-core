package models

import (
	"backend/pkg/security"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// OAuthProvider represents supported OAuth providers
type OAuthProvider string

const (
	OAuthProviderGoogle   OAuthProvider = "google"
	OAuthProviderFacebook OAuthProvider = "facebook"
)

// OAuthAccount represents a linked OAuth provider account for a user
// This allows users to login with multiple OAuth providers
type OAuthAccount struct {
	ID primitive.ObjectID `json:"id" bson:"_id,omitempty"`

	// User reference
	UserID primitive.ObjectID `json:"userId" bson:"userId" validate:"required"`

	// Provider information
	Provider   OAuthProvider `json:"provider" bson:"provider" validate:"required,oneof=google facebook"`
	ProviderID string        `json:"providerId" bson:"providerId" validate:"required"` // Unique ID from provider (sub claim)
	Email      string        `json:"email" bson:"email" validate:"required,email"`

	// 🔒 SECURITY: Tokens are encrypted at rest using AES-256-GCM
	// Never expose these in JSON responses
	AccessToken  string    `json:"-" bson:"accessToken"`            // Encrypted
	RefreshToken string    `json:"-" bson:"refreshToken,omitempty"` // Encrypted (optional)
	ExpiresAt    time.Time `json:"expiresAt" bson:"expiresAt"`      // Token expiration
	TokenType    string    `json:"-" bson:"tokenType,omitempty"`    // Usually "Bearer"

	// Scope permissions granted
	Scope []string `json:"scope" bson:"scope"`

	// Cached profile data from provider
	ProfileData OAuthProfileData `json:"profileData" bson:"profileData"`

	// Timestamps
	CreatedAt  time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt  time.Time `json:"updatedAt" bson:"updatedAt"`
	LastUsedAt time.Time `json:"lastUsedAt" bson:"lastUsedAt"` // Updated on each login
}

// OAuthProfileData contains cached user profile information from OAuth provider
type OAuthProfileData struct {
	Name          string `json:"name" bson:"name"`
	GivenName     string `json:"givenName,omitempty" bson:"givenName,omitempty"`   // First name
	FamilyName    string `json:"familyName,omitempty" bson:"familyName,omitempty"` // Last name
	Picture       string `json:"picture,omitempty" bson:"picture,omitempty"`       // Avatar URL
	EmailVerified bool   `json:"emailVerified" bson:"emailVerified"`
	Locale        string `json:"locale,omitempty" bson:"locale,omitempty"` // Language preference
}

// PrepareForInsert sets up a new OAuth account before insertion
func (oa *OAuthAccount) PrepareForInsert() {
	now := time.Now()
	oa.ID = primitive.NewObjectID()
	oa.CreatedAt = now
	oa.UpdatedAt = now
	oa.LastUsedAt = now
}

// UpdateLastUsed updates the LastUsedAt timestamp
func (oa *OAuthAccount) UpdateLastUsed() {
	oa.LastUsedAt = time.Now()
	oa.UpdatedAt = time.Now()
}

// IsExpired checks if the OAuth access token has expired
func (oa *OAuthAccount) IsExpired() bool {
	return time.Now().After(oa.ExpiresAt)
}

// PublicOAuthAccount is a safe representation for API responses
// Excludes sensitive token information
type PublicOAuthAccount struct {
	ID          primitive.ObjectID `json:"id"`
	Provider    OAuthProvider      `json:"provider"`
	Email       string             `json:"email"`
	ProfileData OAuthProfileData   `json:"profileData"`
	LinkedAt    time.Time          `json:"linkedAt"`
	LastUsedAt  time.Time          `json:"lastUsedAt"`
}

// ToPublic converts OAuthAccount to PublicOAuthAccount for API responses
func (oa *OAuthAccount) ToPublic() *PublicOAuthAccount {
	return &PublicOAuthAccount{
		ID:          oa.ID,
		Provider:    oa.Provider,
		Email:       oa.Email,
		ProfileData: oa.ProfileData,
		LinkedAt:    oa.CreatedAt,
		LastUsedAt:  oa.LastUsedAt,
	}
}

// EncryptTokens encrypts the access and refresh tokens before storing in database.
// SECURITY: This should be called before saving to MongoDB.
func (oa *OAuthAccount) EncryptTokens() error {
	if !security.IsEncryptionInitialized() {
		// Encryption not configured, store as-is (with warning logged at startup)
		return nil
	}

	if oa.AccessToken != "" {
		encrypted, err := security.Encrypt(oa.AccessToken)
		if err != nil {
			return err
		}
		oa.AccessToken = encrypted
	}

	if oa.RefreshToken != "" {
		encrypted, err := security.Encrypt(oa.RefreshToken)
		if err != nil {
			return err
		}
		oa.RefreshToken = encrypted
	}

	return nil
}

// DecryptTokens decrypts the access and refresh tokens after reading from database.
// SECURITY: This should be called after loading from MongoDB.
func (oa *OAuthAccount) DecryptTokens() error {
	if !security.IsEncryptionInitialized() {
		// Encryption not configured, tokens are plaintext
		return nil
	}

	if oa.AccessToken != "" {
		decrypted, err := security.Decrypt(oa.AccessToken)
		if err != nil {
			// Token might not be encrypted (legacy data), keep as-is
			return nil
		}
		oa.AccessToken = decrypted
	}

	if oa.RefreshToken != "" {
		decrypted, err := security.Decrypt(oa.RefreshToken)
		if err != nil {
			// Token might not be encrypted (legacy data), keep as-is
			return nil
		}
		oa.RefreshToken = decrypted
	}

	return nil
}
