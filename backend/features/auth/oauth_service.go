package auth

import (
	"backend/config"
	"backend/models"
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// UserServiceForOAuth defines what OAuth needs from user service
type UserServiceForOAuth interface {
	GetUser(id string) (*models.User, error)
	GetUserByEmail(email string) (*models.User, error)
	CreateUser(user *models.User) error
}

// OAuthService handles OAuth authentication
type OAuthService struct {
	db               *mongo.Database
	userService      UserServiceForOAuth
	oauthStateColl   *mongo.Collection
	oauthAccountColl *mongo.Collection
}

// NewOAuthService creates a new OAuth service
func NewOAuthService(db *mongo.Database, userService UserServiceForOAuth) *OAuthService {
	return &OAuthService{
		db:               db,
		userService:      userService,
		oauthStateColl:   db.Collection("oauth_states"),
		oauthAccountColl: db.Collection("oauth_accounts"),
	}
}

// InitiateOAuthLogin initiates an OAuth login flow
func (s *OAuthService) InitiateOAuthLogin(ctx context.Context, provider models.OAuthProvider, redirectURI string) (string, string, error) {
	// Generate state token
	stateBytes := make([]byte, 32)
	if _, err := rand.Read(stateBytes); err != nil {
		return "", "", err
	}
	state := hex.EncodeToString(stateBytes)

	// Store state
	oauthState := &models.OAuthState{
		ID:          primitive.NewObjectID(),
		State:       state,
		Provider:    provider,
		RedirectURI: redirectURI,
		CreatedAt:   time.Now(),
		ExpiresAt:   time.Now().Add(10 * time.Minute),
	}

	if _, err := s.oauthStateColl.InsertOne(ctx, oauthState); err != nil {
		return "", "", err
	}

	// Build auth URL based on provider
	var authURL string
	switch provider {
	case models.OAuthProviderGoogle:
		authURL = buildGoogleAuthURL(state, redirectURI)
	case models.OAuthProviderFacebook:
		authURL = buildFacebookAuthURL(state, redirectURI)
	default:
		return "", "", errors.New("unsupported OAuth provider")
	}

	return authURL, state, nil
}

// HandleOAuthCallback handles the OAuth callback
func (s *OAuthService) HandleOAuthCallback(ctx context.Context, provider models.OAuthProvider, code, state string) (*models.User, *models.OAuthAccount, error) {
	// Verify state
	var oauthState models.OAuthState
	err := s.oauthStateColl.FindOne(ctx, bson.M{
		"state":     state,
		"provider":  provider,
		"expiresAt": bson.M{"$gt": time.Now()},
	}).Decode(&oauthState)
	if err != nil {
		return nil, nil, errors.New("invalid or expired state")
	}

	// Delete used state
	s.oauthStateColl.DeleteOne(ctx, bson.M{"_id": oauthState.ID})

	// Exchange code for token and get user info
	oauthUser, err := s.exchangeCodeForUser(ctx, provider, code, oauthState.RedirectURI)
	if err != nil {
		return nil, nil, err
	}

	// Find or create user
	user, oauthAccount, err := s.findOrCreateOAuthUser(ctx, provider, oauthUser)
	if err != nil {
		return nil, nil, err
	}

	return user, oauthAccount, nil
}

// exchangeCodeForUser exchanges OAuth code for user info
func (s *OAuthService) exchangeCodeForUser(ctx context.Context, provider models.OAuthProvider, code, redirectURI string) (*OAuthUserInfo, error) {
	// This is a placeholder - implement actual OAuth token exchange
	return nil, errors.New("OAuth token exchange not implemented - configure provider API calls")
}

// findOrCreateOAuthUser finds an existing user or creates a new one
func (s *OAuthService) findOrCreateOAuthUser(ctx context.Context, provider models.OAuthProvider, oauthUser *OAuthUserInfo) (*models.User, *models.OAuthAccount, error) {
	if oauthUser == nil {
		return nil, nil, errors.New("oauth user info is nil")
	}

	// Check if OAuth account exists
	var oauthAccount models.OAuthAccount
	err := s.oauthAccountColl.FindOne(ctx, bson.M{
		"provider":   provider,
		"providerId": oauthUser.ProviderID,
	}).Decode(&oauthAccount)

	if err == nil {
		// OAuth account exists, get user
		user, err := s.userService.GetUser(oauthAccount.UserID.Hex())
		if err != nil {
			return nil, nil, err
		}
		return user, &oauthAccount, nil
	}

	if err != mongo.ErrNoDocuments {
		return nil, nil, err
	}

	// Check if user with email exists
	user, err := s.userService.GetUserByEmail(oauthUser.Email)
	if err == nil {
		// Link OAuth to existing user
		oauthAccount = models.OAuthAccount{
			ID:         primitive.NewObjectID(),
			UserID:     user.ID,
			Provider:   provider,
			ProviderID: oauthUser.ProviderID,
			Email:      oauthUser.Email,
			CreatedAt:  time.Now(),
		}
		if _, err := s.oauthAccountColl.InsertOne(ctx, oauthAccount); err != nil {
			return nil, nil, err
		}
		return user, &oauthAccount, nil
	}

	// Create new user
	newUser := &models.User{
		Email:          oauthUser.Email,
		FirstName:      oauthUser.FirstName,
		LastName:       oauthUser.LastName,
		AvatarURL:      oauthUser.AvatarURL,
		EmailVerified:  true,
		OAuthProviders: []string{string(provider)},
	}

	if err := s.userService.CreateUser(newUser); err != nil {
		return nil, nil, err
	}

	// Create OAuth account
	oauthAccount = models.OAuthAccount{
		ID:         primitive.NewObjectID(),
		UserID:     newUser.ID,
		Provider:   provider,
		ProviderID: oauthUser.ProviderID,
		Email:      oauthUser.Email,
		CreatedAt:  time.Now(),
	}
	if _, err := s.oauthAccountColl.InsertOne(ctx, oauthAccount); err != nil {
		return nil, nil, err
	}

	return newUser, &oauthAccount, nil
}

// OAuthUserInfo represents user info from OAuth provider
type OAuthUserInfo struct {
	ProviderID string
	Email      string
	FirstName  string
	LastName   string
	AvatarURL  string
}

// Helper functions to build OAuth URLs
func buildGoogleAuthURL(state, redirectURI string) string {
	return "https://accounts.google.com/o/oauth2/v2/auth?" +
		"client_id=" + config.Cfg.GoogleClientID +
		"&redirect_uri=" + redirectURI +
		"&response_type=code" +
		"&scope=email%20profile" +
		"&state=" + state
}

func buildFacebookAuthURL(state, redirectURI string) string {
	return "https://www.facebook.com/v18.0/dialog/oauth?" +
		"client_id=" + config.Cfg.FacebookAppID +
		"&redirect_uri=" + redirectURI +
		"&response_type=code" +
		"&scope=email,public_profile" +
		"&state=" + state
}
