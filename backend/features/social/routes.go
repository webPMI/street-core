package social

import (
	"backend/middlewares"
	"github.com/gin-gonic/gin"
)

func RegisterRoutes(version *gin.RouterGroup, module *Module, authMiddleware gin.HandlerFunc) {
	commentHandler := NewCommentHandler(module.CommentService, module.CommentLikeService)
	commentLikeHandler := NewCommentLikeHandler(module.CommentLikeService, module.CommentService)
	likeHandler := NewLikeHandler(module.LikeService, nil) // PostService inyectado en module

	// Rutas públicas
	version.GET("/posts/:id/comments", commentHandler.GetPostComments)
	version.GET("/comments/:commentId/replies", commentHandler.GetCommentReplies)
	version.GET("/comments/:commentId/likes", commentLikeHandler.GetCommentLikes)
	version.GET("/posts/:id/likes", likeHandler.GetPostLikes)

	// Rutas protegidas
	protected := version.Group("")
	protected.Use(authMiddleware)
	protected.Use(middlewares.CSRFProtection())
	{
		// Comments
		protected.POST("/posts/:id/comments", commentHandler.CreateComment)
		protected.PUT("/comments/:commentId", commentHandler.UpdateComment)
		protected.DELETE("/comments/:commentId", commentHandler.DeleteComment)
		protected.GET("/comments/me", commentHandler.GetMyComments)

		// Comment Likes
		protected.POST("/comments/:commentId/like", commentLikeHandler.LikeComment)
		protected.DELETE("/comments/:commentId/like", commentLikeHandler.UnlikeComment)
		protected.GET("/comments/:commentId/like/status", commentLikeHandler.CheckLikeStatus)

		// Post Likes
		protected.POST("/posts/:id/like", likeHandler.LikePost)
		protected.DELETE("/posts/:id/like", likeHandler.UnlikePost)
		protected.GET("/likes/me", likeHandler.GetMyLikes)
		protected.GET("/posts/:id/like/status", likeHandler.CheckLikeStatus)
	}
}
