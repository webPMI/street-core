package profile

import (
	"context"
	"time"

	"backend/pkg/pagination"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// IFollowService define las operaciones para el servicio de seguidores
type IFollowService interface {
	FollowUser(followerID, followingID string, followerName, followerAvatar, followingName, followingAvatar string, targetUserIsPrivate bool) (*Follow, error)
	UnfollowUser(followerID, followingID string) error
	AcceptFollowRequest(followID string) error
	RejectFollowRequest(followID string) error
	GetFollowers(userID string, params *pagination.Params) ([]Follow, int64, error)
	GetFollowing(userID string, params *pagination.Params) ([]Follow, int64, error)
	IsFollowing(followerID, followingID string) (bool, FollowStatus, error)
	GetFollow(followerID, followingID string) (*Follow, error)
	GetFollowStats(userID string) (*FollowStats, error)
	GetPendingRequests(userID string) ([]Follow, error)
	BlockUser(blockerID, blockedID string, blockerName, blockedName, blockedAvatar string, reason string) error
	UnblockUser(blockerID, blockedID string) error
	IsBlocked(blockerID, blockedID string) (bool, error)
	GetBlockedUsers(blockerID string) ([]Block, error)
}

// IPostService define las operaciones para el servicio de publicaciones
type IPostService interface {
	SetUserService(userService UserService)
	CreatePost(post *Post) error
	GetAllPostsPaginated(params *pagination.Params, filters map[string]interface{}) ([]Post, int64, error)
	GetPostByID(id string) (*Post, error)
	GetPostsByUserIDPaginated(userID string, params *pagination.Params, filters map[string]interface{}) ([]Post, int64, error)
	UpdatePost(id string, update *UpdatePostRequest) error
	DeletePost(id string) error
	ArchivePost(id string, archive bool) error
	IncrementViews(postID string) error
	GetUserPostStats(userID string) (*PostStats, error)
	CreatePostTransactional(ctx context.Context, post *Post) error
	DeletePostTransactional(ctx context.Context, postID string) error
	// WaitForBackgroundTasks waits for all background tasks to complete with a timeout.
	// Returns true if all tasks completed, false if timed out.
	WaitForBackgroundTasks(timeout time.Duration) bool
}

// IPrivacyService define las operaciones para el servicio de privacidad
type IPrivacyService interface {
	GetOrCreatePrivacySettings(userID primitive.ObjectID) (*PrivacySettings, error)
	UpdatePrivacySettings(userID primitive.ObjectID, req UpdatePrivacySettingsRequest) (*PrivacySettings, error)
	BlockUser(userID, userToBlockID primitive.ObjectID) error
	UnblockUser(userID, userToUnblockID primitive.ObjectID) error
	GetBlockedUsers(userID primitive.ObjectID) ([]primitive.ObjectID, error)
	IsUserBlocked(userID, targetUserID primitive.ObjectID) (bool, error)
}

// IStoryService define las operaciones para el servicio de historias
type IStoryService interface {
	CreateStory(userID, userName, userAvatar string, mediaType StoryMediaType, mediaURL, thumbnailURL, caption string, visibility StoryVisibility) (*Story, error)
	GetStoryByID(storyID string) (*Story, error)
	GetActiveUserStories(userID string) ([]Story, error)
	GetFollowingStories(userID string, followingIDs []string) ([]Story, error)
	DeleteStory(storyID, userID string) error
	ViewStory(storyID, userID, userName, userAvatar string) error
	GetStoryViewers(storyID, userID string) ([]StoryView, error)
	CreateHighlight(userID, title, coverURL string, storyIDs []string) (*StoryHighlight, error)
	GetUserHighlights(userID string) ([]StoryHighlight, error)
	UpdateHighlight(highlightID, userID, title, coverURL string, storyIDs []string) error
	DeleteHighlight(highlightID, userID string) error
	GetStoryStats(userID string) (*StoryStats, error)
	CleanupExpiredStories() error
}

// ISavedPostService define las operaciones para el servicio de posts guardados
type ISavedPostService interface {
	SavePost(savedPost *SavedPost) error
	UnsavePost(postID, userID string) error
	GetSavedPost(postID, userID string) (*SavedPost, error)
	GetUserSavedPosts(userID string) ([]SavedPost, error)
	CheckSavedStatus(postID, userID string) (bool, error)
}

// IProfileUserService define la interfaz local para el servicio de usuarios
// Esto evita dependencias circulares y define lo que este paquete necesita del módulo de usuarios
type IProfileUserService interface {
	IncrementPostCountWithContext(ctx context.Context, userID string) error
	DecrementPostCountWithContext(ctx context.Context, userID string) error
	GetUser(id string) (*User, error)
}
