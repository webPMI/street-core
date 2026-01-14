package social

import "go.mongodb.org/mongo-driver/mongo"

type Module struct {
	CommentService     ICommentService
	CommentLikeService ICommentLikeService
	LikeService        ILikeService
}

func NewModule(db *mongo.Database, postService IPostService) *Module {
	commentService := NewCommentService(db, postService)
	commentLikeService := NewCommentLikeService(db, commentService)
	likeService := NewLikeService(db, postService)

	return &Module{
		CommentService:     commentService,
		CommentLikeService: commentLikeService,
		LikeService:        likeService,
	}
}
