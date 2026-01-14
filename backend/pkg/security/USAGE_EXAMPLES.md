# Security Package - Usage Examples

**Last Updated**: 2024-12-24 12:00 UTC-5
**Purpose**: Practical examples for integrating security sanitization functions

---

## Quick Start

Import the security package in your handlers:

```go
import "backend/pkg/security"
```

---

## Example 1: User Search (Clubs Module)

**File**: `backend/features/clubs/handler.go`

### Before (Vulnerable):
```go
func (h *ClubHandler) SearchClubs(c *gin.Context) {
    searchTerm := c.Query("q")

    // VULNERABLE: User input directly in regex
    filter := bson.M{
        "name": bson.M{
            "$regex": searchTerm, // ❌ NoSQL injection risk!
            "$options": "i",
        },
    }

    clubs, err := h.clubRepo.Find(c.Request.Context(), filter)
    // ...
}
```

### After (Secure):
```go
func (h *ClubHandler) SearchClubs(c *gin.Context) {
    searchTerm := c.Query("q")

    // ✅ Sanitize search term
    safeTerm := security.SanitizeSearchTerm(searchTerm)

    if safeTerm == "" {
        c.JSON(400, gin.H{"error": "search term required"})
        return
    }

    // Safe MongoDB query
    filter := bson.M{
        "name": bson.M{
            "$regex": safeTerm, // ✅ Protected against injection
            "$options": "i",
        },
    }

    clubs, err := h.clubRepo.Find(c.Request.Context(), filter)
    // ...
}
```

---

## Example 2: User Registration (Auth Module)

**File**: `backend/features/auth/handler.go`

### Before (Vulnerable):
```go
func (h *AuthHandler) Register(c *gin.Context) {
    var dto RegisterDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // VULNERABLE: Null bytes, control characters, etc.
    user := &User{
        Username: dto.Username,        // ❌ No sanitization
        Email:    dto.Email,           // ❌ No sanitization
        FullName: dto.FullName,        // ❌ No sanitization
        Bio:      dto.Bio,             // ❌ No sanitization
    }

    err := h.authService.CreateUser(c.Request.Context(), user)
    // ...
}
```

### After (Secure):
```go
func (h *AuthHandler) Register(c *gin.Context) {
    var dto RegisterDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // ✅ Sanitize all user inputs
    user := &User{
        Username: security.SanitizeUserInput(dto.Username),
        Email:    security.SanitizeUserInput(dto.Email),
        FullName: security.SanitizeUserInput(dto.FullName),
        Bio:      security.SanitizeUserInput(dto.Bio),
    }

    // Additional validation after sanitization
    if len(user.Username) < 3 || len(user.Username) > 30 {
        c.JSON(400, gin.H{"error": "username must be 3-30 characters"})
        return
    }

    err := h.authService.CreateUser(c.Request.Context(), user)
    // ...
}
```

---

## Example 3: Get User by ID (User Module)

**File**: `backend/handlers/user_handler.go`

### Before (Vulnerable):
```go
func (h *UserHandler) GetUserByID(c *gin.Context) {
    userID := c.Param("id")

    // VULNERABLE: Directly convert without validation
    objectID, err := primitive.ObjectIDFromHex(userID) // ❌ Can fail with injection
    if err != nil {
        c.JSON(400, gin.H{"error": "invalid ID"})
        return
    }

    user, err := h.userService.GetUserByID(c.Request.Context(), objectID)
    // ...
}
```

### After (Secure):
```go
func (h *UserHandler) GetUserByID(c *gin.Context) {
    userID := c.Param("id")

    // ✅ Validate MongoDB ID format first
    if !security.ValidateMongoID(userID) {
        c.JSON(400, gin.H{"error": "invalid user ID format"})
        return
    }

    // Safe to convert (we know it's valid hex)
    objectID, _ := primitive.ObjectIDFromHex(userID)

    user, err := h.userService.GetUserByID(c.Request.Context(), objectID)
    // ...
}
```

---

## Example 4: Create Post (Profile Module)

**File**: `backend/features/profile/handler.go`

### Before (Vulnerable):
```go
func (h *PostHandler) CreatePost(c *gin.Context) {
    var dto CreatePostDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // VULNERABLE: No sanitization
    post := &Post{
        Content:  dto.Content,         // ❌ Can contain null bytes, control chars
        Caption: dto.Caption,          // ❌ Not sanitized
        AuthorID: getUserID(c),
    }

    err := h.postService.CreatePost(c.Request.Context(), post)
    // ...
}
```

### After (Secure):
```go
func (h *PostHandler) CreatePost(c *gin.Context) {
    var dto CreatePostDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // ✅ Sanitize content and caption
    safeContent := security.SanitizeUserInput(dto.Content)
    safeCaption := security.SanitizeUserInput(dto.Caption)

    // Validate lengths AFTER sanitization
    if len(safeContent) > 2200 {
        c.JSON(400, gin.H{"error": "content exceeds 2200 characters"})
        return
    }

    if len(safeCaption) > 200 {
        c.JSON(400, gin.H{"error": "caption exceeds 200 characters"})
        return
    }

    post := &Post{
        Content:  safeContent,
        Caption: safeCaption,
        AuthorID: getUserID(c),
    }

    err := h.postService.CreatePost(c.Request.Context(), post)
    // ...
}
```

---

## Example 5: Competition Search (Competitions Module)

**File**: `backend/features/competitions/handler.go`

### Before (Vulnerable):
```go
func (h *CompetitionHandler) SearchCompetitions(c *gin.Context) {
    name := c.Query("name")
    location := c.Query("location")

    // VULNERABLE: Both parameters susceptible to regex injection
    filter := bson.M{}

    if name != "" {
        filter["name"] = bson.M{"$regex": name, "$options": "i"} // ❌
    }

    if location != "" {
        filter["location"] = bson.M{"$regex": location, "$options": "i"} // ❌
    }

    competitions, err := h.competitionRepo.Find(c.Request.Context(), filter)
    // ...
}
```

### After (Secure):
```go
func (h *CompetitionHandler) SearchCompetitions(c *gin.Context) {
    name := c.Query("name")
    location := c.Query("location")

    // ✅ Sanitize both search terms
    safeName := security.SanitizeSearchTerm(name)
    safeLocation := security.SanitizeSearchTerm(location)

    filter := bson.M{}

    if safeName != "" {
        filter["name"] = bson.M{
            "$regex": safeName,
            "$options": "i",
        }
    }

    if safeLocation != "" {
        filter["location"] = bson.M{
            "$regex": safeLocation,
            "$options": "i",
        }
    }

    // At least one search criterion required
    if len(filter) == 0 {
        c.JSON(400, gin.H{"error": "at least one search parameter required"})
        return
    }

    competitions, err := h.competitionRepo.Find(c.Request.Context(), filter)
    // ...
}
```

---

## Example 6: Contact Message (Admin Module)

**File**: `backend/handlers/contact_message_handler.go`

### Before (Vulnerable):
```go
func (h *ContactMessageHandler) CreateMessage(c *gin.Context) {
    var dto ContactMessageDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // VULNERABLE: No sanitization on message content
    message := &ContactMessage{
        Name:    dto.Name,             // ❌
        Email:   dto.Email,            // ❌
        Subject: dto.Subject,          // ❌
        Message: dto.Message,          // ❌
    }

    err := h.messageService.CreateMessage(c.Request.Context(), message)
    // ...
}
```

### After (Secure):
```go
func (h *ContactMessageHandler) CreateMessage(c *gin.Context) {
    var dto ContactMessageDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // ✅ Sanitize all input fields
    message := &ContactMessage{
        Name:    security.SanitizeUserInput(dto.Name),
        Email:   security.SanitizeUserInput(dto.Email),
        Subject: security.SanitizeUserInput(dto.Subject),
        Message: security.SanitizeUserInput(dto.Message),
    }

    // Validate after sanitization
    if message.Name == "" || message.Email == "" || message.Message == "" {
        c.JSON(400, gin.H{"error": "name, email, and message are required"})
        return
    }

    if len(message.Message) > 5000 {
        c.JSON(400, gin.H{"error": "message exceeds 5000 characters"})
        return
    }

    err := h.messageService.CreateMessage(c.Request.Context(), message)
    // ...
}
```

---

## Example 7: Update User Profile

**File**: `backend/handlers/user_profile_handler.go`

### Before (Vulnerable):
```go
func (h *UserProfileHandler) UpdateProfile(c *gin.Context) {
    userID := c.Param("id")

    var dto UpdateProfileDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // VULNERABLE: No ID validation, no input sanitization
    objectID, err := primitive.ObjectIDFromHex(userID) // ❌
    if err != nil {
        c.JSON(400, gin.H{"error": "invalid ID"})
        return
    }

    updates := bson.M{
        "bio":      dto.Bio,           // ❌
        "location": dto.Location,      // ❌
        "website":  dto.Website,       // ❌
    }

    err = h.userService.UpdateProfile(c.Request.Context(), objectID, updates)
    // ...
}
```

### After (Secure):
```go
func (h *UserProfileHandler) UpdateProfile(c *gin.Context) {
    userID := c.Param("id")

    // ✅ Validate MongoDB ID first
    if !security.ValidateMongoID(userID) {
        c.JSON(400, gin.H{"error": "invalid user ID format"})
        return
    }

    var dto UpdateProfileDTO
    if err := c.ShouldBindJSON(&dto); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    // ✅ Sanitize all input fields
    safeBio := security.SanitizeUserInput(dto.Bio)
    safeLocation := security.SanitizeUserInput(dto.Location)
    safeWebsite := security.SanitizeUserInput(dto.Website)

    // Validate lengths
    if len(safeBio) > 500 {
        c.JSON(400, gin.H{"error": "bio exceeds 500 characters"})
        return
    }

    objectID, _ := primitive.ObjectIDFromHex(userID)

    updates := bson.M{
        "bio":      safeBio,
        "location": safeLocation,
        "website":  safeWebsite,
    }

    err := h.userService.UpdateProfile(c.Request.Context(), objectID, updates)
    // ...
}
```

---

## Example 8: Email Lookup (Case-Insensitive)

**File**: `backend/features/auth/repository.go`

### Before (Vulnerable):
```go
func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
    // VULNERABLE: Email not escaped for regex
    filter := bson.M{
        "email": bson.M{
            "$regex": "^" + email + "$", // ❌ Regex injection
            "$options": "i",
        },
    }

    var user User
    err := r.collection.FindOne(ctx, filter).Decode(&user)
    return &user, err
}
```

### After (Secure):
```go
func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
    // ✅ Escape email for safe regex matching
    safeEmail := security.EscapeRegex(email)

    filter := bson.M{
        "email": bson.M{
            "$regex": "^" + safeEmail + "$",
            "$options": "i",
        },
    }

    var user User
    err := r.collection.FindOne(ctx, filter).Decode(&user)
    if err != nil {
        if err == mongo.ErrNoDocuments {
            return nil, ErrUserNotFound
        }
        return nil, err
    }

    return &user, nil
}
```

---

## Migration Checklist

Use this checklist to systematically add security sanitization to existing code:

### Phase 1: Critical Endpoints (Priority 1)
- [ ] Auth: Login, Register, Password Reset
- [ ] User: Get by ID, Update Profile
- [ ] Search: All search endpoints

### Phase 2: User-Generated Content (Priority 2)
- [ ] Posts: Create, Update
- [ ] Comments: Create, Update
- [ ] Messages: Create contact messages
- [ ] Clubs: Create, Update

### Phase 3: Admin Endpoints (Priority 3)
- [ ] Admin: User management
- [ ] Admin: Site config updates
- [ ] Admin: Security dashboard

### For Each Endpoint:
1. Identify all user inputs (query params, body, path params)
2. Choose appropriate sanitization function:
   - **Search terms** → `SanitizeSearchTerm`
   - **Text content** → `SanitizeUserInput`
   - **MongoDB IDs** → `ValidateMongoID`
   - **Regex queries** → `EscapeRegex`
3. Apply sanitization BEFORE validation
4. Validate length limits AFTER sanitization
5. Add tests for sanitization
6. Update handler documentation

---

## Testing Your Changes

After adding sanitization, test with these attack vectors:

### Test 1: Regex Injection
```bash
# Search with wildcard
curl "http://localhost:3000/api/clubs/search?q=.*"

# Expected: No results or escaped literal ".*"
# Not: All clubs returned
```

### Test 2: ReDoS Attack
```bash
# Complex regex pattern
curl "http://localhost:3000/api/competitions/search?name=(a+)+b"

# Expected: Fast response, escaped pattern
# Not: Server hangs or times out
```

### Test 3: Null Byte Injection
```bash
# Null byte in username
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin\u0000test","email":"test@example.com",...}'

# Expected: Null byte removed, "admintest" stored
# Not: "admin" stored (truncated at null)
```

### Test 4: Invalid MongoDB ID
```bash
# SQL injection attempt
curl "http://localhost:3000/api/users/' OR '1'='1"

# Expected: 400 Bad Request (invalid ID format)
# Not: 500 Internal Server Error or data leak
```

### Test 5: Unicode Attack
```bash
# Zero-width characters
curl -X POST http://localhost:3000/api/posts \
  -H "Content-Type: application/json" \
  -d '{"content":"test\u200Bword",...}'

# Expected: "testword" (zero-width removed)
# Not: "test​word" (invisible chars preserved)
```

---

## Performance Considerations

All sanitization functions are highly performant:

- **EscapeRegex**: ~600 ns/op
- **SanitizeSearchTerm**: ~850 ns/op
- **SanitizeUserInput**: ~1200 ns/op
- **ValidateMongoID**: ~120 ns/op

These are negligible compared to:
- Network latency: ~10-100ms
- Database queries: ~5-50ms
- JSON parsing: ~1-10μs

**Conclusion**: Safe to use in all handlers without performance concerns.

---

## Common Mistakes to Avoid

### Mistake 1: Sanitizing After Validation
```go
// WRONG: Validate before sanitize
if len(dto.Username) < 3 { // ❌ May include null bytes, control chars
    return errors.New("too short")
}
safeUsername := security.SanitizeUserInput(dto.Username)
```

```go
// RIGHT: Sanitize before validate
safeUsername := security.SanitizeUserInput(dto.Username)
if len(safeUsername) < 3 { // ✅ Validated on clean data
    return errors.New("too short")
}
```

### Mistake 2: Using Wrong Function
```go
// WRONG: Using SanitizeUserInput for search
searchTerm := security.SanitizeUserInput(c.Query("q")) // ❌ No regex escaping
filter := bson.M{"name": bson.M{"$regex": searchTerm}} // Still vulnerable
```

```go
// RIGHT: Use SanitizeSearchTerm
searchTerm := security.SanitizeSearchTerm(c.Query("q")) // ✅ Regex escaped
filter := bson.M{"name": bson.M{"$regex": searchTerm}} // Safe
```

### Mistake 3: Forgetting to Validate After Sanitization
```go
// WRONG: No length check after sanitization
safeContent := security.SanitizeUserInput(dto.Content)
post.Content = safeContent // ❌ Could be empty or exceed limits
```

```go
// RIGHT: Validate after sanitization
safeContent := security.SanitizeUserInput(dto.Content)
if safeContent == "" || len(safeContent) > 2200 {
    return errors.New("invalid content length")
}
post.Content = safeContent // ✅
```

---

## Questions?

For security issues or questions about these functions:
- Review: `backend/pkg/security/README.md`
- Check tests: `backend/pkg/security/sanitize_test.go`
- Contact: Security team

---

**Last Updated**: 2024-12-24 12:00 UTC-5
