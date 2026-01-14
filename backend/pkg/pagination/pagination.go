package pagination

import (
	"strconv"
	"time"
	"strings"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const (
	DefaultPage    = 1
	DefaultLimit   = 20
	MaxLimit       = 100
	DefaultSortKey = "createdAt"
	DefaultSortDir = -1 // descending
)

// Params holds pagination parameters
type Params struct {
	Page    int
	Limit   int
	Skip    int
	SortKey string
	SortDir int
}

// FilterParams holds advanced filtering parameters
type FilterParams struct {
	Search       string                   // General search term
	Fields       map[string]interface{}   // Field-specific filters
	DateRange    *DateRange               // Date range filter
	NumericRange map[string]*NumericRange // Numeric range filters
	Tags         []string                 // Tag filters
	Status       string                   // Status filter
	IsActive     *bool                    // Active/inactive filter
}

// DateRange represents a date range filter
type DateRange struct {
	From string // ISO date string
	To   string // ISO date string
}

// NumericRange represents a numeric range filter
type NumericRange struct {
	Min *float64
	Max *float64
}

// Metadata holds pagination metadata
type Metadata struct {
	CurrentPage  int   `json:"currentPage"`
	TotalPages   int   `json:"totalPages"`
	TotalItems   int64 `json:"totalItems"`
	ItemsPerPage int   `json:"itemsPerPage"`
	HasNext      bool  `json:"hasNext"`
	HasPrevious  bool  `json:"hasPrevious"`
}

// Response holds paginated data with metadata
type Response struct {
	Data       interface{} `json:"data"`
	Pagination *Metadata   `json:"pagination"`
}

// ParseParams extracts pagination parameters from Gin context
func ParseParams(c *gin.Context) *Params {
	page := parseIntParam(c.Query("page"), DefaultPage)
	if page < 1 {
		page = DefaultPage
	}

	limit := parseIntParam(c.Query("limit"), DefaultLimit)
	if limit < 1 {
		limit = DefaultLimit
	}
	if limit > MaxLimit {
		limit = MaxLimit
	}

	sortKey := c.DefaultQuery("sort", DefaultSortKey)
	sortDir := DefaultSortDir
	if c.Query("order") == "asc" {
		sortDir = 1
	}

	skip := (page - 1) * limit

	return &Params{
		Page:    page,
		Limit:   limit,
		Skip:    skip,
		SortKey: sortKey,
		SortDir: sortDir,
	}
}

// ParseFilters extracts filter parameters from Gin context
func ParseFilters(c *gin.Context) *FilterParams {
	filters := &FilterParams{
		Fields:       make(map[string]interface{}),
		NumericRange: make(map[string]*NumericRange),
	}

	// General search
	if search := c.Query("search"); search != "" {
		filters.Search = strings.TrimSpace(search)
	}

	// Status filter
	if status := c.Query("status"); status != "" {
		filters.Status = status
	}

	// Active/inactive filter
	if isActiveStr := c.Query("isActive"); isActiveStr != "" {
		if isActive, err := strconv.ParseBool(isActiveStr); err == nil {
			filters.IsActive = &isActive
		}
	}

	// Tags filter (comma-separated)
	if tags := c.Query("tags"); tags != "" {
		filters.Tags = strings.Split(tags, ",")
		for i := range filters.Tags {
			filters.Tags[i] = strings.TrimSpace(filters.Tags[i])
		}
	}

	// Date range filter
	if from := c.Query("dateFrom"); from != "" && isValidDateFormat(from) {
		if filters.DateRange == nil {
			filters.DateRange = &DateRange{}
		}
		filters.DateRange.From = from
	}
	if to := c.Query("dateTo"); to != "" && isValidDateFormat(to) {
		if filters.DateRange == nil {
			filters.DateRange = &DateRange{}
		}
		filters.DateRange.To = to
	}

	// Numeric range filters (e.g., priceMin, priceMax)
	parseNumericRange(c, "price", filters)
	parseNumericRange(c, "age", filters)
	parseNumericRange(c, "rating", filters)

	// Custom field filters (e.g., category=sports, level=advanced)
	for key, values := range c.Request.URL.Query() {
		// Skip reserved parameters
		if isReservedParam(key) {
			continue
		}

		// Single value
		if len(values) == 1 {
			filters.Fields[key] = values[0]
		} else if len(values) > 1 {
			// Multiple values (OR condition)
			filters.Fields[key] = values
		}
	}

	return filters
}

// BuildMongoFilter converts FilterParams to MongoDB filter
func (f *FilterParams) BuildMongoFilter(searchFields []string) bson.M {
	filter := bson.M{}

	// General search (OR across multiple fields)
	if f.Search != "" && len(searchFields) > 0 {
		searchConditions := make([]bson.M, 0, len(searchFields))
		for _, field := range searchFields {
			searchConditions = append(searchConditions, bson.M{
				field: bson.M{"$regex": f.Search, "$options": "i"},
			})
		}
		filter["$or"] = searchConditions
	}

	// Status filter
	if f.Status != "" {
		filter["status"] = f.Status
	}

	// Active/inactive filter
	if f.IsActive != nil {
		filter["isActive"] = *f.IsActive
	}

	// Tags filter (match any tag)
	if len(f.Tags) > 0 {
		filter["tags"] = bson.M{"$in": f.Tags}
	}

	// Date range filter
	if f.DateRange != nil {
		dateFilter := bson.M{}
		if f.DateRange.From != "" {
			dateFilter["$gte"] = f.DateRange.From
		}
		if f.DateRange.To != "" {
			dateFilter["$lte"] = f.DateRange.To
		}
		if len(dateFilter) > 0 {
			filter["createdAt"] = dateFilter
		}
	}

	// Numeric range filters
	for field, numRange := range f.NumericRange {
		rangeFilter := bson.M{}
		if numRange.Min != nil {
			rangeFilter["$gte"] = *numRange.Min
		}
		if numRange.Max != nil {
			rangeFilter["$lte"] = *numRange.Max
		}
		if len(rangeFilter) > 0 {
			filter[field] = rangeFilter
		}
	}

	// Custom field filters
	for key, value := range f.Fields {
		switch v := value.(type) {
		case []string:
			// Multiple values = OR condition
			filter[key] = bson.M{"$in": v}
		default:
			// Single value = exact match
			filter[key] = v
		}
	}

	return filter
}

// GetFindOptions creates MongoDB find options from pagination params
func (p *Params) GetFindOptions() *options.FindOptions {
	opts := options.Find()
	opts.SetSkip(int64(p.Skip))
	opts.SetLimit(int64(p.Limit))

	// Apply sorting with defaults if not set
	sortKey := p.SortKey
	if sortKey == "" {
		sortKey = DefaultSortKey
	}
	sortDir := p.SortDir
	if sortDir == 0 {
		sortDir = DefaultSortDir
	}

	opts.SetSort(map[string]int{sortKey: sortDir})
	return opts
}

// CreateResponse creates a pagination response with metadata
func CreateResponse(page, limit int, total int64, data interface{}) *Response {
	totalPages := int(total) / limit
	if int(total)%limit > 0 {
		totalPages++
	}

	hasNext := page < totalPages
	hasPrevious := page > 1

	return &Response{
		Data: data,
		Pagination: &Metadata{
			CurrentPage:  page,
			TotalPages:   totalPages,
			TotalItems:   total,
			ItemsPerPage: limit,
			HasNext:      hasNext,
			HasPrevious:  hasPrevious,
		},
	}
}

// parseIntParam safely parses a string to int with default value
func parseIntParam(s string, defaultVal int) int {
	if s == "" {
		return defaultVal
	}
	val, err := strconv.Atoi(s)
	if err != nil {
		return defaultVal
	}
	return val
}

// parseNumericRange parses min/max query parameters for a field
func parseNumericRange(c *gin.Context, fieldName string, filters *FilterParams) {
	minKey := fieldName + "Min"
	maxKey := fieldName + "Max"

	var numRange *NumericRange

	if minStr := c.Query(minKey); minStr != "" {
		if min, err := strconv.ParseFloat(minStr, 64); err == nil {
			if numRange == nil {
				numRange = &NumericRange{}
			}
			numRange.Min = &min
		}
	}

	if maxStr := c.Query(maxKey); maxStr != "" {
		if max, err := strconv.ParseFloat(maxStr, 64); err == nil {
			if numRange == nil {
				numRange = &NumericRange{}
			}
			numRange.Max = &max
		}
	}

	if numRange != nil {
		filters.NumericRange[fieldName] = numRange
	}
}

// isReservedParam checks if a parameter is reserved for pagination/filtering
func isReservedParam(key string) bool {
	reserved := []string{
		"page", "limit", "sort", "order",
		"search", "status", "isActive", "tags",
		"dateFrom", "dateTo",
	}

	// Check exact match
	for _, r := range reserved {
		if key == r {
			return true
		}
	}

	// Check suffixes
	suffixes := []string{"Min", "Max", "From", "To"}
	for _, suffix := range suffixes {
		if strings.HasSuffix(key, suffix) {
			return true
		}
	}

	return false
}

// isValidDateFormat checks if a date string is in valid RFC3339 or YYYY-MM-DD format
func isValidDateFormat(date string) bool {
	if date == "" {
		return false
	}
	// Try RFC3339 (full format with timezone)
	if _, err := time.Parse(time.RFC3339, date); err == nil {
		return true
	}
	// Try date-only format (YYYY-MM-DD)
	if _, err := time.Parse("2006-01-02", date); err == nil {
		return true
	}
	return false
}
