package config

import (
	"backend/utils"
	"os"
	"path/filepath"
	"time"
)

// MediaContext represents the context/purpose of an upload
type MediaContext string

const (
	MediaContextGeneral      MediaContext = "general"
	MediaContextCompetitions MediaContext = "competitions"
	MediaContextPosts        MediaContext = "posts"
	MediaContextClubs        MediaContext = "clubs"
	MediaContextEvents       MediaContext = "events"
	MediaContextProfiles     MediaContext = "profiles"
)

// MediaConfig holds configuration for media uploads
type MediaConfig struct {
	// Upload directories (filesystem storage)
	UploadDir    string
	ImageDir     string
	VideoDir     string
	ThumbnailDir string
	AvatarDir    string
	TempDir      string

	// File size limits (in bytes)
	MaxImageSize  int64 // 10MB
	MaxVideoSize  int64 // 500MB
	MaxAvatarSize int64 // 5MB

	// Allowed file types
	AllowedImageTypes []string
	AllowedVideoTypes []string

	// Image processing
	ThumbnailWidth  int
	ThumbnailHeight int
	AvatarWidth     int
	AvatarHeight    int

	// Security
	EnableVirusScan      bool
	EnableMagicByteCheck bool
	MaxFilesPerUpload    int

	// Storage configuration (Cloud migration)
	StorageType string // "filesystem", "s3", or "hybrid"

	// S3 configuration
	S3Bucket    string
	S3Region    string
	S3AccessKey string
	S3SecretKey string
	S3Endpoint  string // For MinIO or custom S3-compatible storage

	// CDN configuration
	CDNDomain  string
	CDNEnabled bool

	// Migration configuration
	MigrationBatchSize int
	MigrationInterval  time.Duration

	// Worker Pool Configuration
	ProcessingWorkers int           // Number of workers for async processing
	ProcessingTimeout time.Duration // Timeout for individual file processing
	MaxRetries        int           // Maximum retry attempts for failed operations
}

var Media *MediaConfig

// InitMediaConfig initializes media configuration
func InitMediaConfig() {
	baseDir := os.Getenv("MEDIA_UPLOAD_DIR")
	if baseDir == "" {
		baseDir = os.Getenv("UPLOAD_DIR") // Backward compatibility
		if baseDir == "" {
			baseDir = "./uploads"
		}
	}

	Media = &MediaConfig{
		// Directories (filesystem storage)
		UploadDir:    baseDir,
		ImageDir:     filepath.Join(baseDir, "images"),
		VideoDir:     filepath.Join(baseDir, "videos"),
		ThumbnailDir: filepath.Join(baseDir, "thumbnails"),
		AvatarDir:    filepath.Join(baseDir, "avatars"),
		TempDir:      filepath.Join(baseDir, "temp"),

		// Size limits
		MaxImageSize:  10 * 1024 * 1024,  // 10MB
		MaxVideoSize:  500 * 1024 * 1024, // 500MB
		MaxAvatarSize: 5 * 1024 * 1024,   // 5MB

		// Allowed MIME types
		AllowedImageTypes: []string{
			"image/jpeg",
			"image/jpg",
			"image/png",
			"image/gif",
			"image/webp",
		},
		AllowedVideoTypes: []string{
			"video/mp4",
			"video/mpeg",
			"video/quicktime", // .mov
			"video/x-msvideo", // .avi
			"video/webm",
		},

		// Image processing dimensions
		ThumbnailWidth:  400,
		ThumbnailHeight: 400,
		AvatarWidth:     200,
		AvatarHeight:    200,

		// Security settings
		EnableVirusScan:      false, // Set to true if ClamAV is installed
		EnableMagicByteCheck: true,
		MaxFilesPerUpload:    10, // Max 10 files per upload (for carousels)

		// Storage configuration
		StorageType: getEnv("MEDIA_STORAGE_TYPE", "filesystem"),

		// S3 configuration
		S3Bucket:    getEnv("MEDIA_S3_BUCKET", ""),
		S3Region:    getEnv("MEDIA_S3_REGION", "us-east-1"),
		S3AccessKey: getEnv("MEDIA_S3_ACCESS_KEY", ""),
		S3SecretKey: getEnv("MEDIA_S3_SECRET_KEY", ""),
		S3Endpoint:  getEnv("MEDIA_S3_ENDPOINT", ""),

		// CDN configuration
		CDNDomain:  getEnv("MEDIA_CDN_DOMAIN", ""),
		CDNEnabled: getEnvAsBool("MEDIA_CDN_ENABLED", false),

		// Migration configuration
		MigrationBatchSize: getEnvAsInt("MEDIA_MIGRATION_BATCH_SIZE", 100),
		MigrationInterval:  getEnvAsDuration("MEDIA_MIGRATION_INTERVAL", 5*time.Minute),

		// Worker Pool Configuration
		ProcessingWorkers: getEnvAsInt("MEDIA_PROCESSING_WORKERS", 10),
		ProcessingTimeout: getEnvAsDuration("MEDIA_PROCESSING_TIMEOUT", 5*time.Minute),
		MaxRetries:        getEnvAsInt("MEDIA_MAX_RETRIES", 3),
	}

	// Create directories if they don't exist (for filesystem storage)
	createMediaDirectories()
}

// Helper function to get env as duration
func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}
	duration, err := time.ParseDuration(valueStr)
	if err != nil {
		return defaultValue
	}
	return duration
}

// createMediaDirectories creates all required upload directories
func createMediaDirectories() {
	dirs := []string{
		Media.UploadDir,
		Media.ImageDir,
		Media.VideoDir,
		Media.ThumbnailDir,
		Media.AvatarDir,
		Media.TempDir,
	}

	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			utils.Fatal("Error creando directorio de media", map[string]interface{}{
				"directory": dir,
				"error":     err.Error(),
			})
		}
	}
}

// IsAllowedImageType checks if the MIME type is allowed for images
func (c *MediaConfig) IsAllowedImageType(mimeType string) bool {
	for _, allowed := range c.AllowedImageTypes {
		if mimeType == allowed {
			return true
		}
	}
	return false
}

// IsAllowedVideoType checks if the MIME type is allowed for videos
func (c *MediaConfig) IsAllowedVideoType(mimeType string) bool {
	for _, allowed := range c.AllowedVideoTypes {
		if mimeType == allowed {
			return true
		}
	}
	return false
}

// GetMaxSizeForType returns the max allowed size for a given file type
func (c *MediaConfig) GetMaxSizeForType(fileType string) int64 {
	switch fileType {
	case "image":
		return c.MaxImageSize
	case "video":
		return c.MaxVideoSize
	case "avatar":
		return c.MaxAvatarSize
	default:
		return c.MaxImageSize
	}
}

// GetContextDir returns the subdirectory for a specific context
func (c *MediaConfig) GetContextDir(baseDir string, context MediaContext) string {
	if context == "" || context == MediaContextGeneral {
		return baseDir
	}
	return filepath.Join(baseDir, string(context))
}

// EnsureContextDir ensures the context directory exists and returns its path
func (c *MediaConfig) EnsureContextDir(baseDir string, context MediaContext) (string, error) {
	dir := c.GetContextDir(baseDir, context)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return "", err
	}
	return dir, nil
}
