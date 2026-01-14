package profile

import (
	"backend/models"
	"context"
	"errors"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// UserService defines the user service interface
type UserService interface {
	GetUser(id string) (*models.User, error)
	GetUserByEmail(email string) (*models.User, error)
	GetUserByObjectID(ctx context.Context, id primitive.ObjectID) (*models.User, error)
	CreateUser(user *models.User) error
	UpdateUser(id string, updates map[string]interface{}) error
	DeleteUser(id string) error
	ChangePassword(id, oldPassword, newPassword string) error
	GetCurrentUser(id string) (*models.User, error)
	IncrementPostCountWithContext(ctx context.Context, userID string) error
	DecrementPostCountWithContext(ctx context.Context, userID string) error
}

// userServiceImpl implements UserService interface
type userServiceImpl struct {
	db         *mongo.Database
	collection *mongo.Collection
}

// NewUserService creates a new user service instance
func NewUserService(db *mongo.Database) UserService {
	return &userServiceImpl{
		db:         db,
		collection: db.Collection("users"),
	}
}

// GetUser retrieves a user by ID
func (s *userServiceImpl) GetUser(id string) (*models.User, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, errors.New("invalid user ID")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var user models.User
	err = s.collection.FindOne(ctx, bson.M{"_id": objectID}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("user not found")
		}
		return nil, err
	}

	return &user, nil
}

// GetUserByEmail retrieves a user by email
func (s *userServiceImpl) GetUserByEmail(email string) (*models.User, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var user models.User
	err := s.collection.FindOne(ctx, bson.M{"email": strings.ToLower(email)}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("user not found")
		}
		return nil, err
	}

	return &user, nil
}

// GetUserByObjectID retrieves a user by ObjectID
func (s *userServiceImpl) GetUserByObjectID(ctx context.Context, id primitive.ObjectID) (*models.User, error) {
	var user models.User
	err := s.collection.FindOne(ctx, bson.M{"_id": id}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("user not found")
		}
		return nil, err
	}

	return &user, nil
}

// CreateUser creates a new user
func (s *userServiceImpl) CreateUser(user *models.User) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := user.PrepareForInsert(); err != nil {
		return err
	}

	_, err := s.collection.InsertOne(ctx, user)
	return err
}

// UpdateUser updates a user by ID
func (s *userServiceImpl) UpdateUser(id string, updates map[string]interface{}) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return errors.New("invalid user ID")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	updates["updatedAt"] = time.Now()

	_, err = s.collection.UpdateOne(ctx,
		bson.M{"_id": objectID},
		bson.M{"$set": updates},
	)
	return err
}

// DeleteUser deletes a user by ID
func (s *userServiceImpl) DeleteUser(id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return errors.New("invalid user ID")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = s.collection.DeleteOne(ctx, bson.M{"_id": objectID})
	return err
}

// ChangePassword changes a user's password
func (s *userServiceImpl) ChangePassword(id, oldPassword, newPassword string) error {
	user, err := s.GetUser(id)
	if err != nil {
		return err
	}

	if !user.MatchPassword(oldPassword) {
		return errors.New("invalid old password")
	}

	hashedPassword, err := models.HashPassword(newPassword)
	if err != nil {
		return err
	}

	return s.UpdateUser(id, map[string]interface{}{
		"password":     hashedPassword,
		"tokenVersion": user.TokenVersion + 1, // Invalidate all tokens
	})
}

// GetCurrentUser retrieves the current authenticated user
func (s *userServiceImpl) GetCurrentUser(id string) (*models.User, error) {
	return s.GetUser(id)
}

// IncrementPostCountWithContext increments user's post count
func (s *userServiceImpl) IncrementPostCountWithContext(ctx context.Context, userID string) error {
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return errors.New("invalid user ID")
	}

	_, err = s.collection.UpdateOne(ctx,
		bson.M{"_id": objectID},
		bson.M{"$inc": bson.M{"postCount": 1}},
	)
	return err
}

// DecrementPostCountWithContext decrements user's post count
func (s *userServiceImpl) DecrementPostCountWithContext(ctx context.Context, userID string) error {
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return errors.New("invalid user ID")
	}

	_, err = s.collection.UpdateOne(ctx,
		bson.M{"_id": objectID},
		bson.M{"$inc": bson.M{"postCount": -1}},
	)
	return err
}
