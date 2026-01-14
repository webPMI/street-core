package helpers

// This file contains usage examples for the pagination helper utilities.
// It demonstrates how to integrate pagination in handlers, services, and repositories.
//
// DO NOT import this file in production code - it's for documentation only.

import (
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ========================
// Example 1: Basic Handler Usage
// ========================

// ExampleHandler_List demonstrates basic pagination in a list handler
func ExampleHandler_List(c *gin.Context) {
	// Parse pagination params from query string
	// GET /api/items?skip=20&limit=10
	skip, limit := ParsePaginationParams(c)

	// Use in repository call
	// items, err := repository.FindAll(skip, limit)

	// Return response
	c.JSON(200, gin.H{
		"data": []string{"item1", "item2"}, // Your actual data
		"pagination": gin.H{
			"skip":  skip,
			"limit": limit,
		},
	})
}

// ========================
// Example 2: Handler with Total Count
// ========================

// ExampleHandler_ListWithMetadata demonstrates pagination with full metadata
func ExampleHandler_ListWithMetadata(c *gin.Context) {
	// Parse pagination
	skip, limit := ParsePaginationParams(c)

	// Get data from repository
	// items, err := repository.FindAll(skip, limit)
	// totalCount, err := repository.Count()
	var totalCount int64 = 95 // Example total count

	// Generate pagination metadata
	metadata := GetPaginationMetadata(skip, limit, totalCount)

	c.JSON(200, gin.H{
		"data":       []string{"item1", "item2"}, // Your actual data
		"pagination": metadata,
		// Response includes:
		// {
		//   "page": 3,
		//   "pageSize": 20,
		//   "totalPages": 5,
		//   "totalCount": 95,
		//   "hasNextPage": true
		// }
	})
}

// ========================
// Example 3: Repository Integration
// ========================

// ExampleRepository demonstrates how to use pagination in repository methods
type ExampleRepository struct {
	collection *mongo.Collection
}

// FindAll retrieves items with pagination
func (r *ExampleRepository) FindAll(skip, limit int) ([]interface{}, error) {
	// Normalize pagination (safety check in repository layer)
	skip, limit = NormalizePagination(skip, limit)

	// Create MongoDB options
	opts := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(map[string]int{"created_at": -1})

	// Execute query
	cursor, err := r.collection.Find(nil, map[string]interface{}{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(nil)

	var results []interface{}
	if err = cursor.All(nil, &results); err != nil {
		return nil, err
	}

	return results, nil
}

// Count returns total count of items
func (r *ExampleRepository) Count() (int64, error) {
	return r.collection.CountDocuments(nil, map[string]interface{}{})
}

// ========================
// Example 4: Service Layer with Business Logic
// ========================

// ExampleService demonstrates pagination in service layer
type ExampleService struct {
	repository *ExampleRepository
}

// ListItems retrieves paginated items with business logic
func (s *ExampleService) ListItems(skip, limit int, userID string) (map[string]interface{}, error) {
	// Normalize pagination at service level
	skip, limit = NormalizePagination(skip, limit)

	// Apply business logic (e.g., filter by user permissions)
	// items, err := s.repository.FindByUser(userID, skip, limit)

	// Get total count
	totalCount, err := s.repository.Count()
	if err != nil {
		return nil, err
	}

	// Build response
	return map[string]interface{}{
		"data":       []interface{}{}, // Your items
		"pagination": GetPaginationMetadata(skip, limit, totalCount),
	}, nil
}

// ========================
// Example 5: Advanced - Custom Pagination Response
// ========================

// CustomPaginationResponse demonstrates creating a custom pagination structure
type CustomPaginationResponse struct {
	Items      []interface{}          `json:"items"`
	Pagination map[string]interface{} `json:"pagination"`
	Meta       map[string]interface{} `json:"meta"`
}

// ExampleHandler_CustomResponse shows a custom response format
func ExampleHandler_CustomResponse(c *gin.Context) {
	skip, limit := ParsePaginationParams(c)

	// Get data
	// items, _ := service.GetItems(skip, limit)
	// totalCount, _ := service.GetTotalCount()
	var totalCount int64 = 100

	response := CustomPaginationResponse{
		Items:      []interface{}{}, // Your items
		Pagination: GetPaginationMetadata(skip, limit, totalCount),
		Meta: map[string]interface{}{
			"timestamp": "2025-12-24T10:00:00Z",
			"version":   "1.0",
		},
	}

	c.JSON(200, response)
}

// ========================
// Example 6: Manual Normalization
// ========================

// ExampleManualNormalization shows when to use NormalizePagination directly
func ExampleManualNormalization() {
	// When you receive pagination from non-Gin sources
	userProvidedSkip := -10
	userProvidedLimit := 500

	// Normalize before using
	skip, limit := NormalizePagination(userProvidedSkip, userProvidedLimit)
	// Result: skip=0, limit=100 (capped at MaxPageSize)

	// Now safe to use
	_ = skip
	_ = limit
}

// ========================
// Example 7: Testing Pagination
// ========================

// ExampleTestPagination shows how to test handlers with pagination
func ExampleTestPagination() {
	// In your test file:
	//
	// func TestHandler_List(t *testing.T) {
	//     // Setup
	//     gin.SetMode(gin.TestMode)
	//     req := httptest.NewRequest("GET", "/api/items?skip=20&limit=10", nil)
	//     w := httptest.NewRecorder()
	//     c, _ := gin.CreateTestContext(w)
	//     c.Request = req
	//
	//     // Parse pagination
	//     skip, limit := helpers.ParsePaginationParams(c)
	//
	//     // Assertions
	//     assert.Equal(t, 20, skip)
	//     assert.Equal(t, 10, limit)
	// }
}

// ========================
// Example 8: Security - DoS Prevention
// ========================

// ExampleDoSPrevention demonstrates how pagination prevents DoS attacks
func ExampleDoSPrevention(c *gin.Context) {
	// Malicious request: GET /api/items?limit=999999999
	// Without pagination helper: Server tries to load 999M records → crash
	// With pagination helper:

	_, limit := ParsePaginationParams(c)
	// Result: skip=0, limit=100 (capped at MaxPageSize)

	// SAFE: Maximum 100 items returned, prevents:
	// - Memory exhaustion
	// - Database overload
	// - Network bandwidth saturation
	// - Response timeout

	c.JSON(200, gin.H{
		"message": "Protected from DoS attack",
		"limit":   limit, // Always <= 100
	})
}

// ========================
// Example 9: Page Number to Skip Conversion
// ========================

// ExamplePageNumberConversion shows how to work with page numbers
func ExamplePageNumberConversion(c *gin.Context) {
	// If your API uses page numbers instead of skip
	// GET /api/items?page=3&pageSize=20

	page := 3      // From query param
	pageSize := 20 // From query param

	// Convert page number to skip
	skip := (page - 1) * pageSize // skip = 40

	// Normalize
	skip, limit := NormalizePagination(skip, pageSize)

	// Use in query
	_ = skip  // 40
	_ = limit // 20
}

// ========================
// Example 10: Infinite Scroll Support
// ========================

// ExampleInfiniteScroll demonstrates cursor-based pagination for infinite scroll
func ExampleInfiniteScroll(c *gin.Context) {
	skip, limit := ParsePaginationParams(c)

	// Get data
	// items, _ := repository.FindAll(skip, limit)
	var totalCount int64 = 100

	// Calculate next cursor
	nextSkip := skip + limit
	hasMore := HasNextPage(skip, limit, totalCount)

	c.JSON(200, gin.H{
		"items": []interface{}{}, // Your items
		"cursor": gin.H{
			"next":    nextSkip,
			"hasMore": hasMore,
		},
	})
}

// ========================
// Best Practices Summary
// ========================

/*
BEST PRACTICES:

1. ALWAYS use ParsePaginationParams(c) in handlers
   - Automatically validates and normalizes
   - Prevents DoS attacks
   - Consistent behavior across API

2. Use NormalizePagination() when:
   - Receiving pagination from non-Gin sources
   - Double-checking values before database queries
   - Converting page numbers to skip/limit

3. Include pagination metadata in responses
   - Use GetPaginationMetadata() for consistent format
   - Helps frontend implement pagination UI
   - Provides totalCount for progress indicators

4. Security considerations:
   - NEVER trust user input for pagination
   - ALWAYS normalize before database queries
   - MaxPageSize=100 prevents abuse
   - Skip validation prevents negative offsets

5. Performance tips:
   - Add database indexes for sorting fields
   - Use CountDocuments() efficiently
   - Consider caching total counts for large datasets
   - Use cursor-based pagination for infinite scroll

6. Testing:
   - Test with negative values (should normalize to 0)
   - Test with huge values (should cap at MaxPageSize)
   - Test with invalid strings (should use defaults)
   - Test boundary conditions (page 1, last page)

7. Frontend integration:
   - Return consistent pagination metadata
   - Support both offset and page-based pagination
   - Include hasNextPage for infinite scroll
   - Provide totalPages for page selectors

COMMON MISTAKES TO AVOID:

❌ DON'T use raw query params without validation
❌ DON'T skip normalization in repositories
❌ DON'T return different pagination formats across endpoints
❌ DON'T forget to count total items for metadata
❌ DON'T allow unlimited page sizes
❌ DON'T use negative skip values
❌ DON'T forget to test DoS attack scenarios

✅ DO use ParsePaginationParams() everywhere
✅ DO normalize at multiple layers (defense in depth)
✅ DO return consistent pagination metadata
✅ DO test with malicious inputs
✅ DO document pagination in API specs
✅ DO use constants (DefaultPageSize, MaxPageSize)

*/
