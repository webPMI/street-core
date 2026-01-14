package routes

import (
	application "backend/app"
	"backend/features/social"
	"backend/features/profile"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

// socialPostService define la interfaz interna que necesitamos para el adapter
// Incluye métodos tanto de profile.IPostService como los métodos para social
type socialPostService interface {
	profile.IPostService
	// Métodos adicionales para social (no en la interfaz pública)
	IncrementComments(postID string) error
	DecrementComments(postID string) error
	IncrementLikes(postID string) error
	DecrementLikes(postID string) error
}

// SetupUserProfileRoutes sets up user profile-related routes
// This includes avatar management, user posts, privacy settings, follow system, comments, and stories
func SetupUserProfileRoutes(version *gin.RouterGroup, container *application.Container) {
	// Initialize profile services
	privacyService := profile.NewPrivacyService(container.DB)
	// postService se obtiene como interfaz pero luego se usa como tipo extendido
	postServiceBase := profile.NewPostService(container.DB)
	// Cast al tipo extendido que incluye métodos privados para social
	postService, ok := postServiceBase.(socialPostService)
	if !ok {
		panic("postService does not implement socialPostService")
	}
	followService := profile.NewFollowService(container.DB)
	storyService := profile.NewStoryService(container.DB, followService)
	savedPostService := profile.NewSavedPostService(container.DB)

	// Create user adapter for handlers that only need basic user info
	userAdapter := profile.NewUserAdapter(container.Services.User)

	// Set user service dependency
	postService.SetUserService(container.Services.User)

	// Create PostService adapter for comments module
	// El adapter recibe el servicio que implementa tanto profile.IPostService como los métodos para social
	postServiceAdapter := &commentPostServiceAdapter{postService: postService}

	// Initialize comments module (includes comments, comment likes, and post likes)
	commentsModule := social.NewModule(container.DB, postServiceAdapter)

	// Initialize profile handlers
	postHandler := profile.NewPostHandler(postService, container.Services.User, commentsModule.LikeService)
	followHandler := profile.NewFollowHandler(followService, userAdapter)
	storyHandler := profile.NewStoryHandler(storyService, container.Services.User, followService)
	savedPostHandler := profile.NewSavedPostHandler(savedPostService)

	// Create privacy handler dependencies
	privacyDeps := profile.PrivacyHandlerDependencies{
		PrivacyService: privacyService,
	}

	// =========================================================
	// PUBLIC ROUTES (No authentication required)
	// =========================================================

	// GET /api/v2/users/:id/posts - Get user's public posts
	version.GET("/users/:id/posts", postHandler.GetUserPosts)

	// GET /api/v2/posts - Get all public posts (feed)
	version.GET("/posts", postHandler.GetAllPosts)

	// GET /api/v2/posts/:id - Get specific post
	version.GET("/posts/:id", postHandler.GetPostByID)

	// GET /api/v2/users/:id/followers - Get user's followers
	version.GET("/users/:id/followers", followHandler.GetFollowers)

	// GET /api/v2/users/:id/following - Get users that a user is following
	version.GET("/users/:id/following", followHandler.GetFollowing)

	// GET /api/v2/users/:id/stats - Get user follow statistics
	version.GET("/users/:id/stats", followHandler.GetFollowStats)

	// GET /api/v2/users/:id/stories - Get user's active stories
	version.GET("/users/:id/stories", storyHandler.GetUserStories)

	// GET /api/v2/stories/:id - Get specific story
	version.GET("/stories/:id", storyHandler.GetStory)

	// GET /api/v2/users/:id/highlights - Get user's highlights
	version.GET("/users/:id/highlights", storyHandler.GetUserHighlights)

	// =========================================================
	// PROTECTED ROUTES (JWT Authentication Required)
	// =========================================================

	protectedGroup := version.Group("")
	protectedGroup.Use(middlewares.JWTAuthMiddleware(container.Services.Auth, container.Services.TokenRevocation, container.UserRepo))
	protectedGroup.Use(middlewares.CSRFProtection())
	{
		// ---------------------------------------------------------
		// POSTS MANAGEMENT
		// ---------------------------------------------------------

		// POST /api/v2/posts - Create new post
		protectedGroup.POST("/posts", postHandler.CreatePost)

		// GET /api/v2/posts/me - Get authenticated user's posts
		protectedGroup.GET("/posts/me", postHandler.GetMyPosts)

		// GET /api/v2/posts/me/stats - Get authenticated user's post statistics
		protectedGroup.GET("/posts/me/stats", postHandler.GetMyStats)

		// PUT /api/v2/posts/:id - Update post
		protectedGroup.PUT("/posts/:id", postHandler.UpdatePost)

		// DELETE /api/v2/posts/:id - Delete post
		protectedGroup.DELETE("/posts/:id", postHandler.DeletePost)

		// PUT /api/v2/posts/:id/archive - Archive/unarchive post
		protectedGroup.PUT("/posts/:id/archive", postHandler.ArchivePost)

		// ---------------------------------------------------------
		// PRIVACY SETTINGS
		// ---------------------------------------------------------

		// GET /api/v2/users/me/privacy - Get privacy settings
		protectedGroup.GET("/users/me/privacy", profile.GetPrivacySettings(privacyDeps))

		// PUT /api/v2/users/me/privacy - Update privacy settings
		protectedGroup.PUT("/users/me/privacy", profile.UpdatePrivacySettings(privacyDeps))

		// ---------------------------------------------------------
		// BLOCK MANAGEMENT
		// ---------------------------------------------------------

		// POST /api/v2/users/me/privacy/block - Block user
		protectedGroup.POST("/users/me/privacy/block", profile.BlockUser(privacyDeps))

		// DELETE /api/v2/users/me/privacy/block/:userId - Unblock user
		protectedGroup.DELETE("/users/me/privacy/block/:userId", profile.UnblockUser(privacyDeps))

		// GET /api/v2/users/me/privacy/blocked - Get blocked users
		protectedGroup.GET("/users/me/privacy/blocked", profile.GetBlockedUsers(privacyDeps))

		// ---------------------------------------------------------
		// FOLLOW SYSTEM
		// ---------------------------------------------------------

		// POST /api/v2/users/:id/follow - Follow user
		protectedGroup.POST("/users/:id/follow", followHandler.FollowUser)

		// DELETE /api/v2/users/:id/follow - Unfollow user
		protectedGroup.DELETE("/users/:id/follow", followHandler.UnfollowUser)

		// GET /api/v2/users/:id/follow/status - Check follow status
		protectedGroup.GET("/users/:id/follow/status", followHandler.GetFollowStatus)

		// GET /api/v2/follow/requests - Get pending follow requests
		protectedGroup.GET("/follow/requests", followHandler.GetPendingRequests)

		// PUT /api/v2/follow/requests/:id/accept - Accept follow request
		protectedGroup.PUT("/follow/requests/:id/accept", followHandler.AcceptFollowRequest)

		// PUT /api/v2/follow/requests/:id/reject - Reject follow request
		protectedGroup.PUT("/follow/requests/:id/reject", followHandler.RejectFollowRequest)

		// POST /api/v2/users/:id/block - Block user
		protectedGroup.POST("/users/:id/block", followHandler.BlockUser)

		// DELETE /api/v2/users/:id/block - Unblock user
		protectedGroup.DELETE("/users/:id/block", followHandler.UnblockUser)

		// GET /api/v2/blocks - Get blocked users
		protectedGroup.GET("/blocks", followHandler.GetBlockedUsers)

		// ---------------------------------------------------------
		// STORIES MANAGEMENT
		// ---------------------------------------------------------

		// POST /api/v2/stories - Create new story
		protectedGroup.POST("/stories", storyHandler.CreateStory)

		// DELETE /api/v2/stories/:id - Delete story
		protectedGroup.DELETE("/stories/:id", storyHandler.DeleteStory)

		// POST /api/v2/stories/:id/view - Record story view
		protectedGroup.POST("/stories/:id/view", storyHandler.ViewStory)

		// GET /api/v2/stories/:id/viewers - Get story viewers
		protectedGroup.GET("/stories/:id/viewers", storyHandler.GetStoryViewers)

		// GET /api/v2/stories/following - Get stories from followed users
		protectedGroup.GET("/stories/following", storyHandler.GetFollowingStories)

		// GET /api/v2/stories/stats - Get story statistics
		protectedGroup.GET("/stories/stats", storyHandler.GetStoryStats)

		// ---------------------------------------------------------
		// STORY HIGHLIGHTS MANAGEMENT
		// ---------------------------------------------------------

		// POST /api/v2/highlights - Create story highlight
		protectedGroup.POST("/highlights", storyHandler.CreateHighlight)

		// PUT /api/v2/highlights/:id - Update highlight
		protectedGroup.PUT("/highlights/:id", storyHandler.UpdateHighlight)

		// DELETE /api/v2/highlights/:id - Delete highlight
		protectedGroup.DELETE("/highlights/:id", storyHandler.DeleteHighlight)

		// ---------------------------------------------------------
		// SAVED POSTS MANAGEMENT
		// ---------------------------------------------------------

		// POST /api/v2/posts/:id/save - Save post for later
		protectedGroup.POST("/posts/:id/save", savedPostHandler.SavePost)

		// DELETE /api/v2/posts/:id/save - Unsave post
		protectedGroup.DELETE("/posts/:id/save", savedPostHandler.UnsavePost)

		// GET /api/v2/posts/saved - Get all saved posts
		protectedGroup.GET("/posts/saved", savedPostHandler.GetMySavedPosts)

		// GET /api/v2/posts/:id/save/status - Check if post is saved
		protectedGroup.GET("/posts/:id/save/status", savedPostHandler.CheckSaveStatus)
	}

	// =========================================================
	// COMMENTS MODULE ROUTES (Public + Protected)
	// =========================================================
	authMiddleware := middlewares.JWTAuthMiddleware(container.Services.Auth, container.Services.TokenRevocation, container.UserRepo)
	social.RegisterRoutes(version, commentsModule, authMiddleware)
}

// commentPostServiceAdapter adapts profile.IPostService to social.IPostService
type commentPostServiceAdapter struct {
	postService socialPostService
}

func (a *commentPostServiceAdapter) IncrementComments(postID string) error {
	return a.postService.IncrementComments(postID)
}

func (a *commentPostServiceAdapter) DecrementComments(postID string) error {
	return a.postService.DecrementComments(postID)
}

func (a *commentPostServiceAdapter) IncrementLikes(postID string) error {
	return a.postService.IncrementLikes(postID)
}

func (a *commentPostServiceAdapter) DecrementLikes(postID string) error {
	return a.postService.DecrementLikes(postID)
}

func (a *commentPostServiceAdapter) GetPostByID(id string) (interface{}, error) {
	return a.postService.GetPostByID(id)
}
