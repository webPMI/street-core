package social

import (
	"context"
	"fmt"
	"backend/pkg/repository"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// likeService implementa ILikeService
type likeService struct {
	repo        repository.IRepository[Like]
	postService IPostService
}

// NewLikeService crea una nueva instancia del servicio de me gusta
func NewLikeService(db *mongo.Database, postService IPostService) ILikeService {
	collection := db.Collection("likes")
	return &likeService{
		repo:        repository.NewRepository[Like](collection),
		postService: postService,
	}
}

// LikePost crea un me gusta para una publicación
func (s *likeService) LikePost(like *Like) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	like.SetDefaults()

	if err := like.Validate(); err != nil {
		return err
	}

	// Verificar si ya le gusta
	existing, err := s.GetLike(like.PostID.Hex(), like.UserID.Hex())
	if err == nil && existing != nil {
		return fmt.Errorf("ya te gusta esta publicación")
	}

	// Crear me gusta
	_, err = s.repo.Create(ctx, like)
	if err != nil {
		return err
	}

	// Incrementar contador de me gusta en la publicación
	return s.postService.IncrementLikes(like.PostID.Hex())
}

// UnlikePost elimina un me gusta de una publicación
func (s *likeService) UnlikePost(postID, userID string) error {
	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return fmt.Errorf("formato de ID de publicación inválido: %w", err)
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("formato de ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Encontrar y eliminar
	query := repository.NewQuery().
		Where("postId", postObjID).
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

	// Decrementar contador de me gusta en la publicación
	return s.postService.DecrementLikes(postID)
}

// GetLike obtiene un me gusta específico
func (s *likeService) GetLike(postID, userID string) (*Like, error) {
	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de publicación inválido: %w", err)
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("postId", postObjID).
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

// GetPostLikes obtiene todos los me gusta de una publicación
func (s *likeService) GetPostLikes(postID string, limit int) ([]Like, error) {
	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de publicación inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().Where("postId", postObjID)
	if limit > 0 {
		query = query.Paginate(1, limit)
	}

	likes, _, err := s.repo.Find(ctx, query)
	if err != nil {
		return nil, err
	}

	return likes, nil
}

// GetUserLikes obtiene todas las publicaciones que le gustan a un usuario
func (s *likeService) GetUserLikes(userID string) ([]Like, error) {
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().Where("userId", userObjID)
	likes, _, err := s.repo.Find(ctx, query)
	if err != nil {
		return nil, err
	}

	return likes, nil
}

// GetLikeCount obtiene el número total de me gusta de una publicación
func (s *likeService) GetLikeCount(postID string) (int64, error) {
	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return 0, fmt.Errorf("formato de ID de publicación inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().Where("postId", postObjID)
	count, err := s.repo.Count(ctx, query.GetFilter())

	return count, err
}

// GetUserLikesForPosts obtiene los likes del usuario para múltiples posts (batch query)
// Retorna un mapa de postID -> true si el usuario le dio like
// OPTIMIZACIÓN: Reduce N queries a 1 sola query
func (s *likeService) GetUserLikesForPosts(userID string, postIDs []primitive.ObjectID) (map[string]bool, error) {
	if len(postIDs) == 0 {
		return make(map[string]bool), nil
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("formato de ID de usuario inválido: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Query: WHERE userId = X AND postId IN (postIDs)
	query := repository.NewQuery().
		Where("userId", userObjID).
		WhereIn("postId", postIDs)

	likes, _, err := s.repo.Find(ctx, query)
	if err != nil {
		return nil, err
	}

	// Crear mapa de resultados
	result := make(map[string]bool)
	for _, like := range likes {
		result[like.PostID.Hex()] = true
	}

	return result, nil
}
