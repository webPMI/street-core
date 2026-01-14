package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TournamentRegistrationRepository defines the interface for tournament registration data access
type TournamentRegistrationRepository interface {
	// Basic CRUD operations
	Save(ctx context.Context, registration *entities.TournamentRegistration) error
	Update(ctx context.Context, registration *entities.TournamentRegistration) error
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.TournamentRegistration, error)
	Delete(ctx context.Context, id primitive.ObjectID) error

	// Query operations
	FindByTournamentID(ctx context.Context, tournamentID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error)
	FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error)
	FindByTournamentAndAthleteID(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (*entities.TournamentRegistration, error)

	// Status queries
	FindByStatus(ctx context.Context, tournamentID primitive.ObjectID, status string, page, limit int) ([]*entities.TournamentRegistration, int64, error)
	FindPendingApprovals(ctx context.Context, tournamentID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error)
	FindActiveRegistrations(ctx context.Context, tournamentID primitive.ObjectID, page, limit int) ([]*entities.TournamentRegistration, int64, error)

	// Registration type queries
	FindFullRegistrations(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentRegistration, error)
	FindIndividualRegistrations(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentRegistration, error)

	// Approval operations
	Approve(ctx context.Context, registrationID, approvedBy primitive.ObjectID, approvedByName string) error
	Reject(ctx context.Context, registrationID, rejectedBy primitive.ObjectID, rejectedByName, reason string) error
	ApproveMany(ctx context.Context, registrationIDs []primitive.ObjectID, approvedBy primitive.ObjectID, approvedByName string) error
	RejectMany(ctx context.Context, registrationIDs []primitive.ObjectID, rejectedBy primitive.ObjectID, rejectedByName, reason string) error

	// Payment operations
	UpdatePaymentStatus(ctx context.Context, registrationID primitive.ObjectID, status string) error
	MarkPaymentCompleted(ctx context.Context, registrationID primitive.ObjectID, transactionID, paymentMethod string) error

	// Check operations
	Exists(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (bool, error)
	IsActive(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (bool, error)

	// Statistics
	CountByStatus(ctx context.Context, tournamentID primitive.ObjectID, status string) (int64, error)
	CountByTournamentID(ctx context.Context, tournamentID primitive.ObjectID) (int64, error)
}
