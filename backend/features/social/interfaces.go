package social

import (
	"backend/pkg/pagination"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ICommentService define las operaciones para el servicio de comentarios
type ICommentService interface {
	CreateComment(comment *Comment) error
	GetCommentByID(id string) (*Comment, error)
	GetPostComments(postID string) ([]Comment, error)
	GetPostCommentsPaginated(postID string, params *pagination.Params) ([]Comment, int64, error)
	GetCommentReplies(commentID string) ([]Comment, error)
	UpdateComment(id string, update *UpdateCommentRequest) error
	DeleteComment(id string) error
	IncrementLikes(commentID string) error
	DecrementLikes(commentID string) error
	IncrementReplies(commentID string) error
	DecrementReplies(commentID string) error
	GetUserComments(userID string) ([]Comment, error)
}

// ICommentLikeService define las operaciones para el servicio de 'me gusta' en comentarios
type ICommentLikeService interface {
	LikeComment(like *CommentLike) error
	UnlikeComment(commentID, userID string) error
	GetLike(commentID, userID string) (*CommentLike, error)
	GetCommentLikes(commentID string, limit int) ([]CommentLike, error)
	GetLikeCount(commentID string) (int64, error)
}

// ILikeService define las operaciones para el servicio de 'me gusta'
type ILikeService interface {
	LikePost(like *Like) error
	UnlikePost(postID, userID string) error
	GetLike(postID, userID string) (*Like, error)
	GetPostLikes(postID string, limit int) ([]Like, error)
	GetUserLikes(userID string) ([]Like, error)
	GetLikeCount(postID string) (int64, error)
	GetUserLikesForPosts(userID string, postIDs []primitive.ObjectID) (map[string]bool, error)
}

// IPostService define la interfaz que necesitamos del servicio de posts
// Esto evita dependencias circulares
// NOTA: Social necesita poder actualizar contadores de posts
type IPostService interface {
	IncrementComments(postID string) error
	DecrementComments(postID string) error
	IncrementLikes(postID string) error
	DecrementLikes(postID string) error
	GetPostByID(id string) (interface{}, error)
}
