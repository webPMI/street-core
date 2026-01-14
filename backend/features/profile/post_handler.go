package profile

import (
	"backend/features/social"
	"backend/middlewares"
	"backend/models"
	"backend/pkg/pagination"
	"backend/pkg/response"
	"backend/utils"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type PostHandler struct {
	PostService IPostService
	UserService UserService
	LikeService social.ILikeService
}

func NewPostHandler(service IPostService, userService UserService, likeService social.ILikeService) *PostHandler {
	return &PostHandler{
		PostService: service,
		UserService: userService,
		LikeService: likeService,
	}
}

// parsePostFilters extracts filter parameters from query string
func parsePostFilters(c *gin.Context) map[string]interface{} {
	filters := make(map[string]interface{})

	// Search query
	if search := c.Query("search"); search != "" {
		filters["search"] = search
	}

	// Filter by media type
	if mediaType := c.Query("media_type"); mediaType != "" {
		filters["media_type"] = mediaType
	}

	// Filter by tag
	if tag := c.Query("tag"); tag != "" {
		filters["tag"] = tag
	}

	// Filter by user ID
	if userID := c.Query("user_id"); userID != "" {
		if oid, err := primitive.ObjectIDFromHex(userID); err == nil {
			filters["user_id"] = oid
		}
	}

	// Include archived posts
	if archived := c.Query("archived"); archived == "true" {
		filters["include_archived"] = true
	}

	// Filter by visibility (can be multiple)
	if visibilityStr := c.Query("visibility"); visibilityStr != "" {
		visibilityValues := strings.Split(visibilityStr, ",")
		var visibilities []PostVisibility
		for _, v := range visibilityValues {
			visibilities = append(visibilities, PostVisibility(strings.TrimSpace(v)))
		}
		filters["visibility"] = visibilities
	}

	return filters
}

// CreatePost creates a new post
// POST /posts
func (h *PostHandler) CreatePost(c *gin.Context) {
	utils.Info("Creating new post", nil)

	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error("Error parsing JSON", map[string]interface{}{"error": err.Error()})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": models.RequiredField})
		return
	}

	// Get user ID from context (set by auth middleware)
	userID, exists := c.Get("userID")
	if !exists {
		utils.Error("User ID not found in context", nil)
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": models.Unauthorized})
		return
	}

	userObjID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		utils.Error("Invalid user ID", map[string]interface{}{"error": err.Error()})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": models.RequiredField})
		return
	}

	// Get full user info from database to populate userName and userAvatar
	user, err := h.UserService.GetUserByObjectID(c.Request.Context(), userObjID)
	if err != nil {
		utils.Error("Error fetching user", map[string]interface{}{"error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	// Build full name
	fullName := user.FirstName
	if user.LastName != "" {
		fullName += " " + user.LastName
	}

	// Create post
	post := &Post{
		UserID:     userObjID,
		UserName:   fullName,
		UserAvatar: user.AvatarURL,
		Caption:    middlewares.SanitizeHTML(req.Caption),
		MediaType:  req.MediaType,
		MediaURLs:  req.MediaURLs,
		Location:   req.Location,
		Tags:       req.Tags,
		Mentions:   req.Mentions,
		Visibility: req.Visibility,
	}

	if err := h.PostService.CreatePost(post); err != nil {
		utils.Error("Error creating post", map[string]interface{}{"error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	// Establecer campos de interacción como false para posts nuevos
	post.IsLikedByCurrentUser = false
	post.IsSavedByCurrentUser = false

	utils.Info("Post created successfully", map[string]interface{}{"postId": post.ID.Hex()})
	response.Success(c, http.StatusCreated, "post_created_successfully", post)
}

// GetAllPosts gets all public posts with mandatory pagination
// GET /posts
func (h *PostHandler) GetAllPosts(c *gin.Context) {
	utils.Info("Getting all posts with pagination", nil)

	// Parse pagination parameters with defaults
	params := pagination.ParseParams(c)

	// Parse filters
	filters := parsePostFilters(c)
	if len(filters) > 0 {
		utils.Debug("Applying filters", map[string]interface{}{"filters": filters})
	}

	// ALWAYS use paginated version
	posts, total, err := h.PostService.GetAllPostsPaginated(params, filters)
	if err != nil {
		utils.Error("Error getting posts", map[string]interface{}{"error": err.Error()})
		response.Error(c, http.StatusInternalServerError, models.ServerError)
		return
	}

	// Check if user liked each post (if authenticated) - OPTIMIZED WITH BATCH QUERY
	if userID, exists := c.Get("userID"); exists {
		// Collect all post IDs
		postIDs := make([]primitive.ObjectID, len(posts))
		for i := range posts {
			postIDs[i] = posts[i].ID
		}

		// Batch query: Get all likes for this user in one query
		likedPosts, err := h.LikeService.GetUserLikesForPosts(userID.(string), postIDs)
		if err == nil {
			// Set IsLikedByCurrentUser for each post
			for i := range posts {
				posts[i].IsLikedByCurrentUser = likedPosts[posts[i].ID.Hex()]
			}
		}
	}

	// Create pagination response
	paginatedResp := pagination.CreateResponse(params.Page, params.Limit, total, posts)
	utils.Debug("Returning paginated posts", map[string]interface{}{"page": params.Page, "total": total})
	response.Success(c, http.StatusOK, "", paginatedResp)
}

// GetPostByID gets a specific post
// GET /posts/:id
func (h *PostHandler) GetPostByID(c *gin.Context) {
	id := c.Param("id")
	utils.Info("Getting post by ID", map[string]interface{}{"postId": id})

	post, err := h.PostService.GetPostByID(id)
	if err != nil {
		utils.Error("Post not found", map[string]interface{}{"postId": id, "error": err.Error()})
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "post_not_found"})
		return
	}

	// Check if user liked this post (if authenticated)
	if userID, exists := c.Get("userID"); exists {
		like, _ := h.LikeService.GetLike(id, userID.(string))
		post.IsLikedByCurrentUser = (like != nil)
	}

	utils.Info("Post found", map[string]interface{}{"postId": id})
	c.JSON(http.StatusOK, gin.H{"status": "success", "data": post})
}

// GetMyPosts gets all posts by the authenticated user with mandatory pagination
// GET /posts/me
func (h *PostHandler) GetMyPosts(c *gin.Context) {
	utils.Info("Getting user's own posts with pagination", nil)

	// Get user ID from context using base helper
	userObjectID, err := middlewares.GetUserIDFromContext(c)
	if err != nil {
		return
	}

	// Parse pagination parameters with defaults
	params := pagination.ParseParams(c)

	// Parse filters
	filters := parsePostFilters(c)
	if len(filters) > 0 {
		utils.Debug("Applying filters", map[string]interface{}{"filters": filters})
	}

	// ALWAYS use paginated version
	posts, total, err := h.PostService.GetPostsByUserIDPaginated(userObjectID.Hex(), params, filters)
	if err != nil {
		utils.Error("Error getting user posts", map[string]interface{}{"error": err.Error()})
		response.Error(c, http.StatusInternalServerError, models.ServerError)
		return
	}

	// Check if user liked each post - OPTIMIZED WITH BATCH QUERY
	userIDStr := userObjectID.Hex()

	// Collect all post IDs
	postIDs := make([]primitive.ObjectID, len(posts))
	for i := range posts {
		postIDs[i] = posts[i].ID
	}

	// Batch query: Get all likes for this user in one query
	likedPosts, err := h.LikeService.GetUserLikesForPosts(userIDStr, postIDs)
	if err == nil {
		// Set IsLikedByCurrentUser for each post
		for i := range posts {
			posts[i].IsLikedByCurrentUser = likedPosts[posts[i].ID.Hex()]
		}
	}

	// Create pagination response
	paginatedResp := pagination.CreateResponse(params.Page, params.Limit, total, posts)
	utils.Debug("Returning paginated user posts", map[string]interface{}{"page": params.Page, "total": total})
	response.Success(c, http.StatusOK, "", paginatedResp)
}

// GetUserPosts gets posts by a specific user with mandatory pagination
// GET /users/:id/posts
func (h *PostHandler) GetUserPosts(c *gin.Context) {
	userIDParam := c.Param("id")
	utils.Info("Getting posts for user with pagination", map[string]interface{}{"userId": userIDParam})

	// Parse pagination parameters with defaults
	params := pagination.ParseParams(c)

	// Parse filters
	filters := parsePostFilters(c)
	if len(filters) > 0 {
		utils.Debug("Applying filters", map[string]interface{}{"filters": filters})
	}

	// ALWAYS use paginated version
	posts, total, err := h.PostService.GetPostsByUserIDPaginated(userIDParam, params, filters)
	if err != nil {
		utils.Error("Error getting user posts", map[string]interface{}{"userId": userIDParam, "error": err.Error()})
		response.Error(c, http.StatusInternalServerError, models.ServerError)
		return
	}

	// Check if user liked each post (if authenticated) - OPTIMIZED WITH BATCH QUERY
	if userID, exists := c.Get("userID"); exists {
		// Collect all post IDs
		postIDs := make([]primitive.ObjectID, len(posts))
		for i := range posts {
			postIDs[i] = posts[i].ID
		}

		// Batch query: Get all likes for this user in one query
		likedPosts, err := h.LikeService.GetUserLikesForPosts(userID.(string), postIDs)
		if err == nil {
			// Set IsLikedByCurrentUser for each post
			for i := range posts {
				posts[i].IsLikedByCurrentUser = likedPosts[posts[i].ID.Hex()]
			}
		}
	}

	// Create pagination response
	paginatedResp := pagination.CreateResponse(params.Page, params.Limit, total, posts)
	utils.Debug("Returning paginated posts", map[string]interface{}{"page": params.Page, "total": total})
	response.Success(c, http.StatusOK, "", paginatedResp)
}

// UpdatePost updates a post
// PUT /posts/:id
func (h *PostHandler) UpdatePost(c *gin.Context) {
	id := c.Param("id")
	utils.Info("Updating post", map[string]interface{}{"postId": id})

	var req UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Error("Error parsing JSON", map[string]interface{}{"error": err.Error()})
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": models.RequiredField})
		return
	}

	// Verify ownership
	post, err := h.PostService.GetPostByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "post_not_found"})
		return
	}

	userID, _ := c.Get("userID")
	if post.UserID.Hex() != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"status": "error", "message": "forbidden"})
		return
	}

	// Sanitize caption if provided
	if req.Caption != nil {
		sanitized := middlewares.SanitizeHTML(*req.Caption)
		req.Caption = &sanitized
	}

	if err := h.PostService.UpdatePost(id, &req); err != nil {
		utils.Error("Error updating post", map[string]interface{}{"postId": id, "error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	utils.Info("Post updated successfully", map[string]interface{}{"postId": id})
	response.Success(c, http.StatusOK, "post_updated_successfully", nil)
}

// DeletePost deletes a post
// DELETE /posts/:id
func (h *PostHandler) DeletePost(c *gin.Context) {
	id := c.Param("id")
	utils.Info("Deleting post", map[string]interface{}{"postId": id})

	// Verify ownership
	post, err := h.PostService.GetPostByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "post_not_found"})
		return
	}

	userID, _ := c.Get("userID")
	if post.UserID.Hex() != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"status": "error", "message": "forbidden"})
		return
	}

	if err := h.PostService.DeletePost(id); err != nil {
		utils.Error("Error deleting post", map[string]interface{}{"postId": id, "error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	utils.Info("Post deleted successfully", map[string]interface{}{"postId": id})
	response.Success(c, http.StatusOK, "post_deleted_successfully", nil)
}

// ArchivePost archives/unarchives a post
// PUT /posts/:id/archive
func (h *PostHandler) ArchivePost(c *gin.Context) {
	id := c.Param("id")
	archive := c.Query("archive") == "true"
	utils.Info("Archiving post", map[string]interface{}{"postId": id, "archive": archive})

	// Verify ownership
	post, err := h.PostService.GetPostByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "post_not_found"})
		return
	}

	userID, _ := c.Get("userID")
	if post.UserID.Hex() != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"status": "error", "message": "forbidden"})
		return
	}

	if err := h.PostService.ArchivePost(id, archive); err != nil {
		utils.Error("Error archiving post", map[string]interface{}{"postId": id, "error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	message := "post_archived_successfully"
	if !archive {
		message = "post_unarchived_successfully"
	}

	utils.Info("Post archive status updated", map[string]interface{}{"postId": id, "archived": archive})
	c.JSON(http.StatusOK, gin.H{"status": "success", "message": message})
}

// GetMyStats gets statistics for the authenticated user's posts
// GET /posts/me/stats
func (h *PostHandler) GetMyStats(c *gin.Context) {
	utils.Info("Getting user post stats", nil)

	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": models.Unauthorized})
		return
	}

	stats, err := h.PostService.GetUserPostStats(userID.(string))
	if err != nil {
		utils.Error("Error getting stats", map[string]interface{}{"error": err.Error()})
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": models.ServerError})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "data": stats})
}
