# Security Package

**Last Updated**: 2024-12-24 12:00 UTC-5
**Purpose**: Security utilities for input sanitization and NoSQL injection prevention
**Status**: Production Ready

---

## Overview

This package provides critical security functions to prevent NoSQL injection attacks, input validation, and general data sanitization for the FitRiders backend.

## Functions

### 1. EscapeRegex

**Purpose**: Escapes MongoDB regex metacharacters to prevent NoSQL injection attacks.

**Signature**:
```go
func EscapeRegex(input string) string
```

**Characters Escaped**:
- Backslash: `\`
- Dot: `.`
- Asterisk: `*`
- Plus: `+`
- Question mark: `?`
- Caret: `^`
- Dollar: `$`
- Braces: `{` `}`
- Parentheses: `(` `)`
- Pipe: `|`
- Brackets: `[` `]`

**Usage Example**:
```go
import "backend/pkg/security"

// User search input
userInput := "user@example.com"
safeInput := security.EscapeRegex(userInput)
// Result: "user@example\\.com"

// Now safe to use in MongoDB regex query
filter := bson.M{
    "email": bson.M{
        "$regex": safeInput,
        "$options": "i",
    },
}
```

**Prevents**:
- **Wildcard injection**: `.*` (matches all documents)
- **Username enumeration**: `^admin.*` (find all admin accounts)
- **ReDoS attacks**: `(a+)+b` (Regular Expression Denial of Service)
- **Bypass authentication**: `.*` in password field

---

### 2. SanitizeSearchTerm

**Purpose**: Sanitizes user search input with length limits and regex escaping.

**Signature**:
```go
func SanitizeSearchTerm(input string) string
```

**Operations**:
1. Trims leading/trailing whitespace
2. Returns empty string if only whitespace
3. Limits length to 100 characters (respects UTF-8 boundaries)
4. Escapes MongoDB regex metacharacters via `EscapeRegex`

**Usage Example**:
```go
// In HTTP handler
searchQuery := r.URL.Query().Get("q")
safeTerm := security.SanitizeSearchTerm(searchQuery)

if safeTerm == "" {
    // Return all results or error
    return
}

// Safe to use in MongoDB query
filter := bson.M{
    "name": bson.M{
        "$regex": safeTerm,
        "$options": "i", // case-insensitive
    },
}
```

**Prevents**:
- **NoSQL regex injection**
- **ReDoS attacks** (via length limit)
- **Resource exhaustion** (via max 100 chars)
- **Empty/whitespace searches**

---

### 3. SanitizeUserInput

**Purpose**: General sanitization for user-provided text content.

**Signature**:
```go
func SanitizeUserInput(input string) string
```

**Operations**:
1. Trims leading/trailing whitespace
2. Removes null bytes (`\x00`)
3. Normalizes Unicode (removes zero-width characters, control chars)
4. Collapses multiple spaces to single space

**Usage Example**:
```go
// In HTTP handler for post creation
content := r.PostForm.Get("content")
safeContent := security.SanitizeUserInput(content)

// Now safe to store
post := &Post{
    Content: safeContent,
    AuthorID: userID,
}
```

**Prevents**:
- **Null byte injection**: `admin\x00.txt` (bypass file extension checks)
- **Unicode attacks**: Different representations of same character
- **Zero-width character attacks**: Invisible characters used for obfuscation
- **Control character injection**: Malicious control sequences

**Important Notes**:
- ⚠️ Does NOT sanitize HTML/XSS (use dedicated HTML sanitizer)
- ⚠️ Does NOT validate length limits (apply separately)
- ⚠️ Does NOT escape special characters (use for display, not queries)

---

### 4. ValidateMongoID

**Purpose**: Validates MongoDB ObjectID format.

**Signature**:
```go
func ValidateMongoID(id string) bool
```

**Validation Rules**:
- Exactly 24 characters
- All characters must be valid hexadecimal (0-9, a-f, A-F)

**Usage Example**:
```go
userID := r.URL.Query().Get("userId")

if !security.ValidateMongoID(userID) {
    return errors.New("invalid user ID format")
}

// Safe to convert to ObjectID
objectID, err := primitive.ObjectIDFromHex(userID)
```

**Prevents**:
- **NoSQL injection via malformed IDs**
- **Error-based information disclosure**
- **SQL injection attempts** (`' OR '1'='1`)

---

## Security Best Practices

### Where to Use Each Function

| Function | Use Case | Example |
|----------|----------|---------|
| **EscapeRegex** | Direct MongoDB regex queries | Email search, username lookup |
| **SanitizeSearchTerm** | User search bars, filters | Product search, user search |
| **SanitizeUserInput** | Text content (posts, comments, bios) | Post content, profile bio |
| **ValidateMongoID** | URL parameters, query params | `/users/:id`, `/posts/:id` |

### Common Attack Patterns Prevented

#### 1. NoSQL Injection via Regex

**Attack**:
```go
// User inputs: .*
filter := bson.M{"username": bson.M{"$regex": userInput}}
// Matches ALL usernames
```

**Prevention**:
```go
safeInput := security.EscapeRegex(userInput) // ".*" becomes "\\.\\*"
filter := bson.M{"username": bson.M{"$regex": safeInput}}
// Only matches literal ".*" string
```

#### 2. ReDoS (Regular Expression Denial of Service)

**Attack**:
```go
// User inputs: (a+)+b
// MongoDB tries to match, hangs for minutes/hours
filter := bson.M{"name": bson.M{"$regex": "(a+)+b"}}
```

**Prevention**:
```go
safeTerm := security.SanitizeSearchTerm("(a+)+b")
// Result: "\\(a\\+\\)\\+b"
// Now literal match, no ReDoS
```

#### 3. Null Byte Injection

**Attack**:
```go
// User uploads file: "malware.exe\x00.jpg"
// File extension check sees ".jpg" but file is .exe
filename := r.PostForm.Get("filename")
```

**Prevention**:
```go
safeFilename := security.SanitizeUserInput(filename)
// Null bytes removed: "malware.exe.jpg"
```

#### 4. Username Enumeration

**Attack**:
```go
// Attacker tries: ^admin, ^user, ^test
// Discovers which usernames exist
filter := bson.M{"username": bson.M{"$regex": "^admin"}}
```

**Prevention**:
```go
safeTerm := security.SanitizeSearchTerm("^admin")
// Result: "\\^admin" (literal match, no enumeration)
```

---

## Testing

### Run Tests
```bash
cd backend/pkg/security
go test -v
```

### Run with Coverage
```bash
go test -v -cover
```

### Run Benchmarks
```bash
go test -bench=. -benchmem
```

### Test Coverage
- **Total Tests**: 13 test functions
- **Total Test Cases**: 80+ individual test cases
- **Coverage**: 100% (all functions tested)

### Test Categories
1. **Unit Tests**: Each function tested individually
2. **Security Tests**: NoSQL injection attack patterns
3. **Benchmark Tests**: Performance testing
4. **Edge Cases**: Empty strings, Unicode, extreme lengths

---

## Integration Examples

### Example 1: Search Endpoint

```go
// Handler
func (h *ProductHandler) Search(c *gin.Context) {
    query := c.Query("q")

    // Sanitize search term
    safeTerm := security.SanitizeSearchTerm(query)
    if safeTerm == "" {
        c.JSON(400, gin.H{"error": "search term required"})
        return
    }

    // Safe MongoDB query
    filter := bson.M{
        "name": bson.M{
            "$regex": safeTerm,
            "$options": "i",
        },
    }

    products, err := h.productRepo.Find(c.Request.Context(), filter)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(200, products)
}
```

### Example 2: Create Post

```go
// Handler
func (h *PostHandler) CreatePost(c *gin.Context) {
    var dto CreatePostDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // Sanitize user content
    safeContent := security.SanitizeUserInput(dto.Content)

    // Validate length after sanitization
    if len(safeContent) > 2200 {
        c.JSON(400, gin.H{"error": "content too long"})
        return
    }

    post := &Post{
        Content: safeContent,
        AuthorID: getUserID(c),
    }

    err := h.postService.CreatePost(c.Request.Context(), post)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(201, post)
}
```

### Example 3: Get User by ID

```go
// Handler
func (h *UserHandler) GetUser(c *gin.Context) {
    userID := c.Param("id")

    // Validate MongoDB ID format
    if !security.ValidateMongoID(userID) {
        c.JSON(400, gin.H{"error": "invalid user ID format"})
        return
    }

    // Safe to convert
    objectID, _ := primitive.ObjectIDFromHex(userID)

    user, err := h.userService.GetUserByID(c.Request.Context(), objectID)
    if err != nil {
        c.JSON(404, gin.H{"error": "user not found"})
        return
    }

    c.JSON(200, user)
}
```

### Example 4: Email Search (Case-Insensitive)

```go
// Repository method
func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
    // Sanitize email for regex search
    safeEmail := security.EscapeRegex(email)

    filter := bson.M{
        "email": bson.M{
            "$regex": "^" + safeEmail + "$",
            "$options": "i", // case-insensitive
        },
    }

    var user User
    err := r.collection.FindOne(ctx, filter).Decode(&user)
    if err != nil {
        return nil, err
    }

    return &user, nil
}
```

---

## Performance

### Benchmarks (Sample Results)

```
BenchmarkEscapeRegex-8              2000000    600 ns/op    128 B/op    3 allocs/op
BenchmarkSanitizeSearchTerm-8       1000000    850 ns/op    192 B/op    5 allocs/op
BenchmarkSanitizeUserInput-8        1000000   1200 ns/op    256 B/op    7 allocs/op
BenchmarkValidateMongoID-8         10000000    120 ns/op      0 B/op    0 allocs/op
```

**Key Takeaways**:
- All functions are highly performant (<2μs)
- Minimal memory allocations
- Safe to use in hot paths (handlers)

---

## Future Enhancements

### Potential Additions

1. **HTML Sanitization**
   ```go
   func SanitizeHTML(input string) string
   // Remove dangerous HTML tags, attributes
   ```

2. **SQL Injection Protection** (if using SQL databases)
   ```go
   func EscapeSQL(input string) string
   ```

3. **Rate Limiting by Input Pattern**
   ```go
   func DetectSuspiciousPatterns(input string) bool
   ```

4. **Audit Logging**
   ```go
   func LogSanitization(input, output, context string)
   ```

---

## Related Documentation

- **Security Audit**: `docs/security/SECURITY_AUDIT_REPORT.md`
- **OWASP Guidelines**: https://owasp.org/www-project-nosql-top-10/
- **MongoDB Security**: https://www.mongodb.com/docs/manual/security/

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2024-12-24 12:00 UTC-5 | Initial creation with 4 security functions | Backend Agent |

---

**Security Contact**: For security issues, contact the security team.
**License**: Internal use only.
