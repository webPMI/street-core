package config

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"golang.org/x/oauth2"
)

// OAuthConfig holds all OAuth provider configurations
type OAuthConfig struct {
	Google           GoogleOAuthConfig
	Facebook         FacebookOAuthConfig
	EncryptionKey    string   // 32-byte hex key for AES-256
	StateExpiry      int      // Minutes
	AllowedRedirects []string // Whitelisted redirect URIs
}

// GoogleOAuthConfig holds Google OAuth 2.0 configuration
type GoogleOAuthConfig struct {
	ClientID     string
	ClientSecret string
	RedirectURI  string
	Scopes       []string
	Enabled      bool
}

// FacebookOAuthConfig holds Facebook OAuth 2.0 configuration
type FacebookOAuthConfig struct {
	AppID       string
	AppSecret   string
	RedirectURI string
	Scopes      []string
	Enabled     bool
}

// OAuth is the global OAuth configuration instance
var OAuth *OAuthConfig

// LoadOAuthConfig loads OAuth configuration from environment variables
// This should be called after LoadConfig()
// Returns nil (no error) even if OAuth is not configured - OAuth is optional
func LoadOAuthConfig() error {
	log.Println("🔐 Loading OAuth configuration...")

	// Load Google OAuth config
	googleClientID := os.Getenv("GOOGLE_CLIENT_ID")
	googleClientSecret := os.Getenv("GOOGLE_CLIENT_SECRET")
	googleRedirectURI := os.Getenv("GOOGLE_REDIRECT_URI")

	// Load Facebook OAuth config
	facebookAppID := os.Getenv("FACEBOOK_APP_ID")
	facebookAppSecret := os.Getenv("FACEBOOK_APP_SECRET")
	facebookRedirectURI := os.Getenv("FACEBOOK_REDIRECT_URI")

	// Load OAuth encryption key (required for token encryption)
	encryptionKey := os.Getenv("OAUTH_ENCRYPTION_KEY")

	// Filter out invalid placeholder values
	if encryptionKey == "" || strings.Contains(encryptionKey, "INVALID") {
		log.Println("⚠️  OAUTH_ENCRYPTION_KEY not configured. OAuth features will be disabled.")
		log.Println("   To enable OAuth, generate a key with: openssl rand -hex 32")

		// Create minimal OAuth config to prevent nil pointer errors
		OAuth = &OAuthConfig{
			EncryptionKey: "",
			StateExpiry:   10,
		}
		return nil // Not an error - OAuth is optional
	}

	// Validate encryption key length (must be 64 hex characters = 32 bytes)
	if len(encryptionKey) != 64 {
		log.Printf("⚠️  OAUTH_ENCRYPTION_KEY invalid length: %d characters (need 64 hex)", len(encryptionKey))
		log.Println("   OAuth features will be disabled")
		OAuth = &OAuthConfig{EncryptionKey: "", StateExpiry: 10}
		return nil // Not an error - OAuth is optional
	}

	// Validate encryption key is valid hex
	for _, c := range encryptionKey {
		if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
			log.Println("⚠️  OAUTH_ENCRYPTION_KEY must be hexadecimal [0-9a-fA-F]")
			log.Println("   OAuth features will be disabled")
			OAuth = &OAuthConfig{EncryptionKey: "", StateExpiry: 10}
			return nil // Not an error - OAuth is optional
		}
	}

	// Load state token expiry (default: 10 minutes)
	stateExpiryStr := os.Getenv("OAUTH_STATE_EXPIRY")
	stateExpiry := 10 // default
	if stateExpiryStr != "" {
		var err error
		stateExpiry, err = strconv.Atoi(stateExpiryStr)
		if err != nil || stateExpiry < 1 || stateExpiry > 60 {
			log.Printf("⚠️  Invalid OAUTH_STATE_EXPIRY value: %s. Using default: 10 minutes", stateExpiryStr)
			stateExpiry = 10
		}
	}

	// Load allowed redirect URIs
	allowedRedirectsStr := os.Getenv("OAUTH_ALLOWED_REDIRECTS")
	var allowedRedirects []string
	if allowedRedirectsStr != "" {
		allowedRedirects = strings.Split(allowedRedirectsStr, ",")
		// Trim whitespace
		for i := range allowedRedirects {
			allowedRedirects[i] = strings.TrimSpace(allowedRedirects[i])
		}
	}

	// Filter out invalid placeholder values from provider configs
	if strings.Contains(googleClientID, "INVALID") {
		googleClientID = ""
	}
	if strings.Contains(googleClientSecret, "INVALID") {
		googleClientSecret = ""
	}
	if strings.Contains(facebookAppID, "INVALID") {
		facebookAppID = ""
	}
	if strings.Contains(facebookAppSecret, "INVALID") {
		facebookAppSecret = ""
	}

	// Determine which providers are enabled
	googleEnabled := googleClientID != "" && googleClientSecret != "" && googleRedirectURI != ""
	facebookEnabled := facebookAppID != "" && facebookAppSecret != "" && facebookRedirectURI != ""

	if !googleEnabled && !facebookEnabled {
		log.Println("⚠️  No OAuth providers configured. OAuth login will be disabled.")
		log.Println("   Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET to enable Google OAuth.")
		log.Println("   Set FACEBOOK_APP_ID and FACEBOOK_APP_SECRET to enable Facebook OAuth.")
	}

	// Create OAuth config
	OAuth = &OAuthConfig{
		Google: GoogleOAuthConfig{
			ClientID:     googleClientID,
			ClientSecret: googleClientSecret,
			RedirectURI:  googleRedirectURI,
			Scopes: []string{
				"https://www.googleapis.com/auth/userinfo.email",
				"https://www.googleapis.com/auth/userinfo.profile",
			},
			Enabled: googleEnabled,
		},
		Facebook: FacebookOAuthConfig{
			AppID:       facebookAppID,
			AppSecret:   facebookAppSecret,
			RedirectURI: facebookRedirectURI,
			Scopes: []string{
				"email",
				"public_profile",
			},
			Enabled: facebookEnabled,
		},
		EncryptionKey:    encryptionKey,
		StateExpiry:      stateExpiry,
		AllowedRedirects: allowedRedirects,
	}

	// Log enabled providers
	if googleEnabled {
		log.Println("✅ Google OAuth enabled")
		log.Printf("   - Redirect URI: %s", googleRedirectURI)
		log.Printf("   - Scopes: %v", OAuth.Google.Scopes)
	} else {
		log.Println("⚠️  Google OAuth disabled (missing configuration)")
	}

	if facebookEnabled {
		log.Println("✅ Facebook OAuth enabled")
		log.Printf("   - Redirect URI: %s", facebookRedirectURI)
		log.Printf("   - Scopes: %v", OAuth.Facebook.Scopes)
	} else {
		log.Println("⚠️  Facebook OAuth disabled (missing configuration)")
	}

	log.Printf("🔐 OAuth state token expiry: %d minutes", stateExpiry)
	if len(allowedRedirects) > 0 {
		log.Printf("🔐 Allowed redirect URIs: %v", allowedRedirects)
	}

	log.Println("✅ OAuth configuration loaded successfully")
	return nil
}

// ValidateRedirectURI checks if a redirect URI is whitelisted
func ValidateRedirectURI(uri string) error {
	// If no whitelist is configured, allow any HTTPS URI in production
	if len(OAuth.AllowedRedirects) == 0 {
		if Cfg.Env == "production" && !strings.HasPrefix(uri, "https://") {
			return fmt.Errorf("redirect URI must use HTTPS in production")
		}
		return nil
	}

	// Check against whitelist
	for _, allowed := range OAuth.AllowedRedirects {
		if uri == allowed {
			return nil
		}
	}

	return fmt.Errorf("redirect URI not whitelisted: %s", uri)
}

// IsOAuthEnabled returns true if at least one OAuth provider is configured
func IsOAuthEnabled() bool {
	return OAuth != nil && (OAuth.Google.Enabled || OAuth.Facebook.Enabled)
}

// GetFacebookOAuthConfig returns the oauth2.Config for Facebook
func GetFacebookOAuthConfig() (*oauth2.Config, error) {
	if OAuth == nil || !OAuth.Facebook.Enabled {
		return nil, fmt.Errorf("facebook OAuth is not enabled")
	}

	return &oauth2.Config{
		ClientID:     OAuth.Facebook.AppID,
		ClientSecret: OAuth.Facebook.AppSecret,
		RedirectURL:  OAuth.Facebook.RedirectURI,
		Scopes:       OAuth.Facebook.Scopes,
		Endpoint: oauth2.Endpoint{
			AuthURL:  "https://www.facebook.com/v12.0/dialog/oauth",
			TokenURL: "https://graph.facebook.com/v12.0/oauth/access_token",
		},
	}, nil
}
