package storage

import (
	"context"
	"io"
)

// Storage defines the interface for file storage operations.
// This abstraction allows switching between filesystem, S3, and hybrid storage.
type Storage interface {
	// Save stores a file and returns metadata about the saved file
	Save(ctx context.Context, file io.Reader, path string, metadata Metadata) (*SaveResult, error)

	// Get retrieves a file as a ReadCloser
	Get(ctx context.Context, path string) (io.ReadCloser, error)

	// Delete removes a file from storage
	Delete(ctx context.Context, path string) error

	// Exists checks if a file exists in storage
	Exists(ctx context.Context, path string) (bool, error)

	// GetPublicURL returns the public URL for accessing a file
	GetPublicURL(path string) string

	// GetStorageType returns the type of storage (filesystem, s3, hybrid)
	GetStorageType() string
}

// Metadata contains file metadata for storage operations
type Metadata struct {
	ContentType string            // MIME type of the file
	Size        int64             // File size in bytes
	Hash        string            // SHA256 hash of the file
	Custom      map[string]string // Custom metadata fields
}

// SaveResult contains information about a successfully saved file
type SaveResult struct {
	Path      string // Storage path (may differ from input path)
	PublicURL string // Public URL for accessing the file
	Size      int64  // Actual file size stored
	Hash      string // SHA256 hash of the stored file
}

// StorageConfig holds configuration for initializing storage
type StorageConfig struct {
	Type      string // "filesystem", "s3", or "hybrid"
	BaseURL   string // Base URL for public access
	UploadDir string // Local filesystem directory (for filesystem storage)

	// S3 Configuration
	S3Bucket    string
	S3Region    string
	S3AccessKey string
	S3SecretKey string
	S3Endpoint  string // For MinIO or custom S3-compatible storage

	// CDN Configuration
	CDNDomain  string
	CDNEnabled bool
}
