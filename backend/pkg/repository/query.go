package repository

import (
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Query represents a fluent MongoDB query builder
// Provides a type-safe, readable way to construct MongoDB queries
type Query struct {
	filter     bson.M
	sort       bson.M
	limit      int64
	skip       int64
	projection bson.M
}

// NewQuery creates a new query builder instance
func NewQuery() *Query {
	return &Query{
		filter:     bson.M{},
		sort:       bson.M{},
		projection: bson.M{},
	}
}

// ============================================================================
// COMMON FILTERS
// ============================================================================

// Where adds a custom filter condition
func (q *Query) Where(field string, value interface{}) *Query {
	q.filter[field] = value
	return q
}

// WhereRaw adds a raw bson.M filter for complex queries
// Use this for advanced MongoDB queries that don't fit the fluent API
func (q *Query) WhereRaw(rawFilter bson.M) *Query {
	for key, value := range rawFilter {
		q.filter[key] = value
	}
	return q
}

// WhereIn adds an $in filter (field matches any value in array)
func (q *Query) WhereIn(field string, values interface{}) *Query {
	q.filter[field] = bson.M{"$in": values}
	return q
}

// WhereNotIn adds a $nin filter (field does NOT match any value in array)
func (q *Query) WhereNotIn(field string, values interface{}) *Query {
	q.filter[field] = bson.M{"$nin": values}
	return q
}

// WhereGreaterThan adds a $gt filter
func (q *Query) WhereGreaterThan(field string, value interface{}) *Query {
	q.filter[field] = bson.M{"$gt": value}
	return q
}

// WhereLessThan adds a $lt filter
func (q *Query) WhereLessThan(field string, value interface{}) *Query {
	q.filter[field] = bson.M{"$lt": value}
	return q
}

// WhereBetween adds a range filter ($gte and $lte)
func (q *Query) WhereBetween(field string, min, max interface{}) *Query {
	q.filter[field] = bson.M{
		"$gte": min,
		"$lte": max,
	}
	return q
}

// WhereRegex adds a regex filter for pattern matching
func (q *Query) WhereRegex(field string, pattern string, caseInsensitive bool) *Query {
	options := ""
	if caseInsensitive {
		options = "i"
	}
	q.filter[field] = bson.M{
		"$regex":   pattern,
		"$options": options,
	}
	return q
}

// WhereExists checks if a field exists
func (q *Query) WhereExists(field string, exists bool) *Query {
	q.filter[field] = bson.M{"$exists": exists}
	return q
}

// ============================================================================
// COMMON PATTERNS (Pre-built filters)
// ============================================================================

// WhereActive filters for active records (status = "active")
func (q *Query) WhereActive() *Query {
	q.filter["status"] = "active"
	return q
}

// WhereNotDeleted filters out soft-deleted records
func (q *Query) WhereNotDeleted() *Query {
	q.filter["deletedAt"] = bson.M{"$exists": false}
	return q
}

// WhereDeleted filters for soft-deleted records only
func (q *Query) WhereDeleted() *Query {
	q.filter["deletedAt"] = bson.M{"$exists": true}
	return q
}

// IncludeDeleted removes the deletedAt filter to include soft-deleted records
// Use this when you need to query all records regardless of deletion status
func (q *Query) IncludeDeleted() *Query {
	delete(q.filter, "deletedAt")
	return q
}

// WhereOwner filters by owner/creator ID
func (q *Query) WhereOwner(ownerField string, ownerID primitive.ObjectID) *Query {
	q.filter[ownerField] = ownerID
	return q
}

// WherePublic filters for public records (visibility = "public")
func (q *Query) WherePublic() *Query {
	q.filter["visibility"] = "public"
	return q
}

// WhereCreatedAfter filters records created after a specific date
func (q *Query) WhereCreatedAfter(date time.Time) *Query {
	q.filter["createdAt"] = bson.M{"$gte": date}
	return q
}

// WhereCreatedBefore filters records created before a specific date
func (q *Query) WhereCreatedBefore(date time.Time) *Query {
	q.filter["createdAt"] = bson.M{"$lte": date}
	return q
}

// ============================================================================
// LOGICAL OPERATORS
// ============================================================================

// Or combines multiple queries with OR logic
func (q *Query) Or(queries ...*Query) *Query {
	orConditions := make([]bson.M, len(queries))
	for i, query := range queries {
		orConditions[i] = query.filter
	}
	q.filter["$or"] = orConditions
	return q
}

// And combines multiple queries with AND logic
func (q *Query) And(queries ...*Query) *Query {
	andConditions := make([]bson.M, len(queries))
	for i, query := range queries {
		andConditions[i] = query.filter
	}
	q.filter["$and"] = andConditions
	return q
}

// ============================================================================
// SORTING
// ============================================================================

// Sort adds sorting by field (1 = ascending, -1 = descending)
func (q *Query) Sort(field string, ascending bool) *Query {
	order := -1
	if ascending {
		order = 1
	}
	q.sort[field] = order
	return q
}

// SortByCreatedAt sorts by creation date (newest first by default)
func (q *Query) SortByCreatedAt(ascending bool) *Query {
	return q.Sort("createdAt", ascending)
}

// SortByUpdatedAt sorts by update date (newest first by default)
func (q *Query) SortByUpdatedAt(ascending bool) *Query {
	return q.Sort("updatedAt", ascending)
}

// SortByName sorts alphabetically by name field
func (q *Query) SortByName(ascending bool) *Query {
	return q.Sort("name", ascending)
}

// ============================================================================
// PAGINATION
// ============================================================================

// Limit sets the maximum number of results to return
func (q *Query) Limit(limit int64) *Query {
	q.limit = limit
	return q
}

// Skip sets the number of results to skip (for pagination)
func (q *Query) Skip(skip int64) *Query {
	q.skip = skip
	return q
}

// Paginate sets both limit and skip based on page number and page size
func (q *Query) Paginate(page, pageSize int) *Query {
	q.limit = int64(pageSize)
	q.skip = int64((page - 1) * pageSize)
	return q
}

// ============================================================================
// PROJECTION (Field Selection)
// ============================================================================

// Select includes specific fields in the result
func (q *Query) Select(fields ...string) *Query {
	for _, field := range fields {
		q.projection[field] = 1
	}
	return q
}

// Exclude excludes specific fields from the result
func (q *Query) Exclude(fields ...string) *Query {
	for _, field := range fields {
		q.projection[field] = 0
	}
	return q
}

// ============================================================================
// GETTERS (Internal use by Repository)
// ============================================================================

// GetFilter returns the constructed MongoDB filter
func (q *Query) GetFilter() bson.M {
	return q.filter
}

// GetSort returns the sort specification
func (q *Query) GetSort() bson.M {
	return q.sort
}

// GetLimit returns the limit value
func (q *Query) GetLimit() int64 {
	return q.limit
}

// GetSkip returns the skip value
func (q *Query) GetSkip() int64 {
	return q.skip
}

// GetProjection returns the projection specification
func (q *Query) GetProjection() bson.M {
	return q.projection
}

// ============================================================================
// UTILITY METHODS
// ============================================================================

// Clone creates a deep copy of the query
func (q *Query) Clone() *Query {
	clone := NewQuery()

	// Deep copy filter
	for k, v := range q.filter {
		clone.filter[k] = v
	}

	// Deep copy sort
	for k, v := range q.sort {
		clone.sort[k] = v
	}

	// Deep copy projection
	for k, v := range q.projection {
		clone.projection[k] = v
	}

	clone.limit = q.limit
	clone.skip = q.skip

	return clone
}

// Reset clears all query conditions
func (q *Query) Reset() *Query {
	q.filter = bson.M{}
	q.sort = bson.M{}
	q.projection = bson.M{}
	q.limit = 0
	q.skip = 0
	return q
}
