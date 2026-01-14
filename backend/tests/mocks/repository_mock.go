package mocks

import (
	"context"
	"errors"
	"sync"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Common mock errors
var (
	ErrMockNotFound     = errors.New("document not found")
	ErrMockDuplicate    = errors.New("duplicate key error")
	ErrMockInternal     = errors.New("internal error")
	ErrMockUnauthorized = errors.New("unauthorized")
)

// MockRepository is a generic mock repository for testing
type MockRepository[T any] struct {
	mu        sync.RWMutex
	data      map[primitive.ObjectID]*T
	createErr error
	updateErr error
	deleteErr error
	findErr   error
}

// NewMockRepository creates a new mock repository
func NewMockRepository[T any]() *MockRepository[T] {
	return &MockRepository[T]{
		data: make(map[primitive.ObjectID]*T),
	}
}

// SetCreateError sets an error to return on Create
func (m *MockRepository[T]) SetCreateError(err error) {
	m.createErr = err
}

// SetUpdateError sets an error to return on Update
func (m *MockRepository[T]) SetUpdateError(err error) {
	m.updateErr = err
}

// SetDeleteError sets an error to return on Delete
func (m *MockRepository[T]) SetDeleteError(err error) {
	m.deleteErr = err
}

// SetFindError sets an error to return on Find operations
func (m *MockRepository[T]) SetFindError(err error) {
	m.findErr = err
}

// GetByID retrieves a document by ID
func (m *MockRepository[T]) GetByID(ctx context.Context, id primitive.ObjectID) (*T, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if m.findErr != nil {
		return nil, m.findErr
	}

	if doc, ok := m.data[id]; ok {
		return doc, nil
	}
	return nil, nil
}

// Create inserts a new document
func (m *MockRepository[T]) Create(ctx context.Context, entity *T) (*T, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.createErr != nil {
		return nil, m.createErr
	}

	id := primitive.NewObjectID()
	m.data[id] = entity
	return entity, nil
}

// Update updates a document
func (m *MockRepository[T]) Update(ctx context.Context, id primitive.ObjectID, update bson.M) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.updateErr != nil {
		return m.updateErr
	}

	if _, ok := m.data[id]; !ok {
		return ErrMockNotFound
	}
	return nil
}

// Delete removes a document
func (m *MockRepository[T]) Delete(ctx context.Context, id primitive.ObjectID) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.deleteErr != nil {
		return m.deleteErr
	}

	delete(m.data, id)
	return nil
}

// Count returns the number of documents
func (m *MockRepository[T]) Count(ctx context.Context, filter bson.M) (int64, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if m.findErr != nil {
		return 0, m.findErr
	}

	return int64(len(m.data)), nil
}

// Exists checks if a document exists
func (m *MockRepository[T]) Exists(ctx context.Context, filter bson.M) (bool, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if m.findErr != nil {
		return false, m.findErr
	}

	return len(m.data) > 0, nil
}

// AddTestData adds test data to the mock repository
func (m *MockRepository[T]) AddTestData(id primitive.ObjectID, entity *T) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.data[id] = entity
}

// Clear removes all data from the mock repository
func (m *MockRepository[T]) Clear() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.data = make(map[primitive.ObjectID]*T)
}

// GetAll returns all stored data (for testing purposes)
func (m *MockRepository[T]) GetAll() map[primitive.ObjectID]*T {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make(map[primitive.ObjectID]*T)
	for k, v := range m.data {
		result[k] = v
	}
	return result
}
