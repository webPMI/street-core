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

// TournamentRepositoryImpl implements the TournamentRepository interface
type TournamentRepositoryImpl struct {
	collection *mongo.Collection
}

// NewTournamentRepository creates a new tournament repository
func NewTournamentRepository(db *mongo.Database) repositories.TournamentRepository {
	return &TournamentRepositoryImpl{
		collection: db.Collection("tournaments"),
	}
}

// Save creates a new tournament
func (r *TournamentRepositoryImpl) Save(ctx context.Context, tournament *entities.Tournament) error {
	_, err := r.collection.InsertOne(ctx, tournament)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return domainerrors.ErrDuplicateEntry
		}
		return domainerrors.ErrDatabaseOperation
	}
	return nil
}

// Update updates an existing tournament
func (r *TournamentRepositoryImpl) Update(ctx context.Context, tournament *entities.Tournament) error {
	tournament.PrepareForUpdate()

	filter := bson.M{"_id": tournament.ID}
	update := bson.M{"$set": tournament}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// FindByID finds a tournament by ID
func (r *TournamentRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Tournament, error) {
	var tournament entities.Tournament
	filter := bson.M{"_id": id}

	err := r.collection.FindOne(ctx, filter).Decode(&tournament)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &tournament, nil
}

// FindAll finds all tournaments with pagination and filters
func (r *TournamentRepositoryImpl) FindAll(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Tournament, int64, error) {
	filter := r.buildFilter(filters)

	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

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

	var tournaments []*entities.Tournament
	if err := cursor.All(ctx, &tournaments); err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	return tournaments, total, nil
}

// Delete deletes a tournament
func (r *TournamentRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
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

// FindByOrganizerID finds tournaments by organizer ID
func (r *TournamentRepositoryImpl) FindByOrganizerID(ctx context.Context, organizerID primitive.ObjectID, page, limit int) ([]*entities.Tournament, int64, error) {
	filter := bson.M{"organizerId": organizerID}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindByStatus finds tournaments by status
func (r *TournamentRepositoryImpl) FindByStatus(ctx context.Context, status string, page, limit int) ([]*entities.Tournament, int64, error) {
	filter := bson.M{"status": status}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindUpcoming finds upcoming tournaments
func (r *TournamentRepositoryImpl) FindUpcoming(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Tournament, int64, error) {
	filter := r.buildFilter(filters)
	filter["status"] = entities.TournamentStatusUpcoming
	filter["schedule.startDate"] = bson.M{"$gte": time.Now()}

	return r.findWithPagination(ctx, filter, page, limit)
}

// FindLive finds live tournaments
func (r *TournamentRepositoryImpl) FindLive(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Tournament, int64, error) {
	filter := r.buildFilter(filters)
	filter["status"] = entities.TournamentStatusLive
	filter["isLive"] = true

	return r.findWithPagination(ctx, filter, page, limit)
}

// FindByYear finds tournaments by year
func (r *TournamentRepositoryImpl) FindByYear(ctx context.Context, year int, page, limit int) ([]*entities.Tournament, int64, error) {
	filter := bson.M{"schedule.year": year}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindBySportType finds tournaments by sport type
func (r *TournamentRepositoryImpl) FindBySportType(ctx context.Context, sportType string, page, limit int) ([]*entities.Tournament, int64, error) {
	filter := bson.M{"sportType": sportType}
	return r.findWithPagination(ctx, filter, page, limit)
}

// AddCompetition adds a competition to the tournament
func (r *TournamentRepositoryImpl) AddCompetition(ctx context.Context, tournamentID, competitionID primitive.ObjectID) error {
	filter := bson.M{"_id": tournamentID}
	update := bson.M{
		"$addToSet": bson.M{"competitionIds": competitionID},
		"$inc":      bson.M{"totalCompetitions": 1},
		"$set":      bson.M{"updatedAt": time.Now()},
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

// RemoveCompetition removes a competition from the tournament
func (r *TournamentRepositoryImpl) RemoveCompetition(ctx context.Context, tournamentID, competitionID primitive.ObjectID) error {
	filter := bson.M{"_id": tournamentID}
	update := bson.M{
		"$pull": bson.M{"competitionIds": competitionID},
		"$inc":  bson.M{"totalCompetitions": -1},
		"$set":  bson.M{"updatedAt": time.Now()},
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

// GetCompetitions gets all competition IDs for a tournament
func (r *TournamentRepositoryImpl) GetCompetitions(ctx context.Context, tournamentID primitive.ObjectID) ([]primitive.ObjectID, error) {
	tournament, err := r.FindByID(ctx, tournamentID)
	if err != nil {
		return nil, err
	}
	return tournament.CompetitionIDs, nil
}

// RegisterAthlete registers an athlete to the tournament
func (r *TournamentRepositoryImpl) RegisterAthlete(ctx context.Context, tournamentID, athleteID primitive.ObjectID) error {
	filter := bson.M{"_id": tournamentID}
	update := bson.M{
		"$addToSet": bson.M{"registeredAthleteIds": athleteID},
		"$inc":      bson.M{"registration.currentParticipants": 1},
		"$set":      bson.M{"updatedAt": time.Now()},
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

// UnregisterAthlete unregisters an athlete from the tournament
func (r *TournamentRepositoryImpl) UnregisterAthlete(ctx context.Context, tournamentID, athleteID primitive.ObjectID) error {
	filter := bson.M{"_id": tournamentID}
	update := bson.M{
		"$pull": bson.M{"registeredAthleteIds": athleteID},
		"$inc":  bson.M{"registration.currentParticipants": -1},
		"$set":  bson.M{"updatedAt": time.Now()},
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
func (r *TournamentRepositoryImpl) IsAthleteRegistered(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (bool, error) {
	filter := bson.M{
		"_id":                  tournamentID,
		"registeredAthleteIds": athleteID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, domainerrors.ErrDatabaseOperation
	}

	return count > 0, nil
}

// GetRegisteredAthletes gets all registered athlete IDs
func (r *TournamentRepositoryImpl) GetRegisteredAthletes(ctx context.Context, tournamentID primitive.ObjectID) ([]primitive.ObjectID, error) {
	tournament, err := r.FindByID(ctx, tournamentID)
	if err != nil {
		return nil, err
	}
	return tournament.RegisteredAthleteIDs, nil
}

// UpdateStatus updates the tournament status
func (r *TournamentRepositoryImpl) UpdateStatus(ctx context.Context, tournamentID primitive.ObjectID, status string) error {
	filter := bson.M{"_id": tournamentID}
	update := bson.M{
		"$set": bson.M{
			"status":    status,
			"isLive":    status == entities.TournamentStatusLive,
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

// IncrementCompletedRounds increments the completed rounds counter
func (r *TournamentRepositoryImpl) IncrementCompletedRounds(ctx context.Context, tournamentID primitive.ObjectID) error {
	filter := bson.M{"_id": tournamentID}
	update := bson.M{
		"$inc": bson.M{"completedRounds": 1},
		"$set": bson.M{"updatedAt": time.Now()},
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

// PublishResults publishes the tournament results
func (r *TournamentRepositoryImpl) PublishResults(ctx context.Context, tournamentID primitive.ObjectID) error {
	now := time.Now()
	filter := bson.M{"_id": tournamentID}
	update := bson.M{
		"$set": bson.M{
			"isResultsPublished": true,
			"resultsPublishedAt": now,
			"updatedAt":          now,
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

// FindByAthleteID finds tournaments where the athlete is registered
func (r *TournamentRepositoryImpl) FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID, page, limit int) ([]*entities.Tournament, int64, error) {
	filter := bson.M{"registeredAthleteIds": athleteID}
	return r.findWithPagination(ctx, filter, page, limit)
}

// Helper methods

func (r *TournamentRepositoryImpl) buildFilter(filters map[string]interface{}) bson.M {
	filter := bson.M{}

	if filters == nil {
		return filter
	}

	// Status filter
	if status, ok := filters["status"].(string); ok && status != "" {
		filter["status"] = status
	}

	// Sport type filter
	if sportType, ok := filters["sportType"].(string); ok && sportType != "" {
		filter["sportType"] = sportType
	}

	// Discipline filter
	if discipline, ok := filters["discipline"].(string); ok && discipline != "" {
		filter["discipline"] = discipline
	}

	// Year filter
	if year, ok := filters["year"].(int); ok && year > 0 {
		filter["schedule.year"] = year
	}

	// Search filter (title or description)
	if search, ok := filters["search"].(string); ok && search != "" {
		filter["$or"] = []bson.M{
			{"title": bson.M{"$regex": search, "$options": "i"}},
			{"description": bson.M{"$regex": search, "$options": "i"}},
		}
	}

	// Public only filter
	if isPublic, ok := filters["isPublic"].(bool); ok {
		filter["isPublic"] = isPublic
	}

	// Featured only filter
	if isFeatured, ok := filters["isFeatured"].(bool); ok {
		filter["isFeatured"] = isFeatured
	}

	return filter
}

func (r *TournamentRepositoryImpl) findWithPagination(ctx context.Context, filter bson.M, page, limit int) ([]*entities.Tournament, int64, error) {
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

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

	var tournaments []*entities.Tournament
	if err := cursor.All(ctx, &tournaments); err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	return tournaments, total, nil
}
