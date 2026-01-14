package storage

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// FilesystemStorage implements Storage interface using local filesystem
type FilesystemStorage struct {
	baseDir string // Base directory for file storage (e.g., ./uploads)
	baseURL string // Base URL for public access (e.g., http://localhost:3000/uploads)
}

// NewFilesystemStorage creates a new filesystem storage instance
func NewFilesystemStorage(baseDir, baseURL string) (*FilesystemStorage, error) {
	// Ensure base directory exists
	if err := os.MkdirAll(baseDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create base directory: %w", err)
	}

	// Ensure baseURL doesn't end with /
	baseURL = strings.TrimSuffix(baseURL, "/")

	return &FilesystemStorage{
		baseDir: baseDir,
		baseURL: baseURL,
	}, nil
}

// Save stores a file to the filesystem
func (fs *FilesystemStorage) Save(ctx context.Context, file io.Reader, path string, metadata Metadata) (*SaveResult, error) {
	// Build full file path
	fullPath := filepath.Join(fs.baseDir, path)

	// Ensure parent directory exists
	parentDir := filepath.Dir(fullPath)
	if err := os.MkdirAll(parentDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create parent directory: %w", err)
	}

	// Create destination file
	dst, err := os.Create(fullPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	// Calculate hash while copying
	hash := sha256.New()
	multiWriter := io.MultiWriter(dst, hash)

	// Copy file content
	written, err := io.Copy(multiWriter, file)
	if err != nil {
		os.Remove(fullPath) // Cleanup on error
		return nil, fmt.Errorf("failed to write file: %w", err)
	}

	// Generate hash
	hashString := hex.EncodeToString(hash.Sum(nil))

	// Verify size matches metadata (if provided)
	if metadata.Size > 0 && written != metadata.Size {
		os.Remove(fullPath)
		return nil, fmt.Errorf("size mismatch: expected %d, got %d", metadata.Size, written)
	}

	// Build public URL
	publicURL := fs.GetPublicURL(path)

	return &SaveResult{
		Path:      path,
		PublicURL: publicURL,
		Size:      written,
		Hash:      hashString,
	}, nil
}

// Get retrieves a file from filesystem
func (fs *FilesystemStorage) Get(ctx context.Context, path string) (io.ReadCloser, error) {
	fullPath := filepath.Join(fs.baseDir, path)

	// Security: Ensure path doesn't escape base directory
	absPath, err := filepath.Abs(fullPath)
	if err != nil {
		return nil, fmt.Errorf("invalid path: %w", err)
	}

	absBaseDir, err := filepath.Abs(fs.baseDir)
	if err != nil {
		return nil, fmt.Errorf("invalid base directory: %w", err)
	}

	if !strings.HasPrefix(absPath, absBaseDir) {
		return nil, fmt.Errorf("path escape attempt: %s", path)
	}

	// Open file
	file, err := os.Open(fullPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("file not found: %s", path)
		}
		return nil, fmt.Errorf("failed to open file: %w", err)
	}

	return file, nil
}

// Delete removes a file from filesystem
func (fs *FilesystemStorage) Delete(ctx context.Context, path string) error {
	fullPath := filepath.Join(fs.baseDir, path)

	// Security: Ensure path doesn't escape base directory
	absPath, err := filepath.Abs(fullPath)
	if err != nil {
		return fmt.Errorf("invalid path: %w", err)
	}

	absBaseDir, err := filepath.Abs(fs.baseDir)
	if err != nil {
		return fmt.Errorf("invalid base directory: %w", err)
	}

	if !strings.HasPrefix(absPath, absBaseDir) {
		return fmt.Errorf("path escape attempt: %s", path)
	}

	// Delete file
	if err := os.Remove(fullPath); err != nil {
		if os.IsNotExist(err) {
			return nil // Already deleted, consider success
		}
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

// Exists checks if a file exists in filesystem
func (fs *FilesystemStorage) Exists(ctx context.Context, path string) (bool, error) {
	fullPath := filepath.Join(fs.baseDir, path)

	// Security: Ensure path doesn't escape base directory
	absPath, err := filepath.Abs(fullPath)
	if err != nil {
		return false, fmt.Errorf("invalid path: %w", err)
	}

	absBaseDir, err := filepath.Abs(fs.baseDir)
	if err != nil {
		return false, fmt.Errorf("invalid base directory: %w", err)
	}

	if !strings.HasPrefix(absPath, absBaseDir) {
		return false, fmt.Errorf("path escape attempt: %s", path)
	}

	// Check if file exists
	if _, err := os.Stat(fullPath); err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, fmt.Errorf("failed to check file: %w", err)
	}

	return true, nil
}

// GetPublicURL returns the public URL for a file
func (fs *FilesystemStorage) GetPublicURL(path string) string {
	// Ensure path starts with /
	if !strings.HasPrefix(path, "/") {
		path = "/" + path
	}

	return fs.baseURL + path
}

// GetStorageType returns the storage type
func (fs *FilesystemStorage) GetStorageType() string {
	return "filesystem"
}
