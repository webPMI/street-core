# Profile Module

**Status**: ✅ Production Ready (Cleaned & Documented - 2026-01-06)
**Architecture**: Monolith by Features - Flat Structure
**Languages**: Go (Backend) + Dart/Flutter (Frontend)

## Overview

The Profile module handles user profiles, posts, and related social interactions in the StreetCore platform. It follows a flat architectural pattern optimized for simplicity and maintainability.

### Core Responsibilities

- **User Profiles**: Display and edit user information
- **Post Management**: Create, read, update, delete user posts
- **Post Statistics**: Track engagement metrics (likes, comments, views, saves)
- **Post Interactions**: Via Social feature integration
- **Saved Posts**: Save/unsave posts for later viewing
- **Privacy Settings**: User privacy and blocking functionality
- **Follow System**: Follow/unfollow users, manage relationships

## Architecture

### Backend Structure (Flat)

```
backend/features/profile/
├── model.go                  # Data models (Post, SavedPost, etc.)
├── dto.go                    # Request/Response DTOs
├── *_repository.go           # Data access layer
├── *_service.go              # Business logic layer
├── *_handler.go              # HTTP handlers
├── routes.go                 # Route definitions
├── profile_interfaces.go     # Public interfaces
└── .clinerules              # Development rules (430 lines)
```

**Key Files**:
- `post_handler.go` - Post CRUD operations
- `user_service.go` - User operations
- `follow_handler.go` - Follow/unfollow logic
- `saved_post_handler.go` - Save/unsave posts
- `privacy_handler.go` - Privacy & blocking

### Frontend Structure (Flat)

```
street_core/lib/features/profile/
├── models/                   # Data models (PostModel, UserModel)
├── services/                 # API calls & business logic
├── bloc/                     # State management (Cubits + States)
├── pages/                    # Screen widgets
├── widgets/                  # Feature-specific widgets
├── posts/widgets/            # Post-specific components
├── profile_routes.dart       # Route definitions
└── .clinerules              # Development rules (580 lines)
```

**Key Files**:
- `profile_page.dart` - Main profile screen
- `user_posts_cubit.dart` - Posts state management
- `post_detail_page.dart` - Single post view
- `profile_edit_page.dart` - Edit profile screen

## Integration with Social Feature

Profile delegates all social interactions to the dedicated Social feature:

### What Social Handles
- ✅ Likes (posts & comments)
- ✅ Comments & replies
- ✅ Saves/bookmarks
- ✅ Shares

### Profile's Responsibility
- Posts CRUD operations
- Post counter updates (via interface methods)
- Displaying posts with social interaction data
- Using Social's UI components (CommentCard, CommentInputField)

### Integration Pattern

**Backend**:
```go
// Profile calls Social via interface
type PostHandler struct {
    PostService IPostService
    LikeService social.ILikeService  // Social dependency
}

// Social calls Profile to update counters
postService.IncrementLikes(postID)
postService.IncrementComments(postID)
```

**Frontend**:
```dart
// Profile uses Social widgets
import '../../social/comment/comment_card.dart';
import '../../social/comment/comments_cubit.dart';

// In PostDetailPage
BlocProvider(
  create: (_) => getIt<CommentsCubit>()..fetchComments(postId),
  child: CommentsSection(),
)
```

## API Endpoints

### Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v2/posts` | Create new post |
| GET | `/api/v2/posts` | Get all posts (paginated) |
| GET | `/api/v2/posts/:id` | Get post by ID |
| GET | `/api/v2/posts/me` | Get current user's posts (paginated) |
| GET | `/api/v2/users/:id/posts` | Get user's posts (paginated) |
| PUT | `/api/v2/posts/:id` | Update post |
| DELETE | `/api/v2/posts/:id` | Delete post |
| PUT | `/api/v2/posts/:id/archive` | Archive/unarchive post |
| GET | `/api/v2/posts/me/stats` | Get user's post statistics |

### Saved Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v2/posts/:id/save` | Save post |
| DELETE | `/api/v2/posts/:id/save` | Unsave post |
| GET | `/api/v2/saved-posts` | Get saved posts |

### Privacy

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v2/privacy/settings` | Get privacy settings |
| PUT | `/api/v2/privacy/settings` | Update privacy settings |
| POST | `/api/v2/privacy/block` | Block user |
| DELETE | `/api/v2/privacy/unblock/:id` | Unblock user |
| GET | `/api/v2/privacy/blocked` | Get blocked users |

### Follow

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v2/follow` | Follow user |
| DELETE | `/api/v2/unfollow/:id` | Unfollow user |

## Data Models

### Post Model

```go
type Post struct {
    ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    UserID     primitive.ObjectID `bson:"userId" json:"userId"`
    UserName   string             `bson:"userName" json:"userName"`
    UserAvatar string             `bson:"userAvatar,omitempty" json:"userAvatar,omitempty"`

    Caption      string    `bson:"caption" json:"caption"`
    MediaType    MediaType `bson:"mediaType" json:"mediaType"`
    MediaURLs    []string  `bson:"mediaUrls" json:"mediaUrls"`
    ThumbnailURL string    `bson:"thumbnailUrl,omitempty" json:"thumbnailUrl,omitempty"`

    LikesCount    int `bson:"likesCount" json:"likesCount"`
    CommentsCount int `bson:"commentsCount" json:"commentsCount"`
    SharesCount   int `bson:"sharesCount" json:"sharesCount"`
    ViewsCount    int `bson:"viewsCount" json:"viewsCount"`
    SavesCount    int `bson:"savesCount" json:"savesCount"`

    Location   string         `bson:"location,omitempty" json:"location,omitempty"`
    Tags       []string       `bson:"tags,omitempty" json:"tags,omitempty"`
    Mentions   []string       `bson:"mentions,omitempty" json:"mentions,omitempty"`
    Visibility PostVisibility `bson:"visibility" json:"visibility"`

    // ⚠️ IMPORTANT: No omitempty on these fields!
    IsLikedByCurrentUser bool `bson:"-" json:"isLikedByCurrentUser"`
    IsSavedByCurrentUser bool `bson:"-" json:"isSavedByCurrentUser"`

    CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
    UpdatedAt time.Time `bson:"updatedAt" json:"updatedAt"`
}
```

**Critical Field Notes**:
- `IsLikedByCurrentUser` and `IsSavedByCurrentUser` MUST NOT have `omitempty` tag
- Backend always sends these fields (even when false) to maintain UI consistency
- Frontend trusts backend to provide accurate state

## State Management

### User Posts (Cubit Pattern)

```dart
// States
UserPostsState
├── UserPostsInitial
├── UserPostsLoading
├── UserPostsLoaded { posts, hasMore, currentPage }
├── UserPostsLoadingMore { existingPosts }
├── UserPostsEmpty
└── UserPostsError { message }

// Key Operations
- fetchUserPosts(userId, {refresh})
- loadMore(userId)  // Pagination
- toggleLike(postId)  // Optimistic update
- toggleSave(postId)  // Optimistic update
- deletePost(postId)
```

### Optimistic Updates

```dart
Future<void> toggleLike(String postId) async {
  // 1. Find post
  final post = posts.firstWhere((p) => p.id == postId);

  // 2. Optimistic UI update
  final updatedPost = post.copyWith(
    likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
    isLikedByCurrentUser: !isLiked,
  );
  emit(currentState.copyWith(posts: updatedPosts));

  // 3. API call
  try {
    await _postService.likePost(postId);
  } catch (e) {
    // 4. Revert on error
    emit(previousState);
  }
}
```

## Logging Policy

### Backend
- ✅ Use `backend/utils` centralized logger
- ❌ Never use `log.Printf` directly
- Levels: `utils.Info()`, `utils.Debug()`, `utils.Warn()`, `utils.Error()`

```go
// ✅ CORRECT
utils.Info("Creating post", map[string]interface{}{"userId": userID})
utils.Error("Error creating post", map[string]interface{}{"error": err.Error()})

// ❌ WRONG
log.Printf("Creating post for user %s", userID)
```

### Frontend
- ✅ Use `AppLogger` from `core/helpers/logger.dart`
- ❌ Never use `debugPrint` for production code
- Levels: `AppLogger.info()`, `AppLogger.debug()`, `AppLogger.error()`

```dart
// ✅ CORRECT
AppLogger.info('Fetching posts', tag: 'ProfilePage');

// ❌ WRONG
debugPrint('[ProfilePage] Fetching posts');
```

## Development Guidelines

### Adding New Features

1. **Read `.clinerules` first** - Both backend and frontend have comprehensive rules
2. **Follow flat structure** - Keep all code in feature directory
3. **Use existing patterns** - Repository → Service → Handler (backend) / Repository → Service → Cubit (frontend)
4. **Test compilation** - `go build ./features/profile/...` (backend) / `flutter analyze lib/features/profile` (frontend)

### Code Quality Standards

- ✅ No temporary debug logs
- ✅ Centralized logging
- ✅ Type-safe state management
- ✅ Optimistic UI updates
- ✅ Error handling with rollback
- ✅ Pagination for all lists
- ✅ Context usage in Go
- ✅ Proper resource cleanup (Cubit.close())

### Common Pitfalls (See .clinerules for full list)

**Backend**:
- ❌ Using `omitempty` on boolean interaction fields
- ❌ Forgetting to populate `isLikedByCurrentUser` from Social
- ❌ Not using batch queries (N+1 problem)

**Frontend**:
- ❌ Using `List.from()` without type parameter
- ❌ Using `NavigationService().go()` instead of `context.push()`
- ❌ Not checking `mounted` before async UI operations

## Testing

### Backend Tests
```bash
cd backend
go test ./features/profile/...
```

### Frontend Tests
```bash
cd street_core
flutter test lib/features/profile
flutter analyze lib/features/profile
```

## Recent Improvements (2026-01-06)

### ✅ Phase 1: Code Cleanup
- Removed 6 `debugPrint` statements from frontend
- Converted 46 `log.Printf` to centralized logger (backend)
- Cleaned all unused imports
- Verified compilation (no warnings/errors)

### ✅ Phase 2: Architecture Validation
- Investigated claimed "UserRepository duplication" → FALSE POSITIVE
- Verified `getCurrentUser` is proper layer separation
- Documented current architecture as appropriate

### ✅ Phase 3: Documentation
- Created comprehensive `.clinerules` (backend: 430 lines, frontend: 580 lines)
- Updated AUDIT_SUMMARY.md with findings
- Created this README.md

## Performance Considerations

### Backend
- Use pagination for all list endpoints (mandatory)
- Batch queries for like/save status checks (`GetUserLikesForPosts`)
- Context timeouts on all DB operations
- Indexes on: `userId`, `createdAt`, `isDeleted`, `visibility`

### Frontend
- ListView.builder for long lists (not GridView)
- Lazy loading with pagination
- Image caching (`CachedNetworkImage`)
- Cubit disposal on widget disposal

## Security

### Backend
- Verify user ownership before update/delete
- Sanitize HTML in captions (`middlewares.SanitizeHTML`)
- Validate ObjectIDs before queries
- Check authentication for interaction fields

### Frontend
- Never log sensitive data
- Clear secure storage on logout
- Validate URLs before rendering
- Check file sizes before upload

## Related Documentation

- [.clinerules (Backend)](../../backend/features/profile/.clinerules) - Development rules
- [.clinerules (Frontend)](../../../street_core/lib/features/profile/.clinerules) - Development rules
- [AUDIT_SUMMARY.md](./AUDIT_SUMMARY.md) - Cleanup & audit report
- [TRANSLATIONS.md](./TRANSLATIONS.md) - Translation keys
- [ADR-005](../../architecture/adr/ADR-005-hybrid-architecture.md) - Architecture decision
- [CLAUDE.md](../../../CLAUDE.md) - Project overview

## Maintainers

- Backend: Go team
- Frontend: Flutter team
- Last audit: 2026-01-06

---

**For questions or issues**, refer to:
1. `.clinerules` files in feature directories
2. This README
3. AUDIT_SUMMARY.md for recent changes
