package media

import (
	"context"
	"time"

	"backend/utils"

	"go.mongodb.org/mongo-driver/mongo"
)

// Module contains all media-related components
type Module struct {
	Repository IMediaRepository
	Service    IMediaService
	Processor  IMediaProcessor
	Handler    *mediaHandler
}

// NewModule creates a new media module with all dependencies
func NewModule(db *mongo.Database) *Module {
	// Create repository
	repo := NewMediaRepository(db)

	// Create processor
	processor := NewMediaProcessor()

	// Create service
	service := NewMediaService(repo, processor)

	// Create handler
	handler := NewMediaHandler(service)

	return &Module{
		Repository: repo,
		Service:    service,
		Processor:  processor,
		Handler:    handler,
	}
}

// StartBackgroundJobs starts background processing jobs
func (m *Module) StartBackgroundJobs(ctx context.Context) {
	// Start periodic cleanup of orphaned files
	go m.runPeriodicCleanup(ctx)

	// Start periodic processing of pending files
	go m.runPeriodicProcessing(ctx)
}

// runPeriodicCleanup runs the orphaned file cleanup periodically
func (m *Module) runPeriodicCleanup(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			utils.Info("Media cleanup job stopped", nil)
			return
		case <-ticker.C:
			if err := m.Service.CleanupOrphanedFiles(ctx); err != nil {
				utils.Error("Orphaned files cleanup failed", map[string]interface{}{
					"error": err.Error(),
				})
			}
		}
	}
}

// runPeriodicProcessing processes pending files periodically with exponential backoff
// Reduces polling frequency when there's no work to do
func (m *Module) runPeriodicProcessing(ctx context.Context) {
	interval := 30 * time.Second
	maxInterval := 5 * time.Minute
	minInterval := 30 * time.Second

	utils.Info("Media processing job started", map[string]interface{}{
		"initial_interval": interval,
		"max_interval":     maxInterval,
	})

	for {
		select {
		case <-ctx.Done():
			utils.Info("Media processing job stopped", nil)
			return
		case <-time.After(interval):
			// Process pending files and get count
			count, err := m.Service.ProcessPendingFiles(ctx)
			if err != nil {
				utils.Error("Pending files processing failed", map[string]interface{}{
					"error": err.Error(),
				})
				// Don't change interval on error
				continue
			}

			// Adjust interval based on workload
			if count == 0 {
				// No work - exponential backoff
				interval = min(interval*2, maxInterval)
				utils.Debug("No pending files, increasing interval", map[string]interface{}{
					"new_interval": interval,
				})
			} else {
				// Work found - reset to minimum interval
				interval = minInterval
				utils.Debug("Processed pending files", map[string]interface{}{
					"count":        count,
					"new_interval": interval,
				})
			}
		}
	}
}

// min returns the minimum of two durations
func min(a, b time.Duration) time.Duration {
	if a < b {
		return a
	}
	return b
}
