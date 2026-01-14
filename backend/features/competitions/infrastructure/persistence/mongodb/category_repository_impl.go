package mongodb

import (
	"context"
	"time"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CategoryRepositoryImpl implements the CategoryRepository interface
type CategoryRepositoryImpl struct {
	collection *mongo.Collection
}

// NewCategoryRepository creates a new category repository
func NewCategoryRepository(db *mongo.Database) repositories.CategoryRepository {
	return &CategoryRepositoryImpl{
		collection: db.Collection("competition_categories"),
	}
}

// Save creates a new category
func (r *CategoryRepositoryImpl) Save(ctx context.Context, category *entities.Category) error {
	_, err := r.collection.InsertOne(ctx, category)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return entities.ErrCategoryNotFound
		}
		return err
	}
	return nil
}

// Update updates an existing category
func (r *CategoryRepositoryImpl) Update(ctx context.Context, category *entities.Category) error {
	category.PrepareForUpdate()

	filter := bson.M{"_id": category.ID}
	update := bson.M{"$set": category}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return entities.ErrCategoryNotFound
	}

	return nil
}

// FindByID finds a category by ID
func (r *CategoryRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Category, error) {
	var category entities.Category
	filter := bson.M{"_id": id}

	err := r.collection.FindOne(ctx, filter).Decode(&category)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, entities.ErrCategoryNotFound
		}
		return nil, err
	}

	return &category, nil
}

// FindByCompetitionID finds all categories for a competition
func (r *CategoryRepositoryImpl) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID, page, limit int) ([]*entities.Category, int64, error) {
	filter := bson.M{"competitionId": competitionID}

	// Count total documents
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// Find with pagination
	skip := (page - 1) * limit
	findOptions := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"order": 1, "createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var categories []*entities.Category
	if err := cursor.All(ctx, &categories); err != nil {
		return nil, 0, err
	}

	return categories, total, nil
}

// Delete deletes a category by ID
func (r *CategoryRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}

	result, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return entities.ErrCategoryNotFound
	}

	return nil
}

// AddParticipant adds a participant to a category
func (r *CategoryRepositoryImpl) AddParticipant(ctx context.Context, categoryID, participantID primitive.ObjectID) error {
	filter := bson.M{"_id": categoryID}
	update := bson.M{
		"$addToSet": bson.M{
			"participantIds": participantID,
		},
		"$inc": bson.M{
			"currentParticipants": 1,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return entities.ErrCategoryNotFound
	}

	return nil
}

// RemoveParticipant removes a participant from a category
func (r *CategoryRepositoryImpl) RemoveParticipant(ctx context.Context, categoryID, participantID primitive.ObjectID) error {
	filter := bson.M{"_id": categoryID}
	update := bson.M{
		"$pull": bson.M{
			"participantIds": participantID,
		},
		"$inc": bson.M{
			"currentParticipants": -1,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return entities.ErrCategoryNotFound
	}

	return nil
}

// IsParticipant checks if a user is a participant in a category
func (r *CategoryRepositoryImpl) IsParticipant(ctx context.Context, categoryID, participantID primitive.ObjectID) (bool, error) {
	filter := bson.M{
		"_id":            categoryID,
		"participantIds": participantID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

// AddJudge adds a judge to a category
func (r *CategoryRepositoryImpl) AddJudge(ctx context.Context, categoryID, judgeID primitive.ObjectID) error {
	filter := bson.M{"_id": categoryID}
	update := bson.M{
		"$addToSet": bson.M{
			"judgeIds": judgeID,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return entities.ErrCategoryNotFound
	}

	return nil
}

// RemoveJudge removes a judge from a category
func (r *CategoryRepositoryImpl) RemoveJudge(ctx context.Context, categoryID, judgeID primitive.ObjectID) error {
	filter := bson.M{"_id": categoryID}
	update := bson.M{
		"$pull": bson.M{
			"judgeIds": judgeID,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return entities.ErrCategoryNotFound
	}

	return nil
}

// IsJudge checks if a user is a judge in a category
func (r *CategoryRepositoryImpl) IsJudge(ctx context.Context, categoryID, judgeID primitive.ObjectID) (bool, error) {
	filter := bson.M{
		"_id":      categoryID,
		"judgeIds": judgeID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}
