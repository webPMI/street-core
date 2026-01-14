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

// TournamentRegistrationRepositoryImpl implements the TournamentRegistrationRepository interface
type TournamentRegistrationRepositoryImpl struct {
	collection *mongo.Collection
}

// NewTournamentRegistrationRepository creates a new tournament registration repository
func NewTournamentRegistrationRepository(db *mongo.Database) repositories.TournamentRegistrationRepository {
	return &TournamentRegistrationRepositoryImpl{
		collection: db.Collection("tournament_registrations"),
	}
}

// Save creates a new registration
func (r *TournamentRegistrationRepositoryImpl) Save(ctx context.Context, registration *entities.TournamentRegistration) error {
	_, err := r.collection.InsertOne(ctx, registration)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return domainerrors.ErrDuplicateEntry
		}
		return domainerrors.ErrDatabaseOperation
	}
	return nil
}

// Update updates an existing registration
func (r *TournamentRegistrationRepositoryImpl) Update(ctx context.Context, registration *entities.TournamentRegistration) error {
	registration.PrepareForUpdate()

	filter := bson.M{"_id": registration.ID}
	update := bson.M{"$set": registration}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	if result.MatchedCount == 0 {
		return domainerrors.ErrCompetitionNotFound
	}

	return nil
}

// FindByID finds a registration by ID
func (r *TournamentRegistrationRepositoryImpl) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.TournamentRegistration, error) {
	var registration entities.TournamentRegistration
	filter := bson.M{"_id": id}

	err := r.collection.FindOne(ctx, filter).Decode(&registration)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &registration, nil
}

// Delete deletes a registration
func (r *TournamentRegistrationRepositoryImpl) Delete(ctx context.Context, id primitive.ObjectID) error {
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

// FindByTournamentID finds all registrations for a tournament
func (r *TournamentRegistrationRepositoryImpl) FindByTournamentID(ctx context.Context, tournamentID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error) {
	filter := bson.M{"tournamentId": tournamentID}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindByAthleteID finds all registrations for an athlete
func (r *TournamentRegistrationRepositoryImpl) FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error) {
	filter := bson.M{"athleteId": athleteID}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindByTournamentAndAthleteID finds a specific registration
func (r *TournamentRegistrationRepositoryImpl) FindByTournamentAndAthleteID(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (*entities.TournamentRegistration, error) {
	var registration entities.TournamentRegistration
	filter := bson.M{
		"tournamentId": tournamentID,
		"athleteId":    athleteID,
	}

	err := r.collection.FindOne(ctx, filter).Decode(&registration)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, domainerrors.ErrCompetitionNotFound
		}
		return nil, domainerrors.ErrDatabaseOperation
	}

	return &registration, nil
}

// FindByStatus finds registrations by status
func (r *TournamentRegistrationRepositoryImpl) FindByStatus(ctx context.Context, tournamentID primitive.ObjectID, status string, page, limit int) ([]*entities.TournamentRegistration, int64, error) {
	filter := bson.M{
		"tournamentId": tournamentID,
		"status":       status,
	}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindPendingApprovals finds pending approval registrations
func (r *TournamentRegistrationRepositoryImpl) FindPendingApprovals(ctx context.Context, tournamentID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error) {
	filter := bson.M{
		"tournamentId":        tournamentID,
		"status":              entities.RegistrationStatusPending,
		"approval.isRequired": true,
	}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindActiveRegistrations finds active registrations
func (r *TournamentRegistrationRepositoryImpl) FindActiveRegistrations(ctx context.Context, tournamentID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error) {
	filter := bson.M{
		"tournamentId": tournamentID,
		"status":       entities.RegistrationStatusApproved,
	}
	return r.findWithPagination(ctx, filter, page, limit)
}

// FindFullRegistrations finds full tournament registrations
func (r *TournamentRegistrationRepositoryImpl) FindFullRegistrations(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentRegistration, error) {
	filter := bson.M{
		"tournamentId":     tournamentID,
		"registrationType": entities.RegistrationTypeFull,
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var registrations []*entities.TournamentRegistration
	if err := cursor.All(ctx, &registrations); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return registrations, nil
}

// FindIndividualRegistrations finds individual registrations
func (r *TournamentRegistrationRepositoryImpl) FindIndividualRegistrations(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentRegistration, error) {
	filter := bson.M{
		"tournamentId":     tournamentID,
		"registrationType": entities.RegistrationTypeIndividual,
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var registrations []*entities.TournamentRegistration
	if err := cursor.All(ctx, &registrations); err != nil {
		return nil, domainerrors.ErrDatabaseOperation
	}

	return registrations, nil
}

// Approve approves a registration
func (r *TournamentRegistrationRepositoryImpl) Approve(ctx context.Context, registrationID, approvedBy primitive.ObjectID, approvedByName string) error {
	now := time.Now()
	filter := bson.M{"_id": registrationID}
	update := bson.M{
		"$set": bson.M{
			"status":                 entities.RegistrationStatusApproved,
			"approval.status":        entities.RegistrationStatusApproved,
			"approval.approvedBy":    approvedBy,
			"approval.approvedByName": approvedByName,
			"approval.approvedAt":    now,
			"updatedAt":              now,
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

// Reject rejects a registration
func (r *TournamentRegistrationRepositoryImpl) Reject(ctx context.Context, registrationID, rejectedBy primitive.ObjectID, rejectedByName, reason string) error {
	now := time.Now()
	filter := bson.M{"_id": registrationID}
	update := bson.M{
		"$set": bson.M{
			"status":                   entities.RegistrationStatusRejected,
			"approval.status":          entities.RegistrationStatusRejected,
			"approval.rejectedBy":      rejectedBy,
			"approval.rejectedByName":   rejectedByName,
			"approval.rejectionReason": reason,
			"approval.rejectedAt":      now,
			"updatedAt":                now,
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

// ApproveMany approves multiple registrations
func (r *TournamentRegistrationRepositoryImpl) ApproveMany(ctx context.Context, registrationIDs []primitive.ObjectID, approvedBy primitive.ObjectID, approvedByName string) error {
	now := time.Now()
	filter := bson.M{"_id": bson.M{"$in": registrationIDs}}
	update := bson.M{
		"$set": bson.M{
			"status":                 entities.RegistrationStatusApproved,
			"approval.status":        entities.RegistrationStatusApproved,
			"approval.approvedBy":    approvedBy,
			"approval.approvedByName": approvedByName,
			"approval.approvedAt":    now,
			"updatedAt":              now,
		},
	}

	_, err := r.collection.UpdateMany(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

// RejectMany rejects multiple registrations
func (r *TournamentRegistrationRepositoryImpl) RejectMany(ctx context.Context, registrationIDs []primitive.ObjectID, rejectedBy primitive.ObjectID, rejectedByName, reason string) error {
	now := time.Now()
	filter := bson.M{"_id": bson.M{"$in": registrationIDs}}
	update := bson.M{
		"$set": bson.M{
			"status":                   entities.RegistrationStatusRejected,
			"approval.status":          entities.RegistrationStatusRejected,
			"approval.rejectedBy":      rejectedBy,
			"approval.rejectedByName":   rejectedByName,
			"approval.rejectionReason": reason,
			"approval.rejectedAt":      now,
			"updatedAt":                now,
		},
	}

	_, err := r.collection.UpdateMany(ctx, filter, update)
	if err != nil {
		return domainerrors.ErrDatabaseOperation
	}

	return nil
}

// UpdatePaymentStatus updates payment status
func (r *TournamentRegistrationRepositoryImpl) UpdatePaymentStatus(ctx context.Context, registrationID primitive.ObjectID, status string) error {
	filter := bson.M{"_id": registrationID}
	update := bson.M{
		"$set": bson.M{
			"payment.status": status,
			"updatedAt":      time.Now(),
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

// MarkPaymentCompleted marks payment as completed
func (r *TournamentRegistrationRepositoryImpl) MarkPaymentCompleted(ctx context.Context, registrationID primitive.ObjectID, transactionID, paymentMethod string) error {
	now := time.Now()
	filter := bson.M{"_id": registrationID}
	update := bson.M{
		"$set": bson.M{
			"payment.status":        entities.PaymentStatusCompleted,
			"payment.transactionId": transactionID,
			"payment.paymentMethod": paymentMethod,
			"payment.paymentDate":   now,
			"updatedAt":             now,
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

// Exists checks if a registration exists
func (r *TournamentRegistrationRepositoryImpl) Exists(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (bool, error) {
	filter := bson.M{
		"tournamentId": tournamentID,
		"athleteId":    athleteID,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, domainerrors.ErrDatabaseOperation
	}

	return count > 0, nil
}

// IsActive checks if registration is active
func (r *TournamentRegistrationRepositoryImpl) IsActive(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (bool, error) {
	filter := bson.M{
		"tournamentId": tournamentID,
		"athleteId":    athleteID,
		"status":       entities.RegistrationStatusApproved,
	}

	count, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return false, domainerrors.ErrDatabaseOperation
	}

	return count > 0, nil
}

// CountByStatus counts registrations by status
func (r *TournamentRegistrationRepositoryImpl) CountByStatus(ctx context.Context, tournamentID primitive.ObjectID, status string) (int64, error) {
	filter := bson.M{
		"tournamentId": tournamentID,
		"status":       status,
	}

	return r.collection.CountDocuments(ctx, filter)
}

// CountByTournamentID counts total registrations
func (r *TournamentRegistrationRepositoryImpl) CountByTournamentID(ctx context.Context, tournamentID primitive.ObjectID) (int64, error) {
	filter := bson.M{"tournamentId": tournamentID}
	return r.collection.CountDocuments(ctx, filter)
}

// Helper method

func (r *TournamentRegistrationRepositoryImpl) findWithPagination(ctx context.Context, filter bson.M, page, limit int) ([]*entities.TournamentRegistration, int64, error) {
	total, err := r.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	skip := (page - 1) * limit
	findOptions := options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(limit)).
		SetSort(bson.M{"registrationDate": -1})

	cursor, err := r.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}
	defer cursor.Close(ctx)

	var registrations []*entities.TournamentRegistration
	if err := cursor.All(ctx, &registrations); err != nil {
		return nil, 0, domainerrors.ErrDatabaseOperation
	}

	return registrations, total, nil
}
