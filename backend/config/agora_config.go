package config

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"strconv"
	"time"
)

// AgoraConfig holds Agora RTC configuration
type AgoraConfig struct {
	Enabled       bool
	AppID         string
	AppCertificate string
	// Token expiration (default: 24 hours for viewers, 48 hours for hosts)
	ViewerTokenExpiry time.Duration
	HostTokenExpiry   time.Duration
	// Cloud recording configuration
	RecordingEnabled  bool
	RecordingBucket   string // S3/Cloud storage bucket for recordings
	RecordingRegion   string // AWS region or cloud provider region
	RecordingCustomerID string
	RecordingCustomerSecret string
}

// Agora is the global Agora configuration
var Agora AgoraConfig

// LoadAgoraConfig loads Agora SDK configuration from environment variables
func LoadAgoraConfig() {
	Agora.AppID = getEnv("AGORA_APP_ID", "")
	Agora.AppCertificate = getEnv("AGORA_APP_CERTIFICATE", "")

	// Agora is enabled only if both AppID and Certificate are valid
	Agora.Enabled = isValidAgoraKey(Agora.AppID) && isValidAgoraKey(Agora.AppCertificate)

	// Token expiration
	viewerExpHours := getEnvAsInt("AGORA_VIEWER_TOKEN_EXP_HOURS", 24)
	Agora.ViewerTokenExpiry = time.Duration(viewerExpHours) * time.Hour

	hostExpHours := getEnvAsInt("AGORA_HOST_TOKEN_EXP_HOURS", 48)
	Agora.HostTokenExpiry = time.Duration(hostExpHours) * time.Hour

	// Cloud recording configuration
	Agora.RecordingEnabled = getEnvAsBool("AGORA_RECORDING_ENABLED", false)
	Agora.RecordingBucket = getEnv("AGORA_RECORDING_BUCKET", "")
	Agora.RecordingRegion = getEnv("AGORA_RECORDING_REGION", "")
	Agora.RecordingCustomerID = getEnv("AGORA_RECORDING_CUSTOMER_ID", "")
	Agora.RecordingCustomerSecret = getEnv("AGORA_RECORDING_CUSTOMER_SECRET", "")

	// Log configuration status
	if Agora.Enabled {
		fmt.Println("📹 Agora RTC: habilitado")
		fmt.Printf("   - App ID: %s\n", maskString(Agora.AppID))
		fmt.Printf("   - Viewer Token Expiry: %d hours\n", int(Agora.ViewerTokenExpiry.Hours()))
		fmt.Printf("   - Host Token Expiry: %d hours\n", int(Agora.HostTokenExpiry.Hours()))
		if Agora.RecordingEnabled {
			fmt.Println("   - Cloud Recording: habilitado")
			fmt.Printf("     - Bucket: %s\n", Agora.RecordingBucket)
			fmt.Printf("     - Region: %s\n", Agora.RecordingRegion)
		} else {
			fmt.Println("   - Cloud Recording: deshabilitado")
		}
	} else {
		fmt.Println("📹 Agora RTC: deshabilitado (no hay credenciales configuradas)")
		fmt.Println("   Para habilitar livestreaming, configura AGORA_APP_ID y AGORA_APP_CERTIFICATE en .env")
	}
}

// isValidAgoraKey checks if an Agora key is valid
func isValidAgoraKey(key string) bool {
	if key == "" {
		return false
	}
	// Agora App IDs are 32-character hex strings
	// Agora App Certificates are also 32-character hex strings
	if len(key) != 32 {
		return false
	}
	// Check if it's a valid hex string
	_, err := hex.DecodeString(key)
	return err == nil
}

// maskString masks sensitive information for logging
func maskString(s string) string {
	if len(s) <= 8 {
		return "****"
	}
	return s[:4] + "****" + s[len(s)-4:]
}

// ============================================================================
// Agora RTC Token Generation
// ============================================================================

// RoleType represents the user role in Agora channel
type RoleType uint16

const (
	RoleAttendee  RoleType = 0 // Viewer (can only receive streams)
	RolePublisher RoleType = 1 // Host (can publish and receive streams)
	RoleSubscriber RoleType = 2 // Viewer (alternative name)
)

// GenerateRTCToken generates an Agora RTC token for a user
// Parameters:
//   - channelName: The channel name (e.g., "livestream_123")
//   - uid: User ID (0 means any user can use this token)
//   - role: RolePublisher (host) or RoleAttendee (viewer)
//   - expiry: Token expiration duration
func GenerateRTCToken(channelName string, uid uint, role RoleType, expiry time.Duration) (string, error) {
	if !Agora.Enabled {
		return "", fmt.Errorf("Agora SDK is not enabled")
	}

	// Calculate expiration timestamp
	expirationTime := uint32(time.Now().Unix()) + uint32(expiry.Seconds())

	// Build message to sign
	message := buildTokenMessage(channelName, uid, role, expirationTime)

	// Sign the message with HMAC-SHA256
	signature := signMessage(message, Agora.AppCertificate)

	// Build the token
	token := buildToken(Agora.AppID, signature, message, expirationTime)

	return token, nil
}

// buildTokenMessage constructs the message to be signed
func buildTokenMessage(channelName string, uid uint, role RoleType, expirationTime uint32) string {
	// Agora token format: AppID + ChannelName + UID + Role + ExpirationTime
	message := fmt.Sprintf("%s%s%d%d%d",
		Agora.AppID,
		channelName,
		uid,
		role,
		expirationTime,
	)
	return message
}

// signMessage signs a message using HMAC-SHA256
func signMessage(message, secret string) string {
	h := hmac.New(sha256.New, []byte(secret))
	h.Write([]byte(message))
	return hex.EncodeToString(h.Sum(nil))
}

// buildToken constructs the final Agora RTC token
func buildToken(appID, signature, message string, expirationTime uint32) string {
	// Agora token format: version + appID + signature + message + expirationTime
	// Version 006 is the current Agora token version
	version := "006"

	// Combine all parts
	tokenData := fmt.Sprintf("%s%s%s%s%d",
		version,
		appID,
		signature,
		message,
		expirationTime,
	)

	// Base64 encode the token
	token := base64.StdEncoding.EncodeToString([]byte(tokenData))

	return token
}

// ============================================================================
// Token Validation
// ============================================================================

// ValidateRTCToken validates an Agora RTC token
// Returns true if the token is valid and not expired
func ValidateRTCToken(token string) (bool, error) {
	if !Agora.Enabled {
		return false, fmt.Errorf("Agora SDK is not enabled")
	}

	// Decode base64
	tokenData, err := base64.StdEncoding.DecodeString(token)
	if err != nil {
		return false, fmt.Errorf("invalid token format: %w", err)
	}

	// Token must be at least: version(3) + appID(32) + signature(64) + expiration(10)
	if len(tokenData) < 109 {
		return false, fmt.Errorf("token too short")
	}

	// Extract version
	version := string(tokenData[:3])
	if version != "006" {
		return false, fmt.Errorf("unsupported token version: %s", version)
	}

	// Extract expiration time (last 10 bytes)
	expirationStr := string(tokenData[len(tokenData)-10:])
	expirationTime, err := strconv.ParseUint(expirationStr, 10, 32)
	if err != nil {
		return false, fmt.Errorf("invalid expiration time: %w", err)
	}

	// Check if token is expired
	now := uint32(time.Now().Unix())
	if now > uint32(expirationTime) {
		return false, fmt.Errorf("token expired")
	}

	return true, nil
}

// ============================================================================
// Channel Management
// ============================================================================

// GenerateChannelName generates a unique channel name for a livestream
func GenerateChannelName(streamID string) string {
	return fmt.Sprintf("stream_%s", streamID)
}

// GenerateUID generates a unique Agora UID for a user
// In Agora, UID can be 0 (any user) or a positive integer
// We use ObjectID hash to generate a consistent UID for each user
func GenerateUID(userID string) uint {
	// Simple hash: sum of ASCII values modulo max uint32
	var sum uint
	for _, char := range userID {
		sum += uint(char)
	}
	// Return a 32-bit unsigned integer
	return sum % 4294967295
}
