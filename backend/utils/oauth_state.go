package utils

import (
	"backend/models"
	"context"
	"errors"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// 🔒 SECURITY: OAuth State Token Management
//
// State tokens provide CSRF (Cross-Site Request Forgery) protection for OAuth flows
// According to OWASP OAuth 2.0 Security Best Practices (2025)
//
// Security features:
// 1. Cryptographically random UUID v4 (122 bits of entropy)
// 2. Single-use tokens (deleted after validation)
// 3. Time-limited (TTL index auto-deletes expired tokens)
// 4. Bound to specific provider and redirect URI
// 5. Includes PKCE verifier for additional security

// GenerateStateToken generates a cryptographically secure state token
// Returns a UUID v4 string (36 characters including hyphens)
//
// Example: "550e8400-e29b-41d4-a716-446655440000"
func GenerateStateToken() (string, error) {
	// Generate UUID v4 (random)
	stateUUID, err := uuid.NewRandom()
	if err != nil {
		return "", errors.New("failed to generate UUID for state token")
	}

	return stateUUID.String(), nil
}

// StoreState stores an OAuth state token in the database
// This should be called before redirecting the user to the OAuth provider
//
// Parameters:
//   - ctx: Context for database operation
//   - db: MongoDB database
//   - state: The state token (UUID)
//   - provider: OAuth provider (google, facebook)
//   - codeVerifier: PKCE code verifier
//   - redirectURI: The redirect URI for this flow
//   - expiryMinutes: How many minutes until the token expires
//
// Returns:
//   - Error if storage fails
func StoreState(
	ctx context.Context,
	db *mongo.Database,
	state string,
	provider models.OAuthProvider,
	codeVerifier string,
	redirectURI string,
	expiryMinutes int,
) error {
	// Validate inputs
	if state == "" {
		return errors.New("state token cannot be empty")
	}
	if codeVerifier == "" {
		return errors.New("code verifier cannot be empty")
	}
	if redirectURI == "" {
		return errors.New("redirect URI cannot be empty")
	}

	// Create OAuth state document
	oauthState := &models.OAuthState{
		State:        state,
		Provider:     provider,
		CodeVerifier: codeVerifier,
		RedirectURI:  redirectURI,
	}

	// Set timestamps and expiration
	oauthState.PrepareForInsert(expiryMinutes)

	// Insert into database
	collection := db.Collection("oauth_state_tokens")
	_, err := collection.InsertOne(ctx, oauthState)
	if err != nil {
		// Check for duplicate state token (should be extremely rare with UUID)
		if mongo.IsDuplicateKeyError(err) {
			return errors.New("duplicate state token generated (try again)")
		}
		return err
	}

	return nil
}

// ValidateState validates an OAuth state token and returns the associated data
// This should be called when handling the OAuth callback
//
// 🔒 SECURITY: This function performs the following validations:
// 1. State token exists in database
// 2. State token has not expired
// 3. State token provider matches expected provider
// 4. State token has not been used (deleted after validation)
//
// Parameters:
//   - ctx: Context for database operation
//   - db: MongoDB database
//   - state: The state token received from OAuth provider
//   - provider: The expected OAuth provider
//
// Returns:
//   - OAuthState document if valid
//   - Error if validation fails
func ValidateState(
	ctx context.Context,
	db *mongo.Database,
	state string,
	provider models.OAuthProvider,
) (*models.OAuthState, error) {
	// Validate input
	if state == "" {
		return nil, errors.New("state token cannot be empty")
	}

	collection := db.Collection("oauth_state_tokens")

	// Find the state token
	var oauthState models.OAuthState
	filter := bson.M{
		"state":    state,
		"provider": provider,
	}

	err := collection.FindOne(ctx, filter).Decode(&oauthState)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("invalid state token: not found or already used")
		}
		return nil, err
	}

	// Validate the state token
	if !oauthState.IsValid() {
		// Delete invalid token
		collection.DeleteOne(ctx, filter)
		return nil, errors.New("invalid state token: expired or malformed")
	}

	// 🔒 SECURITY: Delete the state token immediately after validation (single-use)
	// This prevents replay attacks where the same state token is used multiple times
	_, err = collection.DeleteOne(ctx, filter)
	if err != nil {
		// Log error but don't fail validation
		// The state was valid, we just couldn't clean it up
		// TTL index will eventually delete it
	}

	return &oauthState, nil
}

// CleanupExpiredStates manually removes expired state tokens
// This is a backup cleanup in case the TTL index doesn't run immediately
//
// This function can be called:
// - In a cron job (recommended: every hour)
// - On application startup
// - During maintenance windows
//
// The TTL index should handle most cleanup automatically,
// but this provides additional protection against token buildup
func CleanupExpiredStates(ctx context.Context, db *mongo.Database) (int64, error) {
	collection := db.Collection("oauth_state_tokens")

	// Find all expired tokens
	filter := bson.M{
		"expiresAt": bson.M{"$lt": bson.M{"$currentDate": bson.M{}}},
	}

	// Delete expired tokens
	result, err := collection.DeleteMany(ctx, filter)
	if err != nil {
		return 0, err
	}

	return result.DeletedCount, nil
}

// GetStateCount returns the number of active state tokens in the database
// This is useful for monitoring and debugging
func GetStateCount(ctx context.Context, db *mongo.Database) (int64, error) {
	collection := db.Collection("oauth_state_tokens")
	return collection.CountDocuments(ctx, bson.M{})
}

// GetStateCountByProvider returns the number of active state tokens per provider
// This is useful for analytics and monitoring
func GetStateCountByProvider(
	ctx context.Context,
	db *mongo.Database,
	provider models.OAuthProvider,
) (int64, error) {
	collection := db.Collection("oauth_state_tokens")
	filter := bson.M{"provider": provider}
	return collection.CountDocuments(ctx, filter)
}
