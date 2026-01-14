package social

import (
	"context"
	"fmt"
	"backend/pkg/pagination"
	"backend/pkg/repository"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// commentService implementa ICommentService
type commentService struct {
	repo        repository.IRepository[Comment]
	coll        *mongo.Collection
	postService IPostService
}

// NewCommentService crea una nueva instancia del servicio de comentarios
func NewCommentService(db *mongo.Database, postService IPostService) ICommentService {
	collection := db.Collection("comments")
	return &commentService{
		repo:        repository.NewRepository[Comment](collection),
		coll:        collection,
		postService: postService,
	}
}

// CreateComment crea un nuevo comentario
func (s *commentService) CreateComment(comment *Comment) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	comment.SetDefaults()

	if err := comment.Validate(); err != nil {
		return err
	}

	// Si es una respuesta, incrementar el contador de respuestas del comentario padre
	if comment.ParentCommentID != nil {
		if err := s.IncrementReplies(comment.ParentCommentID.Hex()); err != nil {
			return err
		}
	}

	// Crear comentario y obtener el ID generado
	createdComment, err := s.repo.Create(ctx, comment)
	if err != nil {
		return err
	}

	// Actualizar el comment con el ID generado
	*comment = *createdComment

	// Incrementar contador de comentarios en la publicación
	return s.postService.IncrementComments(comment.PostID.Hex())
}

// GetCommentByID obtiene un comentario por su ID
func (s *commentService) GetCommentByID(id string) (*Comment, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	query := repository.NewQuery().
		Where("_id", objectID).
		Where("isDeleted", false)

	comment, err := s.repo.FindOne(ctx, query)
	if err != nil {
		return nil, err
	}

	return comment, nil
}

// GetPostComments obtiene todos los comentarios de una publicación (solo nivel superior)
func (s *commentService) GetPostComments(postID string) ([]Comment, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de publicación inválido: %w", err)
	}

	query := repository.NewQuery().
		Where("postId", postObjID).
		Where("parentCommentId", nil).
		Where("isDeleted", false)

	comments, _, err := s.repo.Find(ctx, query)
	return comments, err
}

// GetPostCommentsPaginated obtiene comentarios paginados para una publicación
func (s *commentService) GetPostCommentsPaginated(postID string, params *pagination.Params) ([]Comment, int64, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return nil, 0, fmt.Errorf("formato de ID de publicación inválido: %w", err)
	}

	filter := bson.M{
		"postId":          postObjID,
		"parentCommentId": nil,
		"isDeleted":       false,
	}

	query := repository.NewQuery().
		WhereRaw(filter).
		Paginate(params.Page, params.Limit)

	return s.repo.Find(ctx, query)
}

// GetCommentReplies obtiene todas las respuestas a un comentario
func (s *commentService) GetCommentReplies(commentID string) ([]Comment, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	commentObjID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	query := repository.NewQuery().
		Where("parentCommentId", commentObjID).
		Where("isDeleted", false)

	replies, _, err := s.repo.Find(ctx, query)
	return replies, err
}

// UpdateComment actualiza un comentario
func (s *commentService) UpdateComment(id string, update *UpdateCommentRequest) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	updateDoc := bson.M{
		"text":      update.Text,
		"isEdited":  true,
		"updatedAt": time.Now(),
	}

	// Asegurar que no esté eliminado
	_, err = s.coll.UpdateOne(
		ctx,
		bson.M{"_id": objectID, "isDeleted": false},
		bson.M{"$set": updateDoc},
	)
	return err
}

// DeleteComment elimina suavemente un comentario
func (s *commentService) DeleteComment(id string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	// Obtener comentario para encontrar postID y parentCommentID
	comment, err := s.repo.GetByID(ctx, objectID)
	if err != nil {
		return err
	}

	// Soft delete
	now := time.Now()
	updateDoc := bson.M{
		"$set": bson.M{
			"isDeleted": true,
			"deletedAt": now,
			"updatedAt": now,
		},
	}

	if err := s.repo.Update(ctx, objectID, updateDoc); err != nil {
		return err
	}

	// Decrementar contador de comentarios en la publicación
	if err := s.postService.DecrementComments(comment.PostID.Hex()); err != nil {
		return err
	}

	// Si es una respuesta, decrementar contador de respuestas del padre
	if comment.ParentCommentID != nil {
		if err := s.DecrementReplies(comment.ParentCommentID.Hex()); err != nil {
			return err
		}
	}

	return nil
}

// IncrementLikes incrementa el contador de me gusta
func (s *commentService) IncrementLikes(commentID string) error {
	objectID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = s.coll.UpdateOne(
		ctx,
		bson.M{"_id": objectID},
		bson.M{
			"$inc": bson.M{"likesCount": 1},
			"$set": bson.M{"updatedAt": time.Now()},
		},
	)
	return err
}

// DecrementLikes decrementa el contador de me gusta
func (s *commentService) DecrementLikes(commentID string) error {
	objectID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = s.coll.UpdateOne(
		ctx,
		bson.M{"_id": objectID, "likesCount": bson.M{"$gt": 0}},
		bson.M{
			"$inc": bson.M{"likesCount": -1},
			"$set": bson.M{"updatedAt": time.Now()},
		},
	)
	return err
}

// IncrementReplies incrementa el contador de respuestas
func (s *commentService) IncrementReplies(commentID string) error {
	objectID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = s.coll.UpdateOne(
		ctx,
		bson.M{"_id": objectID},
		bson.M{
			"$inc": bson.M{"repliesCount": 1},
			"$set": bson.M{"updatedAt": time.Now()},
		},
	)
	return err
}

// DecrementReplies decrementa el contador de respuestas
func (s *commentService) DecrementReplies(commentID string) error {
	objectID, err := primitive.ObjectIDFromHex(commentID)
	if err != nil {
		return fmt.Errorf("formato de ID de comentario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = s.coll.UpdateOne(
		ctx,
		bson.M{"_id": objectID, "repliesCount": bson.M{"$gt": 0}},
		bson.M{
			"$inc": bson.M{"repliesCount": -1},
			"$set": bson.M{"updatedAt": time.Now()},
		},
	)
	return err
}

// GetUserComments obtiene todos los comentarios de un usuario
func (s *commentService) GetUserComments(userID string) ([]Comment, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de usuario inválido: %w", err)
	}

	query := repository.NewQuery().
		Where("userId", userObjID).
		Where("isDeleted", false)

	comments, _, err := s.repo.Find(ctx, query)
	return comments, err
}
