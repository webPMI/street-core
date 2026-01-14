package helpers

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// ========================
// NormalizePagination Tests
// ========================

func TestNormalizePagination(t *testing.T) {
	tests := []struct {
		name          string
		skip          int
		limit         int
		expectedSkip  int
		expectedLimit int
	}{
		{
			name:          "Valid positive values",
			skip:          10,
			limit:         20,
			expectedSkip:  10,
			expectedLimit: 20,
		},
		{
			name:          "Negative skip normalized to 0",
			skip:          -10,
			limit:         20,
			expectedSkip:  0,
			expectedLimit: 20,
		},
		{
			name:          "Zero limit normalized to default",
			skip:          10,
			limit:         0,
			expectedSkip:  10,
			expectedLimit: DefaultPageSize,
		},
		{
			name:          "Negative limit normalized to default",
			skip:          10,
			limit:         -5,
			expectedSkip:  10,
			expectedLimit: DefaultPageSize,
		},
		{
			name:          "Limit exceeds max, capped at MaxPageSize",
			skip:          0,
			limit:         500,
			expectedSkip:  0,
			expectedLimit: MaxPageSize,
		},
		{
			name:          "Both skip and limit invalid",
			skip:          -100,
			limit:         -50,
			expectedSkip:  0,
			expectedLimit: DefaultPageSize,
		},
		{
			name:          "Limit at max boundary",
			skip:          0,
			limit:         MaxPageSize,
			expectedSkip:  0,
			expectedLimit: MaxPageSize,
		},
		{
			name:          "Limit just above max boundary",
			skip:          0,
			limit:         MaxPageSize + 1,
			expectedSkip:  0,
			expectedLimit: MaxPageSize,
		},
		{
			name:          "Limit at min boundary",
			skip:          0,
			limit:         MinPageSize,
			expectedSkip:  0,
			expectedLimit: MinPageSize,
		},
		{
			name:          "Zero skip and limit",
			skip:          0,
			limit:         0,
			expectedSkip:  0,
			expectedLimit: DefaultPageSize,
		},
		{
			name:          "Large skip value",
			skip:          999999,
			limit:         20,
			expectedSkip:  999999,
			expectedLimit: 20,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			skip, limit := NormalizePagination(tt.skip, tt.limit)

			assert.Equal(t, tt.expectedSkip, skip, "Skip value should match expected")
			assert.Equal(t, tt.expectedLimit, limit, "Limit value should match expected")

			// Additional security assertions
			assert.GreaterOrEqual(t, skip, 0, "Skip must be >= 0")
			assert.GreaterOrEqual(t, limit, MinPageSize, "Limit must be >= MinPageSize")
			assert.LessOrEqual(t, limit, MaxPageSize, "Limit must be <= MaxPageSize")
		})
	}
}

// ========================
// ParsePaginationParams Tests
// ========================

func TestParsePaginationParams(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name          string
		queryParams   map[string]string
		expectedSkip  int
		expectedLimit int
	}{
		{
			name:          "No query params - use defaults",
			queryParams:   map[string]string{},
			expectedSkip:  0,
			expectedLimit: DefaultPageSize,
		},
		{
			name: "Valid skip and limit",
			queryParams: map[string]string{
				"skip":  "40",
				"limit": "10",
			},
			expectedSkip:  40,
			expectedLimit: 10,
		},
		{
			name: "Negative skip normalized to 0",
			queryParams: map[string]string{
				"skip":  "-10",
				"limit": "20",
			},
			expectedSkip:  0,
			expectedLimit: 20,
		},
		{
			name: "Limit exceeds max, capped",
			queryParams: map[string]string{
				"skip":  "0",
				"limit": "200",
			},
			expectedSkip:  0,
			expectedLimit: MaxPageSize,
		},
		{
			name: "Invalid skip string - use default 0",
			queryParams: map[string]string{
				"skip":  "invalid",
				"limit": "20",
			},
			expectedSkip:  0,
			expectedLimit: 20,
		},
		{
			name: "Invalid limit string - use default",
			queryParams: map[string]string{
				"skip":  "10",
				"limit": "invalid",
			},
			expectedSkip:  10,
			expectedLimit: DefaultPageSize,
		},
		{
			name: "Both params invalid",
			queryParams: map[string]string{
				"skip":  "abc",
				"limit": "xyz",
			},
			expectedSkip:  0,
			expectedLimit: DefaultPageSize,
		},
		{
			name: "Zero values",
			queryParams: map[string]string{
				"skip":  "0",
				"limit": "0",
			},
			expectedSkip:  0,
			expectedLimit: DefaultPageSize,
		},
		{
			name: "Large values",
			queryParams: map[string]string{
				"skip":  "9999",
				"limit": "50",
			},
			expectedSkip:  9999,
			expectedLimit: 50,
		},
		{
			name: "Only skip provided",
			queryParams: map[string]string{
				"skip": "20",
			},
			expectedSkip:  20,
			expectedLimit: DefaultPageSize,
		},
		{
			name: "Only limit provided",
			queryParams: map[string]string{
				"limit": "30",
			},
			expectedSkip:  0,
			expectedLimit: 30,
		},
		{
			name: "Float values (should fail parsing, use defaults)",
			queryParams: map[string]string{
				"skip":  "10.5",
				"limit": "20.7",
			},
			expectedSkip:  0,
			expectedLimit: DefaultPageSize,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup test request
			req := httptest.NewRequest(http.MethodGet, "/test", nil)
			q := req.URL.Query()
			for key, value := range tt.queryParams {
				q.Add(key, value)
			}
			req.URL.RawQuery = q.Encode()

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Request = req

			// Parse pagination
			skip, limit := ParsePaginationParams(c)

			assert.Equal(t, tt.expectedSkip, skip, "Skip value should match expected")
			assert.Equal(t, tt.expectedLimit, limit, "Limit value should match expected")

			// Security assertions
			assert.GreaterOrEqual(t, skip, 0, "Skip must be >= 0")
			assert.GreaterOrEqual(t, limit, MinPageSize, "Limit must be >= MinPageSize")
			assert.LessOrEqual(t, limit, MaxPageSize, "Limit must be <= MaxPageSize")
		})
	}
}

// ========================
// CalculateTotalPages Tests
// ========================

func TestCalculateTotalPages(t *testing.T) {
	tests := []struct {
		name          string
		totalCount    int64
		pageSize      int
		expectedPages int
	}{
		{
			name:          "Exact division",
			totalCount:    100,
			pageSize:      20,
			expectedPages: 5,
		},
		{
			name:          "With remainder (rounds up)",
			totalCount:    95,
			pageSize:      20,
			expectedPages: 5,
		},
		{
			name:          "Single item",
			totalCount:    1,
			pageSize:      20,
			expectedPages: 1,
		},
		{
			name:          "Zero count",
			totalCount:    0,
			pageSize:      20,
			expectedPages: 1,
		},
		{
			name:          "Zero page size",
			totalCount:    100,
			pageSize:      0,
			expectedPages: 1,
		},
		{
			name:          "Count less than page size",
			totalCount:    5,
			pageSize:      20,
			expectedPages: 1,
		},
		{
			name:          "Large count",
			totalCount:    10000,
			pageSize:      100,
			expectedPages: 100,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			pages := CalculateTotalPages(tt.totalCount, tt.pageSize)
			assert.Equal(t, tt.expectedPages, pages)
			assert.GreaterOrEqual(t, pages, 1, "Pages must be at least 1")
		})
	}
}

// ========================
// CalculatePageNumber Tests
// ========================

func TestCalculatePageNumber(t *testing.T) {
	tests := []struct {
		name             string
		skip             int
		limit            int
		expectedPageNum  int
	}{
		{
			name:            "First page",
			skip:            0,
			limit:           20,
			expectedPageNum: 1,
		},
		{
			name:            "Second page",
			skip:            20,
			limit:           20,
			expectedPageNum: 2,
		},
		{
			name:            "Third page",
			skip:            40,
			limit:           20,
			expectedPageNum: 3,
		},
		{
			name:            "Different page size",
			skip:            30,
			limit:           10,
			expectedPageNum: 4,
		},
		{
			name:            "Zero limit uses default",
			skip:            40,
			limit:           0,
			expectedPageNum: (40 / DefaultPageSize) + 1,
		},
		{
			name:            "Partial skip",
			skip:            15,
			limit:           20,
			expectedPageNum: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			pageNum := CalculatePageNumber(tt.skip, tt.limit)
			assert.Equal(t, tt.expectedPageNum, pageNum)
			assert.GreaterOrEqual(t, pageNum, 1, "Page number must be at least 1")
		})
	}
}

// ========================
// HasNextPage Tests
// ========================

func TestHasNextPage(t *testing.T) {
	tests := []struct {
		name         string
		skip         int
		limit        int
		totalCount   int64
		expectedNext bool
	}{
		{
			name:         "Has next page",
			skip:         0,
			limit:        20,
			totalCount:   100,
			expectedNext: true,
		},
		{
			name:         "Last page - no next",
			skip:         80,
			limit:        20,
			totalCount:   100,
			expectedNext: false,
		},
		{
			name:         "Exact last page",
			skip:         80,
			limit:        20,
			totalCount:   100,
			expectedNext: false,
		},
		{
			name:         "Beyond last page",
			skip:         120,
			limit:        20,
			totalCount:   100,
			expectedNext: false,
		},
		{
			name:         "First page of one",
			skip:         0,
			limit:        20,
			totalCount:   5,
			expectedNext: false,
		},
		{
			name:         "Zero total count",
			skip:         0,
			limit:        20,
			totalCount:   0,
			expectedNext: false,
		},
		{
			name:         "Zero limit uses default",
			skip:         0,
			limit:        0,
			totalCount:   100,
			expectedNext: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			hasNext := HasNextPage(tt.skip, tt.limit, tt.totalCount)
			assert.Equal(t, tt.expectedNext, hasNext)
		})
	}
}

// ========================
// GetPaginationMetadata Tests
// ========================

func TestGetPaginationMetadata(t *testing.T) {
	tests := []struct {
		name               string
		skip               int
		limit              int
		totalCount         int64
		expectedPage       int
		expectedPageSize   int
		expectedTotalPages int
		expectedHasNext    bool
	}{
		{
			name:               "First page of many",
			skip:               0,
			limit:              20,
			totalCount:         100,
			expectedPage:       1,
			expectedPageSize:   20,
			expectedTotalPages: 5,
			expectedHasNext:    true,
		},
		{
			name:               "Middle page",
			skip:               40,
			limit:              20,
			totalCount:         100,
			expectedPage:       3,
			expectedPageSize:   20,
			expectedTotalPages: 5,
			expectedHasNext:    true,
		},
		{
			name:               "Last page",
			skip:               80,
			limit:              20,
			totalCount:         95,
			expectedPage:       5,
			expectedPageSize:   20,
			expectedTotalPages: 5,
			expectedHasNext:    false,
		},
		{
			name:               "Negative skip normalized",
			skip:               -10,
			limit:              20,
			totalCount:         100,
			expectedPage:       1,
			expectedPageSize:   20,
			expectedTotalPages: 5,
			expectedHasNext:    true,
		},
		{
			name:               "Invalid limit normalized",
			skip:               0,
			limit:              0,
			totalCount:         100,
			expectedPage:       1,
			expectedPageSize:   DefaultPageSize,
			expectedTotalPages: CalculateTotalPages(100, DefaultPageSize),
			expectedHasNext:    HasNextPage(0, DefaultPageSize, 100),
		},
		{
			name:               "Limit exceeds max",
			skip:               0,
			limit:              500,
			totalCount:         100,
			expectedPage:       1,
			expectedPageSize:   MaxPageSize,
			expectedTotalPages: CalculateTotalPages(100, MaxPageSize),
			expectedHasNext:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			metadata := GetPaginationMetadata(tt.skip, tt.limit, tt.totalCount)

			assert.Equal(t, tt.expectedPage, metadata["page"])
			assert.Equal(t, tt.expectedPageSize, metadata["pageSize"])
			assert.Equal(t, tt.expectedTotalPages, metadata["totalPages"])
			assert.Equal(t, tt.totalCount, metadata["totalCount"])
			assert.Equal(t, tt.expectedHasNext, metadata["hasNextPage"])

			// Verify all expected keys exist
			requiredKeys := []string{"page", "pageSize", "totalPages", "totalCount", "hasNextPage"}
			for _, key := range requiredKeys {
				assert.Contains(t, metadata, key, "Metadata should contain key: "+key)
			}
		})
	}
}

// ========================
// DoS Attack Prevention Tests
// ========================

func TestDoSAttackPrevention(t *testing.T) {
	gin.SetMode(gin.TestMode)

	attackTests := []struct {
		name        string
		skip        string
		limit       string
		description string
	}{
		{
			name:        "Extremely large limit",
			skip:        "0",
			limit:       "999999999",
			description: "Should cap at MaxPageSize",
		},
		{
			name:        "Negative skip attack",
			skip:        "-999999999",
			limit:       "20",
			description: "Should normalize to 0",
		},
		{
			name:        "Combined attack",
			skip:        "-999999",
			limit:       "999999",
			description: "Should normalize both",
		},
		{
			name:        "Integer overflow attempt",
			skip:        "2147483647",
			limit:       "2147483647",
			description: "Should cap limit",
		},
	}

	for _, tt := range attackTests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/test", nil)
			q := req.URL.Query()
			q.Add("skip", tt.skip)
			q.Add("limit", tt.limit)
			req.URL.RawQuery = q.Encode()

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Request = req

			skip, limit := ParsePaginationParams(c)

			// Security assertions - should ALWAYS be safe
			assert.GreaterOrEqual(t, skip, 0, tt.description)
			assert.LessOrEqual(t, limit, MaxPageSize, tt.description)
			assert.GreaterOrEqual(t, limit, MinPageSize, tt.description)

			t.Logf("Attack prevented: %s → skip=%d, limit=%d", tt.description, skip, limit)
		})
	}
}

// ========================
// Benchmark Tests
// ========================

func BenchmarkNormalizePagination(b *testing.B) {
	for i := 0; i < b.N; i++ {
		NormalizePagination(i, i%150)
	}
}

func BenchmarkParsePaginationParams(b *testing.B) {
	gin.SetMode(gin.TestMode)
	req := httptest.NewRequest(http.MethodGet, "/test?skip=40&limit=20", nil)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ParsePaginationParams(c)
	}
}

func BenchmarkCalculateTotalPages(b *testing.B) {
	for i := 0; i < b.N; i++ {
		CalculateTotalPages(int64(i), 20)
	}
}

func BenchmarkGetPaginationMetadata(b *testing.B) {
	for i := 0; i < b.N; i++ {
		GetPaginationMetadata(i, 20, 1000)
	}
}
