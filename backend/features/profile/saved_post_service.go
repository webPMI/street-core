package profile

import (
	"context"
	"fmt"
	"backend/pkg/repository"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// savedPostService implements ISavedPostService
type savedPostService struct {
	repo repository.IRepository[SavedPost]
}

// NewSavedPostService creates a new instance of the saved posts service
func NewSavedPostService(db *mongo.Database) ISavedPostService {
	collection := db.Collection("saved_posts")
	return &savedPostService{
		repo: repository.NewRepository[SavedPost](collection),
	}
}

// SavePost saves a post for later viewing
func (s *savedPostService) SavePost(savedPost *SavedPost) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	savedPost.SetDefaults()

	if err := savedPost.Validate(); err != nil {
		return err
	}

	// Verify if already saved
	existing, err := s.GetSavedPost(savedPost.PostID.Hex(), savedPost.UserID.Hex())
	if err == nil && existing != nil {
		return fmt.Errorf("post_already_saved")
	}

	// Create saved post
	_, err = s.repo.Create(ctx, savedPost)
	return err
}

// UnsavePost removes a saved post
func (s *savedPostService) UnsavePost(postID, userID string) error {
	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return fmt.Errorf("invalid_post_id")
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return fmt.Errorf("invalid_user_id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Find and delete
	query := repository.NewQuery().
		Where("postId", postObjID).
		Where("userId", userObjID)

	savedPost, err := s.repo.FindOne(ctx, query)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return fmt.Errorf("saved_post_not_found")
		}
		return err
	}

	if savedPost == nil {
		return fmt.Errorf("saved_post_not_found")
	}

	err = s.repo.Delete(ctx, savedPost.ID)
	return err
}

// GetSavedPost gets a specific saved post
func (s *savedPostService) GetSavedPost(postID, userID string) (*SavedPost, error) {
	postObjID, err := primitive.ObjectIDFromHex(postID)
	if err != nil {
		return nil, fmt.Errorf("invalid_post_id")
	}

	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid_user_id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("postId", postObjID).
		Where("userId", userObjID)

	savedPost, err := s.repo.FindOne(ctx, query)
	if err == mongo.ErrNoDocuments {
		return nil, nil
	}

	if err != nil {
		return nil, err
	}

	return savedPost, nil
}

// GetUserSavedPosts gets all posts saved by a user
func (s *savedPostService) GetUserSavedPosts(userID string) ([]SavedPost, error) {
	userObjID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, fmt.Errorf("invalid_user_id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := repository.NewQuery().
		Where("userId", userObjID).
		SortByCreatedAt(false) // Most recent first

	savedPosts, _, err := s.repo.Find(ctx, query)
	if err != nil {
		return nil, err
	}

	return savedPosts, nil
}

// CheckSavedStatus checks if a user has saved a post
func (s *savedPostService) CheckSavedStatus(postID, userID string) (bool, error) {
	savedPost, err := s.GetSavedPost(postID, userID)
	if err != nil {
		return false, err
	}
	return savedPost != nil, nil
}
