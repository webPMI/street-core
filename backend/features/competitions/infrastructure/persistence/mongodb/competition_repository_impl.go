package mongodb

import (
	"context"
	"time"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CompetitionRepositoryImpl implements the CompetitionRepository interface
type CompetitionRepositoryImpl struct {
	collection *mongo.Collection
}

// NewCompetitionRepository creates a new competition repository
func NewCompetitionRepository(db *mongo.Database) repositories.CompetitionRepository {
	return &CompetitionRepositoryImpl{
		collection: db.Collection("competitions"),
	}
}

// Save creates a new competition
func (r *CompetitionRepositoryImpl) Save(ctx context.Context, competition *entities.Competition) error {
	_, err := r.collection.InsertOne(ctx, competition)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return domainerrors.ErrDuplicateEntry
		}
		return domainerrors.ErrDatabaseOperation
	}
	return nil
}

// Update updates an existing competition
func (r *CompetitionRepositoryImpl) Update(ctx context.Context, competition *entities.Competition) error {
	competition.PrepareForUpdate()

	filter := bson.M{"_id": competition.ID}
	update := bson.M{"$set": competition}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// FindByID finds a competition by ID
func (r *CompetitionRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Competition, error) {
	var competition entities.Competition
	filter := bson.M{"_id": id}

	err := r.collection.FindOne(ctx, filter).Decode(&competition)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &competition, nil
}

// FindAll finds all competitions with pagination and filters
func (r *CompetitionRepositoryImpl) FindAll(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error) {
	// Build filter
	filter := r.buildFilter(filters)

	// Count total documents
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	// Find with pagination
	skip := (page - 1) * limit
	findOptions := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"createdAt": -1})

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var competitions []*entities.Competition
	if err := cursor.All(ctx, &competitions); err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	return competitions, total, nil
}

// Delete deletes a competition by ID
func (r *CompetitionRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
	filter := bson.M{"_id": id}

	result, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.DeletedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// FindByOrganizerID finds competitions by organizer ID
func (r *CompetitionRepositoryImpl) FindByOrganizerID(ctx context.Context, organizerID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error) {
	filters := map[string]interface{}{
		"organizerId": organizerID,
	}
	return r.FindAll(ctx, page, limit, filters)
}

// FindByStatus finds competitions by status
func (r *CompetitionRepositoryImpl) FindByStatus(ctx context.Context, status string, page, limit int) ([]*entities.Competition, int64, error) {
	filters := map[string]interface{}{
		"status": status,
	}
	return r.FindAll(ctx, page, limit, filters)
}

// FindUpcoming finds upcoming competitions
func (r *CompetitionRepositoryImpl) FindUpcoming(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error) {
	// Add status filter
	if filters == nil {
		filters = make(map[string]interface{})
	}
	filters["status"] = entities.StatusUpcoming

	return r.FindAll(ctx, page, limit, filters)
}

// FindLive finds live competitions
func (r *CompetitionRepositoryImpl) FindLive(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error) {
	// Add status filter
	if filters == nil {
		filters = make(map[string]interface{})
	}
	filters["status"] = entities.StatusLive

	return r.FindAll(ctx, page, limit, filters)
}

// RegisterAthlete registers an athlete for a competition
func (r *CompetitionRepositoryImpl) RegisterAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) error {
	filter := bson.M{"_id": competitionID}
	update := bson.M{
		"$addToSet": bson.M{
			"registration.registeredAthleteIds": athleteID,
		},
		"$inc": bson.M{
			"registration.currentParticipants": 1,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// UnregisterAthlete unregisters an athlete from a competition
func (r *CompetitionRepositoryImpl) UnregisterAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) error {
	filter := bson.M{"_id": competitionID}
	update := bson.M{
		"$pull": bson.M{
			"registration.registeredAthleteIds": athleteID,
		},
		"$inc": bson.M{
			"registration.currentParticipants": -1,
		},
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// IsAthleteRegistered checks if an athlete is registered
func (r *CompetitionRepositoryImpl) IsAthleteRegistered(ctx context.Context, competitionID, athleteID primitive.ObjectID) (bool, error) {
	filter := bson.M{
		"_id": competitionID,
		"registration.registeredAthleteIds": athleteID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, domainerrors.ErrDatabaseOperation
	}

	return count > 0, nil
}

// AddJudge adds a judge to a competition
func (r *CompetitionRepositoryImpl) AddJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) error {
	filter := bson.M{"_id": competitionID}
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
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// RemoveJudge removes a judge from a competition
func (r *CompetitionRepositoryImpl) RemoveJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) error {
	filter := bson.M{"_id": competitionID}
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
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// IsJudge checks if a user is a judge for a competition
func (r *CompetitionRepositoryImpl) IsJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) (bool, error) {
	filter := bson.M{
		"_id":      competitionID,
		"judgeIds": judgeID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, domainerrors.ErrDatabaseOperation
	}

	return count > 0, nil
}

// FindByAthleteID finds competitions where an athlete is registered
func (r *CompetitionRepositoryImpl) FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error) {
	filter := bson.M{
		"registration.registeredAthleteIds": athleteID,
	}

	// Count total documents
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	// Find with pagination
	skip := (page - 1) * limit
	findOptions := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"schedule.startDate": -1})

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var competitions []*entities.Competition
	if err := cursor.All(ctx, &competitions); err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	return competitions, total, nil
}

// buildFilter builds a MongoDB filter from the provided filters map
// 🔒 SECURITY: Only whitelisted keys are allowed to prevent NoSQL injection (OWASP A03:2021)
func (r *CompetitionRepositoryImpl) buildFilter(filters map[string]interface{}) bson.M {
	filter := bson.M{}

	if filters == nil {
		return filter
	}

	for key, value := range filters {
		switch key {
		case "search":
			// Search in title and description
			if searchTerm, ok := value.(string); ok && searchTerm != "" {
				filter["$or"] = []bson.M{
					{"title": bson.M{"$regex": searchTerm, "$options": "i"}},
					{"description": bson.M{"$regex": searchTerm, "$options": "i"}},
				}
			}
		case "status":
			filter["status"] = value
		case "discipline":
			filter["discipline"] = value
		case "competitionType":
			filter["competitionType"] = value
		case "clubId", "club_id":
			if oid, ok := value.(primitive.ObjectID); ok {
				filter["clubId"] = oid
			}
		case "organizerId", "organizer_id":
			if oid, ok := value.(primitive.ObjectID); ok {
				filter["organizerId"] = oid
			}
		case "featured":
			// Allow filtering by featured competitions
			if featured, ok := value.(bool); ok {
				filter["featured"] = featured
			}
		case "verified":
			// Allow filtering by verified competitions
			if verified, ok := value.(bool); ok {
				filter["verified"] = verified
			}
		case "minPrize":
			// Allow filtering by minimum prize amount
			if minPrize, ok := value.(float64); ok {
				filter["prize"] = bson.M{"$gte": minPrize}
			}
		default:
			// 🔒 SECURITY FIX: Silently ignore unknown keys (fail-secure) instead of adding them
			// This prevents NoSQL injection attacks via arbitrary filter keys
			continue
		}
	}

	return filter
}
