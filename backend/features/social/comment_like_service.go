package social

import (
	"backend/pkg/repository"
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// commentLikeService implementa ICommentLikeService
type commentLikeService struct {
	repo           repository.IRepository[CommentLike]
	commentService ICommentService
}

// NewCommentLikeService crea una nueva instancia del servicio de me gusta en comentarios
func NewCommentLikeService(db *mongo.Database, commentService ICommentService) ICommentLikeService {
	collection := db.Collection("comment_likes")
	return &commentLikeService{
		repo:           repository.NewRepository[CommentLike](collection),
		commentService: commentService,
	}
}

// LikeComment crea un me gusta para un comentario
func (s *commentLikeService) LikeComment(like *CommentLike) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	like.SetDefaults()

	if err := like.Validate(); err != nil {
		return err
	}

	// Verificar si ya le gusta
	existing, err := s.GetLike(like.CommentID.Hex(), like.UserID.Hex())
	if err == nil && existing != nil {
		return fmt.Errorf("ya te gusta este comentario")
	}

	// Crear me gusta
	_, err = s.repo.Create(ctx, like)
	if err != nil {
		return err
	}

	// Incrementar contador de me gusta en el comentario
	return s.commentService.IncrementLikes(like.CommentID.Hex())
}

// UnlikeComment elimina un me gusta de un comentario
func (s *commentLikeService) UnlikeComment(commentID, userID string) error {
	commentObjID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("formato de ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Encontrar y eliminar
	query := repository.NewQuery().
		Where("commentId", commentObjID).
		Where("userId", userObjID)

	like, err := s.repo.FindOne(ctx, query)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return fmt.Errorf("me gusta no encontrado")
		}
		return err
	}

	if like == nil {
		return fmt.Errorf("me gusta no encontrado")
	}

	err = s.repo.Delete(ctx, like.ID)
	if err != nil {
		return err
	}

	// Decrementar contador de me gusta en el comentario
	return s.commentService.DecrementLikes(commentID)
}

// GetLike obtiene un me gusta específico
func (s *commentLikeService) GetLike(commentID, userID string) (*CommentLike, error) {
	commentObjID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("commentId", commentObjID).
		Where("userId", userObjID)

	like, err := s.repo.FindOne(ctx, query)
	if err == mongo.ErrNoDocuments {
		return nil, nil
	}

	if err != nil {
		return nil, err
	}

	return like, nil
}

// GetCommentLikes obtiene todos los me gusta de un comentario
func (s *commentLikeService) GetCommentLikes(commentID string, limit int) ([]CommentLike, error) {
	commentObjID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().Where("commentId", commentObjID)
	if limit > 0 {
		query = query.Paginate(1, limit)
	}

	likes, _, err := s.repo.Find(ctx, query)
	if err != nil {
		return nil, err
	}

	return likes, nil
}

// GetLikeCount obtiene el número total de me gusta de un comentario
func (s *commentLikeService) GetLikeCount(commentID string) (int64, error) {
	commentObjID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return 0, fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().Where("commentId", commentObjID)
	count, err := s.repo.Count(ctx, query.GetFilter())

	return count, err
}
