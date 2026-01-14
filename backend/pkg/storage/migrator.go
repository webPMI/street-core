package storage

import (
	"backend/utils"
	"context"
	"fmt"
	"time"
)

// MediaRepository defines the interface for media database operations
// This must be implemented by the actual media repository
type MediaRepository interface {
	// GetUnmigratedFiles returns a list of files that haven't been migrated yet
	GetUnmigratedFiles(ctx context.Context, limit int) ([]UnmigratedFile, error)

	// UpdateFilePath updates the file path in the database after migration
	UpdateFilePath(ctx context.Context, oldPath, newPath string) error

	// MarkAsMigrated marks a file as migrated to S3
	MarkAsMigrated(ctx context.Context, filePath string, migratedAt time.Time) error
}

// UnmigratedFile represents a file that needs to be migrated
type UnmigratedFile struct {
	FilePath   string
	FileSize   int64
	UploadedAt time.Time
}

// Migrator handles background migration of files from source to destination storage
type Migrator struct {
	source      Storage         // Source storage (filesystem)
	destination Storage         // Destination storage (S3)
	repo        MediaRepository // Database repository
	batchSize   int             // Number of files to migrate per batch
	running     bool            // Is migration running?
	stopCh      chan struct{}   // Channel to stop migration
}

// NewMigrator creates a new migrator instance
func NewMigrator(source, dest Storage, repo MediaRepository, batchSize int) *Migrator {
	if batchSize <= 0 {
		batchSize = 100
	}

	return &Migrator{
		source:      source,
		destination: dest,
		repo:        repo,
		batchSize:   batchSize,
		stopCh:      make(chan struct{}),
	}
}

// MigrateFile migrates a single file from source to destination
func (m *Migrator) MigrateFile(ctx context.Context, filePath string) error {
	// 1. Check if file exists in source
	exists, err := m.source.Exists(ctx, filePath)
	if err != nil {
		return fmt.Errorf("failed to check source: %w", err)
	}

	if !exists {
		return fmt.Errorf("file not found in source: %s", filePath)
	}

	// 2. Read from source
	reader, err := m.source.Get(ctx, filePath)
	if err != nil {
		return fmt.Errorf("failed to read from source: %w", err)
	}
	defer reader.Close()

	// 3. Save to destination (with minimal metadata)
	metadata := Metadata{
		ContentType: "application/octet-stream", // Generic, will be detected
	}

	result, err := m.destination.Save(ctx, reader, filePath, metadata)
	if err != nil {
		return fmt.Errorf("failed to save to destination: %w", err)
	}

	// 4. Mark as migrated in database
	if err := m.repo.MarkAsMigrated(ctx, filePath, time.Now()); err != nil {
		// Log warning but don't fail - file is already in S3
		utils.WarnWithTag("Storage", "Failed to mark file as migrated", map[string]interface{}{
			"error": err.Error(),
			"file":  filePath,
		})
	}

	utils.InfoWithTag("Storage", "File migrated successfully", map[string]interface{}{
		"file":        filePath,
		"destination": result.Path,
		"size":        result.Size,
	})

	return nil
}

// MigrateBatch migrates a batch of files
func (m *Migrator) MigrateBatch(ctx context.Context) (int, error) {
	// Get files that need migration
	files, err := m.repo.GetUnmigratedFiles(ctx, m.batchSize)
	if err != nil {
		return 0, fmt.Errorf("failed to get unmigrated files: %w", err)
	}

	if len(files) == 0 {
		return 0, nil // No files to migrate
	}

	migrated := 0
	failed := 0

	for _, file := range files {
		if err := m.MigrateFile(ctx, file.FilePath); err != nil {
			utils.ErrorWithTag("Storage", "Failed to migrate file", map[string]interface{}{
				"error": err.Error(),
				"file":  file.FilePath,
			})
			failed++
			continue
		}
		migrated++
	}

	utils.InfoWithTag("Storage", "Migration batch complete", map[string]interface{}{
		"migrated": migrated,
		"failed":   failed,
		"total":    len(files),
	})

	return migrated, nil
}

// Run starts the background migration process
func (m *Migrator) Run(ctx context.Context, interval time.Duration) {
	if m.running {
		utils.WarnWithTag("Storage", "Migrator already running", nil)
		return
	}

	m.running = true
	utils.InfoWithTag("Storage", "Starting background migration", map[string]interface{}{
		"interval":   interval.String(),
		"batch_size": m.batchSize,
	})

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			count, err := m.MigrateBatch(ctx)
			if err != nil {
				utils.ErrorWithTag("Storage", "Migration batch error", map[string]interface{}{
					"error": err.Error(),
				})
			}

			if count > 0 {
				utils.InfoWithTag("Storage", "Files migrated to S3", map[string]interface{}{
					"count": count,
				})
			}

		case <-m.stopCh:
			utils.InfoWithTag("Storage", "Stopping background migration", nil)
			m.running = false
			return

		case <-ctx.Done():
			utils.InfoWithTag("Storage", "Context cancelled, stopping migration", nil)
			m.running = false
			return
		}
	}
}

// Stop stops the background migration process
func (m *Migrator) Stop() {
	if m.running {
		close(m.stopCh)
	}
}

// IsRunning returns true if migration is currently running
func (m *Migrator) IsRunning() bool {
	return m.running
}

// GetStats returns migration statistics (to be implemented with actual metrics)
type MigrationStats struct {
	TotalFiles        int64
	MigratedFiles     int64
	RemainingFiles    int64
	LastMigrationTime time.Time
	ErrorCount        int64
}

// GetStats returns current migration statistics
func (m *Migrator) GetStats(ctx context.Context) (*MigrationStats, error) {
	// This would query the database for actual statistics
	// For now, return a placeholder
	return &MigrationStats{
		TotalFiles:        0,
		MigratedFiles:     0,
		RemainingFiles:    0,
		LastMigrationTime: time.Now(),
		ErrorCount:        0,
	}, nil
}
