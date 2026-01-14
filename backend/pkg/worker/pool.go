package worker

import (
	"context"
	"sync"

	"backend/utils"
)

// WorkerPool manages a pool of workers for processing jobs asynchronously
// This prevents goroutine leaks and provides graceful shutdown capabilities
type WorkerPool struct {
	jobs      chan func()      // Channel for job submissions
	workers   int              // Number of worker goroutines
	semaphore chan struct{}    // Semaphore to limit concurrent jobs
	wg        sync.WaitGroup   // WaitGroup to track active jobs
	once      sync.Once        // Ensure shutdown only happens once
	done      chan struct{}    // Signal shutdown
	mu        sync.Mutex       // Protects shutdown state
	isShutdown bool            // Tracks if pool is shut down
}

// NewWorkerPool creates a new worker pool with the specified number of workers
// workers: number of concurrent goroutines to process jobs
func NewWorkerPool(workers int) *WorkerPool {
	if workers <= 0 {
		workers = 10 // Default to 10 workers
	}

	pool := &WorkerPool{
		jobs:      make(chan func(), workers*2), // Buffered channel for smoother operation
		workers:   workers,
		semaphore: make(chan struct{}, workers),
		done:      make(chan struct{}),
	}

	// Start worker goroutines
	for i := 0; i < workers; i++ {
		go pool.worker(i)
	}

	utils.Info("Worker pool initialized", map[string]interface{}{
		"workers": workers,
	})

	return pool
}

// worker is the main worker goroutine that processes jobs from the queue
func (p *WorkerPool) worker(id int) {
	for {
		select {
		case <-p.done:
			// Shutdown signal received
			return
		case job := <-p.jobs:
			if job == nil {
				// Nil job signals worker to stop
				return
			}

			// Execute the job
			func() {
				defer func() {
					if r := recover(); r != nil {
						utils.Error("Worker panic recovered", map[string]interface{}{
							"worker": id,
							"panic":  r,
						})
					}
					p.wg.Done()
				}()
				job()
			}()
		}
	}
}

// Submit adds a job to the worker pool for asynchronous processing
// Blocks if the job queue is full until a worker is available
func (p *WorkerPool) Submit(job func()) error {
	p.mu.Lock()
	if p.isShutdown {
		p.mu.Unlock()
		return ErrPoolShutdown
	}
	p.mu.Unlock()

	p.wg.Add(1)

	select {
	case <-p.done:
		p.wg.Done()
		return ErrPoolShutdown
	case p.jobs <- job:
		return nil
	}
}

// Shutdown gracefully shuts down the worker pool
// It waits for all currently executing jobs to complete or until context is canceled
func (p *WorkerPool) Shutdown(ctx context.Context) error {
	var shutdownErr error

	p.once.Do(func() {
		p.mu.Lock()
		p.isShutdown = true
		p.mu.Unlock()

		utils.Info("Worker pool shutting down", map[string]interface{}{
			"workers": p.workers,
		})

		// Signal all workers to stop
		close(p.done)

		// Wait for all jobs to complete or context timeout
		done := make(chan struct{})
		go func() {
			p.wg.Wait()
			close(done)
		}()

		select {
		case <-done:
			// All jobs completed successfully
			utils.Info("Worker pool shutdown complete", nil)
		case <-ctx.Done():
			// Context timeout, some jobs may not have completed
			utils.Warn("Worker pool shutdown timeout", map[string]interface{}{
				"error": ctx.Err().Error(),
			})
			shutdownErr = ctx.Err()
		}

		// Close jobs channel
		close(p.jobs)
	})

	return shutdownErr
}

// ActiveWorkers returns the number of workers in the pool
func (p *WorkerPool) ActiveWorkers() int {
	return p.workers
}

// Size returns the current number of pending jobs
func (p *WorkerPool) Size() int {
	return len(p.jobs)
}

var (
	// ErrPoolShutdown is returned when trying to submit to a shut down pool
	ErrPoolShutdown = &WorkerError{Message: "worker pool is shut down"}
)

// WorkerError represents an error from the worker pool
type WorkerError struct {
	Message string
}

func (e *WorkerError) Error() string {
	return e.Message
}
