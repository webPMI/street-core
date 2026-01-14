package storage

import (
	"context"
	"fmt"
	"io"
)

// HybridStorage implements Storage interface using a primary and fallback storage.
// This allows gradual migration from filesystem to S3:
// - New uploads go to primary (S3)
// - Reads check primary first, then fallback (filesystem)
// - Background migration moves old files from fallback to primary
type HybridStorage struct {
	primary  Storage   // Primary storage (usually S3)
	fallback Storage   // Fallback storage (usually filesystem)
	migrator *Migrator // Background migrator (optional)
}

// NewHybridStorage creates a new hybrid storage instance
func NewHybridStorage(primary, fallback Storage, migrator *Migrator) *HybridStorage {
	return &HybridStorage{
		primary:  primary,
		fallback: fallback,
		migrator: migrator,
	}
}

// Save stores a file to primary storage only (new uploads go to S3)
func (h *HybridStorage) Save(ctx context.Context, file io.Reader, path string, metadata Metadata) (*SaveResult, error) {
	// All new uploads go to primary storage (S3)
	result, err := h.primary.Save(ctx, file, path, metadata)
	if err != nil {
		return nil, fmt.Errorf("failed to save to primary storage: %w", err)
	}

	return result, nil
}

// Get retrieves a file from primary first, then fallback if not found
func (h *HybridStorage) Get(ctx context.Context, path string) (io.ReadCloser, error) {
	// Try primary storage first (S3)
	exists, err := h.primary.Exists(ctx, path)
	if err == nil && exists {
		return h.primary.Get(ctx, path)
	}

	// Fallback to filesystem if not in S3
	exists, err = h.fallback.Exists(ctx, path)
	if err != nil {
		return nil, fmt.Errorf("file not found in any storage: %s", path)
	}

	if !exists {
		return nil, fmt.Errorf("file not found: %s", path)
	}

	// Return from fallback
	return h.fallback.Get(ctx, path)
}

// Delete removes a file from both storages
func (h *HybridStorage) Delete(ctx context.Context, path string) error {
	// Delete from primary (ignore errors if not exists)
	_ = h.primary.Delete(ctx, path)

	// Delete from fallback (ignore errors if not exists)
	_ = h.fallback.Delete(ctx, path)

	return nil
}

// Exists checks if a file exists in either storage
func (h *HybridStorage) Exists(ctx context.Context, path string) (bool, error) {
	// Check primary first
	exists, err := h.primary.Exists(ctx, path)
	if err == nil && exists {
		return true, nil
	}

	// Check fallback
	return h.fallback.Exists(ctx, path)
}

// GetPublicURL returns the public URL from primary storage
// This assumes the file will eventually be migrated to primary
func (h *HybridStorage) GetPublicURL(path string) string {
	// Always use primary storage URL (S3)
	// This ensures URLs remain stable after migration
	return h.primary.GetPublicURL(path)
}

// GetStorageType returns the storage type
func (h *HybridStorage) GetStorageType() string {
	return fmt.Sprintf("hybrid(%s+%s)", h.primary.GetStorageType(), h.fallback.GetStorageType())
}

// GetPrimaryStorage returns the primary storage (for migration purposes)
func (h *HybridStorage) GetPrimaryStorage() Storage {
	return h.primary
}

// GetFallbackStorage returns the fallback storage (for migration purposes)
func (h *HybridStorage) GetFallbackStorage() Storage {
	return h.fallback
}

// GetMigrator returns the migrator instance
func (h *HybridStorage) GetMigrator() *Migrator {
	return h.migrator
}
