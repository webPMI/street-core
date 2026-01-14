package helpers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TestConfig holds configuration for test environment
type TestConfig struct {
	// MongoDB test configuration
	MongoURI string
	DBName   string

	// JWT test configuration
	JWTSecret    string
	JWTExpiresIn time.Duration

	// Server configuration
	ServerPort string
}

// DefaultTestConfig returns default test configuration
func DefaultTestConfig() *TestConfig {
	return &TestConfig{
		MongoURI:     "mongodb://localhost:27017",
		DBName:       "fitriders_test",
		JWTSecret:    "test-secret-key-for-testing-purposes-only",
		JWTExpiresIn: 1 * time.Hour,
		ServerPort:   "8081",
	}
}

// SetupTestRouter creates a gin router configured for testing
func SetupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(gin.Recovery())
	return router
}

// CreateTestContext creates a gin context for testing
func CreateTestContext() (*gin.Context, *httptest.ResponseRecorder) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	return c, w
}

// CreateTestContextWithRequest creates a gin context with a custom request
func CreateTestContextWithRequest(method, path string, body interface{}) (*gin.Context, *httptest.ResponseRecorder) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	var req *http.Request
	if body != nil {
		jsonBody, _ := json.Marshal(body)
		req = httptest.NewRequest(method, path, bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
	} else {
		req = httptest.NewRequest(method, path, nil)
	}

	c.Request = req
	return c, w
}

// CreateAuthenticatedContext creates a context with authentication info
func CreateAuthenticatedContext(userID string, role string) (*gin.Context, *httptest.ResponseRecorder) {
	c, w := CreateTestContext()
	c.Set("userID", userID)
	c.Set("userRole", role)
	return c, w
}

// NewTestObjectID generates a new MongoDB ObjectID for testing
func NewTestObjectID() primitive.ObjectID {
	return primitive.NewObjectID()
}

// NewTestObjectIDHex generates a new MongoDB ObjectID and returns its hex string
func NewTestObjectIDHex() string {
	return primitive.NewObjectID().Hex()
}

// AssertJSONResponse asserts that the response is valid JSON and returns the parsed body
func AssertJSONResponse(t *testing.T, w *httptest.ResponseRecorder, expectedStatus int) map[string]interface{} {
	t.Helper()
	require.Equal(t, expectedStatus, w.Code, "Unexpected status code")
	require.Contains(t, w.Header().Get("Content-Type"), "application/json")

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err, "Response body should be valid JSON")

	return response
}

// AssertErrorResponse asserts that the response is an error response
func AssertErrorResponse(t *testing.T, w *httptest.ResponseRecorder, expectedStatus int, expectedMessage string) {
	t.Helper()
	response := AssertJSONResponse(t, w, expectedStatus)

	status, ok := response["status"]
	require.True(t, ok, "Response should have 'status' field")
	require.Equal(t, "error", status, "Status should be 'error'")

	if expectedMessage != "" {
		message, ok := response["message"]
		require.True(t, ok, "Response should have 'message' field")
		require.Contains(t, message, expectedMessage, "Error message should contain expected text")
	}
}

// AssertSuccessResponse asserts that the response is a success response
func AssertSuccessResponse(t *testing.T, w *httptest.ResponseRecorder) map[string]interface{} {
	t.Helper()
	response := AssertJSONResponse(t, w, http.StatusOK)

	status, ok := response["status"]
	require.True(t, ok, "Response should have 'status' field")
	require.Equal(t, "success", status, "Status should be 'success'")

	return response
}

// TimeoutContext creates a context with timeout for testing
func TimeoutContext(timeout time.Duration) (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), timeout)
}

// DefaultTimeoutContext creates a context with 5 second timeout
func DefaultTimeoutContext() (context.Context, context.CancelFunc) {
	return TimeoutContext(5 * time.Second)
}

// TestUser represents a user for testing
type TestUser struct {
	ID        primitive.ObjectID
	Email     string
	Password  string
	FirstName string
	LastName  string
	Role      string
}

// NewTestUser creates a new test user with default values
func NewTestUser() *TestUser {
	return &TestUser{
		ID:        primitive.NewObjectID(),
		Email:     "testuser@example.com",
		Password:  "TestPassword123!",
		FirstName: "Test",
		LastName:  "User",
		Role:      "user",
	}
}

// NewTestAdmin creates a new test admin user
func NewTestAdmin() *TestUser {
	return &TestUser{
		ID:        primitive.NewObjectID(),
		Email:     "admin@example.com",
		Password:  "AdminPassword123!",
		FirstName: "Admin",
		LastName:  "User",
		Role:      "admin",
	}
}

// WaitForCondition waits for a condition to be true or times out
func WaitForCondition(timeout time.Duration, interval time.Duration, condition func() bool) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if condition() {
			return true
		}
		time.Sleep(interval)
	}
	return false
}
