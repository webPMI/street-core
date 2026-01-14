package storage

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestFilesystemStorage_Save(t *testing.T) {
	// Create temporary directory for testing
	tempDir := filepath.Join(os.TempDir(), "test-filesystem-storage")
	defer os.RemoveAll(tempDir)

	// Create filesystem storage
	storage, err := NewFilesystemStorage(tempDir, "http://localhost:3000/uploads")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	// Test data
	testData := "Hello, World!"
	testPath := "test/file.txt"
	metadata := Metadata{
		ContentType: "text/plain",
		Size:        int64(len(testData)),
	}

	// Save file
	ctx := context.Background()
	result, err := storage.Save(ctx, strings.NewReader(testData), testPath, metadata)
	if err != nil {
		t.Fatalf("Failed to save file: %v", err)
	}

	// Verify result
	if result.Path != testPath {
		t.Errorf("Expected path %s, got %s", testPath, result.Path)
	}

	if result.Size != int64(len(testData)) {
		t.Errorf("Expected size %d, got %d", len(testData), result.Size)
	}

	if result.PublicURL != "http://localhost:3000/uploads/"+testPath {
		t.Errorf("Expected URL http://localhost:3000/uploads/%s, got %s", testPath, result.PublicURL)
	}

	// Verify file exists on disk
	fullPath := filepath.Join(tempDir, testPath)
	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		t.Error("File was not created on disk")
	}

	// Verify file content
	content, err := os.ReadFile(fullPath)
	if err != nil {
		t.Fatalf("Failed to read file: %v", err)
	}

	if string(content) != testData {
		t.Errorf("Expected content %s, got %s", testData, string(content))
	}
}

func TestFilesystemStorage_Get(t *testing.T) {
	// Create temporary directory for testing
	tempDir := filepath.Join(os.TempDir(), "test-filesystem-storage-get")
	defer os.RemoveAll(tempDir)

	// Create filesystem storage
	storage, err := NewFilesystemStorage(tempDir, "http://localhost:3000/uploads")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	// Test data
	testData := "Test content"
	testPath := "test/file.txt"

	// Save file first
	ctx := context.Background()
	metadata := Metadata{ContentType: "text/plain"}
	_, err = storage.Save(ctx, strings.NewReader(testData), testPath, metadata)
	if err != nil {
		t.Fatalf("Failed to save file: %v", err)
	}

	// Get file
	reader, err := storage.Get(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to get file: %v", err)
	}
	defer reader.Close()

	// Verify content
	content := make([]byte, len(testData))
	n, err := reader.Read(content)
	if err != nil {
		t.Fatalf("Failed to read content: %v", err)
	}

	if n != len(testData) {
		t.Errorf("Expected to read %d bytes, read %d", len(testData), n)
	}

	if string(content) != testData {
		t.Errorf("Expected content %s, got %s", testData, string(content))
	}
}

func TestFilesystemStorage_Delete(t *testing.T) {
	// Create temporary directory for testing
	tempDir := filepath.Join(os.TempDir(), "test-filesystem-storage-delete")
	defer os.RemoveAll(tempDir)

	// Create filesystem storage
	storage, err := NewFilesystemStorage(tempDir, "http://localhost:3000/uploads")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	// Test data
	testPath := "test/file.txt"

	// Save file first
	ctx := context.Background()
	metadata := Metadata{ContentType: "text/plain"}
	_, err = storage.Save(ctx, strings.NewReader("test"), testPath, metadata)
	if err != nil {
		t.Fatalf("Failed to save file: %v", err)
	}

	// Verify file exists
	exists, err := storage.Exists(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to check existence: %v", err)
	}
	if !exists {
		t.Error("File should exist before deletion")
	}

	// Delete file
	err = storage.Delete(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to delete file: %v", err)
	}

	// Verify file no longer exists
	exists, err = storage.Exists(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to check existence: %v", err)
	}
	if exists {
		t.Error("File should not exist after deletion")
	}
}

func TestFilesystemStorage_Exists(t *testing.T) {
	// Create temporary directory for testing
	tempDir := filepath.Join(os.TempDir(), "test-filesystem-storage-exists")
	defer os.RemoveAll(tempDir)

	// Create filesystem storage
	storage, err := NewFilesystemStorage(tempDir, "http://localhost:3000/uploads")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	ctx := context.Background()
	testPath := "test/file.txt"

	// Check non-existent file
	exists, err := storage.Exists(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to check existence: %v", err)
	}
	if exists {
		t.Error("File should not exist")
	}

	// Save file
	metadata := Metadata{ContentType: "text/plain"}
	_, err = storage.Save(ctx, strings.NewReader("test"), testPath, metadata)
	if err != nil {
		t.Fatalf("Failed to save file: %v", err)
	}

	// Check existent file
	exists, err = storage.Exists(ctx, testPath)
	if err != nil {
		t.Fatalf("Failed to check existence: %v", err)
	}
	if !exists {
		t.Error("File should exist")
	}
}

func TestFilesystemStorage_PathEscapeAttempt(t *testing.T) {
	// Create temporary directory for testing
	tempDir := filepath.Join(os.TempDir(), "test-filesystem-storage-security")
	defer os.RemoveAll(tempDir)

	// Create filesystem storage
	storage, err := NewFilesystemStorage(tempDir, "http://localhost:3000/uploads")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	ctx := context.Background()

	// Try path escape attacks
	maliciousPaths := []string{
		"../etc/passwd",
		"../../secret.txt",
		"test/../../etc/passwd",
	}

	for _, path := range maliciousPaths {
		_, err := storage.Get(ctx, path)
		if err == nil {
			t.Errorf("Expected error for malicious path %s, got nil", path)
		}

		if !strings.Contains(err.Error(), "path escape") {
			t.Errorf("Expected path escape error for %s, got: %v", path, err)
		}
	}
}

func TestFilesystemStorage_GetPublicURL(t *testing.T) {
	storage, err := NewFilesystemStorage("./uploads", "http://localhost:3000/uploads")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	tests := []struct {
		path     string
		expected string
	}{
		{"test/file.txt", "http://localhost:3000/uploads/test/file.txt"},
		{"/test/file.txt", "http://localhost:3000/uploads/test/file.txt"},
		{"images/avatar.jpg", "http://localhost:3000/uploads/images/avatar.jpg"},
	}

	for _, tt := range tests {
		result := storage.GetPublicURL(tt.path)
		if result != tt.expected {
			t.Errorf("GetPublicURL(%s) = %s, expected %s", tt.path, result, tt.expected)
		}
	}
}

func TestFilesystemStorage_GetStorageType(t *testing.T) {
	storage, err := NewFilesystemStorage("./uploads", "http://localhost:3000")
	if err != nil {
		t.Fatalf("Failed to create filesystem storage: %v", err)
	}

	expected := "filesystem"
	result := storage.GetStorageType()

	if result != expected {
		t.Errorf("Expected storage type %s, got %s", expected, result)
	}
}
