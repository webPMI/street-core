package storage

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// MockStorage is a simple in-memory storage for testing
type MockStorage struct {
	files       map[string]string // path -> content
	storageType string
	baseURL     string
}

func NewMockStorage(storageType, baseURL string) *MockStorage {
	return &MockStorage{
		files:       make(map[string]string),
		storageType: storageType,
		baseURL:     baseURL,
	}
}

func (m *MockStorage) Save(ctx context.Context, file interface{}, path string, metadata Metadata) (*SaveResult, error) {
	// For testing, we'll just store a placeholder
	m.files[path] = "content"

	return &SaveResult{
		Path:      path,
		PublicURL: m.GetPublicURL(path),
		Size:      10,
		Hash:      "abc123",
	}, nil
}

func (m *MockStorage) Get(ctx context.Context, path string) (interface{}, error) {
	if _, exists := m.files[path]; !exists {
		return nil, os.ErrNotExist
	}
	return strings.NewReader(m.files[path]), nil
}

func (m *MockStorage) Delete(ctx context.Context, path string) error {
	delete(m.files, path)
	return nil
}

func (m *MockStorage) Exists(ctx context.Context, path string) (bool, error) {
	_, exists := m.files[path]
	return exists, nil
}

func (m *MockStorage) GetPublicURL(path string) string {
	return m.baseURL + "/" + path
}

func (m *MockStorage) GetStorageType() string {
	return m.storageType
}

func TestHybridStorage_Save(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()
	testPath := "test/file.txt"
	metadata := Metadata{ContentType: "text/plain"}

	// Save file (should go to primary)
	result, err := hybrid.Save(ctx, strings.NewReader("test"), testPath, metadata)
	if err != nil {
		t.Fatalf("Failed to save file: %v", err)
	}

	// Verify file is in primary storage
	existsInPrimary, _ := primary.Exists(ctx, testPath)
	if !existsInPrimary {
		t.Error("File should exist in primary storage")
	}

	// Verify file is NOT in fallback storage
	existsInFallback, _ := fallback.Exists(ctx, testPath)
	if existsInFallback {
		t.Error("File should NOT exist in fallback storage")
	}

	// Verify public URL is from primary storage
	if !strings.Contains(result.PublicURL, "s3.amazonaws.com") {
		t.Errorf("Expected S3 URL, got %s", result.PublicURL)
	}
}

func TestHybridStorage_Get_FromPrimary(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()
	testPath := "test/file.txt"

	// Add file to primary storage
	primary.files[testPath] = "content from primary"

	// Get file (should come from primary)
	reader, err := hybrid.Get(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to get file: %v", err)
	}

	if reader == nil {
		t.Error("Expected reader, got nil")
	}
}

func TestHybridStorage_Get_FromFallback(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()
	testPath := "old/file.txt"

	// Add file ONLY to fallback storage (simulating old file)
	fallback.files[testPath] = "content from fallback"

	// Get file (should come from fallback)
	reader, err := hybrid.Get(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to get file: %v", err)
	}

	if reader == nil {
		t.Error("Expected reader, got nil")
	}
}

func TestHybridStorage_Get_NotFound(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()
	testPath := "nonexistent/file.txt"

	// Try to get non-existent file
	_, err := hybrid.Get(ctx, testPath)
	if err == nil {
		t.Error("Expected error for non-existent file, got nil")
	}
}

func TestHybridStorage_Delete(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()
	testPath := "test/file.txt"

	// Add file to both storages
	primary.files[testPath] = "content"
	fallback.files[testPath] = "content"

	// Delete file (should delete from both)
	err := hybrid.Delete(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to delete file: %v", err)
	}

	// Verify file is deleted from primary
	existsInPrimary, _ := primary.Exists(ctx, testPath)
	if existsInPrimary {
		t.Error("File should be deleted from primary storage")
	}

	// Verify file is deleted from fallback
	existsInFallback, _ := fallback.Exists(ctx, testPath)
	if existsInFallback {
		t.Error("File should be deleted from fallback storage")
	}
}

func TestHybridStorage_Exists_InPrimary(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()
	testPath := "test/file.txt"

	// Add file to primary
	primary.files[testPath] = "content"

	// Check existence
	exists, err := hybrid.Exists(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to check existence: %v", err)
	}

	if !exists {
		t.Error("File should exist in hybrid storage")
	}
}

func TestHybridStorage_Exists_InFallback(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()
	testPath := "old/file.txt"

	// Add file to fallback only
	fallback.files[testPath] = "content"

	// Check existence
	exists, err := hybrid.Exists(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to check existence: %v", err)
	}

	if !exists {
		t.Error("File should exist in hybrid storage")
	}
}

func TestHybridStorage_GetPublicURL(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	testPath := "test/file.txt"

	// Get public URL (should always use primary)
	url := hybrid.GetPublicURL(testPath)

	if !strings.Contains(url, "s3.amazonaws.com") {
		t.Errorf("Expected S3 URL, got %s", url)
	}
}

func TestHybridStorage_GetStorageType(t *testing.T) {
	// Create mock storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback := NewMockStorage("filesystem", "http://localhost:3000/uploads")

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	storageType := hybrid.GetStorageType()
	expected := "hybrid(s3+filesystem)"

	if storageType != expected {
		t.Errorf("Expected storage type %s, got %s", expected, storageType)
	}
}

func TestHybridStorage_Integration(t *testing.T) {
	// Create real filesystem storage for integration test
	tempDir := filepath.Join(os.TempDir(), "test-hybrid-integration")
	defer os.RemoveAll(tempDir)

	// Create storages
	primary := NewMockStorage("s3", "https://s3.amazonaws.com/bucket")
	fallback, err := NewFilesystemStorage(tempDir, "http://localhost:3000/uploads")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	// Create hybrid storage
	hybrid := NewHybridStorage(primary, fallback, nil)

	ctx := context.Background()

	// Scenario 1: Add old file to fallback
	oldPath := "old/legacy.txt"
	fallbackFile := filepath.Join(tempDir, oldPath)
	os.MkdirAll(filepath.Dir(fallbackFile), 0755)
	os.WriteFile(fallbackFile, []byte("legacy content"), 0644)

	// Verify can read old file from fallback
	exists, _ := hybrid.Exists(ctx, oldPath)
	if !exists {
		t.Error("Old file should be accessible through hybrid storage")
	}

	// Scenario 2: Add new file (should go to primary)
	newPath := "new/file.txt"
	metadata := Metadata{ContentType: "text/plain"}
	_, err = hybrid.Save(ctx, strings.NewReader("new content"), newPath, metadata)
	if err != nil {
		t.Fatalf("Failed to save new file: %v", err)
	}

	// Verify new file is in primary, not fallback
	existsInPrimary, _ := primary.Exists(ctx, newPath)
	if !existsInPrimary {
		t.Error("New file should be in primary storage")
	}

	existsInFallback, _ := fallback.Exists(ctx, newPath)
	if existsInFallback {
		t.Error("New file should NOT be in fallback storage")
	}
}
