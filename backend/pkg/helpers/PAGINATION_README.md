# Pagination Helper Utilities

**Last Updated**: 2025-12-24 10:00 UTC-5
**Location**: `backend/pkg/helpers/pagination.go`
**Status**: Production Ready
**Security**: DoS Attack Prevention

---

## Overview

The pagination helper utilities provide secure, standardized pagination functionality across the backend API. These utilities prevent DoS attacks by limiting maximum page sizes and normalizing user input.

---

## Security Features

- **DoS Prevention**: Caps maximum page size at 100 items
- **Input Validation**: Normalizes negative/invalid values automatically
- **Attack Mitigation**: Prevents memory exhaustion and database overload
- **Defense in Depth**: Normalization at handler, service, and repository layers

---

## Constants

```go
const (
    DefaultPageSize = 20  // Default items per page
    MaxPageSize     = 100 // Maximum allowed (DoS prevention)
    MinPageSize     = 1   // Minimum allowed
)
```

---

## Core Functions

### 1. ParsePaginationParams(c *gin.Context)

**Use in handlers** to extract and normalize pagination from query params.

```go
func (h *Handler) List(c *gin.Context) {
    skip, limit := helpers.ParsePaginationParams(c)
    // skip and limit are already normalized and safe

    items, err := h.repository.FindAll(skip, limit)
    // ...
}
```

**Query params**:
- `skip`: Number of documents to skip (default: 0)
- `limit`: Max documents to return (default: 20)

**Examples**:
```
GET /api/items                 → skip=0, limit=20 (defaults)
GET /api/items?skip=40&limit=10 → skip=40, limit=10
GET /api/items?skip=-5&limit=200 → skip=0, limit=100 (normalized)
GET /api/items?limit=0          → skip=0, limit=20 (default)
```

---

### 2. NormalizePagination(skip, limit int)

**Use when receiving pagination from non-Gin sources** or for double-validation.

```go
func (s *Service) GetItems(skip, limit int) ([]Item, error) {
    // Normalize at service layer (defense in depth)
    skip, limit = helpers.NormalizePagination(skip, limit)

    return s.repository.FindAll(skip, limit)
}
```

**Normalization rules**:
- If `skip < 0` → set to `0`
- If `limit <= 0` → set to `DefaultPageSize (20)`
- If `limit > MaxPageSize` → set to `MaxPageSize (100)`

---

### 3. GetPaginationMetadata(skip, limit, totalCount)

**Returns full pagination metadata** for API responses.

```go
func (h *Handler) List(c *gin.Context) {
    skip, limit := helpers.ParsePaginationParams(c)

    items, _ := h.repository.FindAll(skip, limit)
    totalCount, _ := h.repository.Count()

    metadata := helpers.GetPaginationMetadata(skip, limit, totalCount)

    c.JSON(200, gin.H{
        "data":       items,
        "pagination": metadata,
    })
}
```

**Metadata includes**:
```json
{
  "page": 3,
  "pageSize": 20,
  "totalPages": 5,
  "totalCount": 95,
  "hasNextPage": true
}
```

---

### 4. Additional Helpers

- `CalculateTotalPages(totalCount, pageSize)` - Calculate number of pages
- `CalculatePageNumber(skip, limit)` - Get current page number
- `HasNextPage(skip, limit, totalCount)` - Check if more pages exist

---

## Usage Examples

### Basic Handler
```go
func (h *Handler) ListUsers(c *gin.Context) {
    skip, limit := helpers.ParsePaginationParams(c)

    users, err := h.userRepo.FindAll(skip, limit)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(200, gin.H{
        "users": users,
        "skip":  skip,
        "limit": limit,
    })
}
```

### With Full Metadata
```go
func (h *Handler) ListCompetitions(c *gin.Context) {
    skip, limit := helpers.ParsePaginationParams(c)

    competitions, _ := h.compRepo.FindAll(skip, limit)
    totalCount, _ := h.compRepo.Count()

    c.JSON(200, gin.H{
        "data":       competitions,
        "pagination": helpers.GetPaginationMetadata(skip, limit, totalCount),
    })
}
```

### Repository Integration
```go
func (r *Repository) FindAll(skip, limit int) ([]Item, error) {
    // Normalize at repository level (safety check)
    skip, limit = helpers.NormalizePagination(skip, limit)

    opts := options.Find().
        SetSkip(int64(skip)).
        SetLimit(int64(limit)).
        SetSort(bson.D{{Key: "created_at", Value: -1}})

    cursor, err := r.collection.Find(ctx, bson.M{}, opts)
    // ...
}
```

---

## Security Best Practices

### 1. Always Use ParsePaginationParams
```go
// ✅ GOOD - Automatic validation
skip, limit := helpers.ParsePaginationParams(c)

// ❌ BAD - Raw query params
skip, _ := strconv.Atoi(c.Query("skip"))
limit, _ := strconv.Atoi(c.Query("limit"))
```

### 2. Normalize at Multiple Layers
```go
// Handler layer
skip, limit := helpers.ParsePaginationParams(c)

// Service layer (defense in depth)
skip, limit = helpers.NormalizePagination(skip, limit)

// Repository layer (final safety check)
skip, limit = helpers.NormalizePagination(skip, limit)
```

### 3. Never Trust User Input
```go
// ✅ GOOD - Validated and capped
skip, limit := helpers.ParsePaginationParams(c)
// Maximum limit is 100, prevents DoS

// ❌ BAD - Allows unlimited page size
limit := c.Query("limit") // Could be 999999999
```

---

## DoS Attack Prevention

The pagination helper prevents several DoS attack vectors:

### Attack Scenario 1: Memory Exhaustion
```
GET /api/items?limit=999999999
```
**Without helper**: Server tries to load 999M records → crashes
**With helper**: Limit capped at 100 → safe

### Attack Scenario 2: Database Overload
```
GET /api/items?skip=-999999999&limit=999999999
```
**Without helper**: Invalid query → database error
**With helper**: Normalized to skip=0, limit=100 → safe

### Attack Scenario 3: Network Saturation
```
Multiple requests: GET /api/items?limit=100000
```
**Without helper**: Each request returns 100K items → network congestion
**With helper**: Each request returns max 100 items → controlled bandwidth

---



**Test coverage**:
- ✅ Normal pagination scenarios
- ✅ Edge cases (negative, zero, huge values)
- ✅ Invalid input handling
- ✅ DoS attack prevention
- ✅ Boundary conditions
- ✅ Integration with Gin context

---

---

## Performance Considerations

### 1. Database Indexes
Ensure sorting fields are indexed:
```go
// In config/indexes.go
db.Collection("items").Indexes().CreateOne(ctx, mongo.IndexModel{
    Keys: bson.D{{Key: "created_at", Value: -1}},
})
```

### 2. Count Optimization
Cache total counts for large datasets:
```go
// Cache total count (invalidate on create/delete)
totalCount := cache.Get("items_total_count")
if totalCount == nil {
    totalCount, _ = repo.Count()
    cache.Set("items_total_count", totalCount, 5*time.Minute)
}
```

### 3. Cursor-Based Pagination
For infinite scroll, use cursor-based pagination:
```go
skip, limit := helpers.ParsePaginationParams(c)
hasMore := helpers.HasNextPage(skip, limit, totalCount)

c.JSON(200, gin.H{
    "items": items,
    "cursor": gin.H{
        "next":    skip + limit,
        "hasMore": hasMore,
    },
})
```

---

## API Response Format

### Standard Format
```json
{
  "data": [...],
  "pagination": {
    "page": 3,
    "pageSize": 20,
    "totalPages": 5,
    "totalCount": 95,
    "hasNextPage": true
  }
}
```

### Cursor Format (Infinite Scroll)
```json
{
  "items": [...],
  "cursor": {
    "next": 40,
    "hasMore": true
  }
}
```

---

## Frontend Integration

### React/JavaScript Example
```javascript
const fetchItems = async (page = 1, pageSize = 20) => {
  const skip = (page - 1) * pageSize;
  const response = await fetch(`/api/items?skip=${skip}&limit=${pageSize}`);
  const { data, pagination } = await response.json();

  return {
    items: data,
    currentPage: pagination.page,
    totalPages: pagination.totalPages,
    hasNextPage: pagination.hasNextPage,
  };
};
```

### Flutter/Dart Example
```dart
Future<PaginatedResult<Item>> fetchItems({int page = 1, int pageSize = 20}) async {
  final skip = (page - 1) * pageSize;
  final response = await api.get('/items?skip=$skip&limit=$pageSize');

  return PaginatedResult.fromJson(response.data);
}
```

---

## Common Mistakes to Avoid

### 1. Not Using ParsePaginationParams
```go
// ❌ BAD - Manual parsing
skip, _ := strconv.Atoi(c.Query("skip"))
limit, _ := strconv.Atoi(c.Query("limit"))

// ✅ GOOD - Use helper
skip, limit := helpers.ParsePaginationParams(c)
```

### 2. Inconsistent Response Format
```go
// ❌ BAD - Different formats across endpoints
c.JSON(200, items) // No pagination metadata

// ✅ GOOD - Consistent format
c.JSON(200, gin.H{
    "data": items,
    "pagination": helpers.GetPaginationMetadata(skip, limit, totalCount),
})
```

### 3. Forgetting Total Count
```go
// ❌ BAD - No total count
c.JSON(200, gin.H{"items": items})

// ✅ GOOD - Include total count
totalCount, _ := repo.Count()
c.JSON(200, gin.H{
    "items": items,
    "pagination": helpers.GetPaginationMetadata(skip, limit, totalCount),
})
```

### 4. Not Testing DoS Scenarios
```go
// ✅ GOOD - Test attack scenarios
func TestDoSPrevention(t *testing.T) {
    // Test huge limit
    skip, limit := helpers.NormalizePagination(0, 999999)
    assert.Equal(t, 100, limit) // Capped at MaxPageSize
}
```

---

## Related Files

- **Implementation**: `backend/pkg/helpers/pagination.go`
- **Tests**: `backend/pkg/helpers/pagination_test.go`
- **Examples**: `backend/pkg/helpers/pagination_example.go`
- **Helpers**: `backend/pkg/helpers/helpers.go`

---

## References

- **OWASP**: [API Security - Excessive Data Exposure](https://owasp.org/www-project-api-security/)
- **MongoDB**: [Pagination Best Practices](https://www.mongodb.com/docs/manual/reference/method/cursor.skip/)
- **Gin**: [Query Parameters](https://gin-gonic.com/docs/examples/query-string-parameters/)

---

**Last Updated**: 2025-12-24 10:00 UTC-5
**Maintained by**: Backend Agent
**Status**: Production Ready
