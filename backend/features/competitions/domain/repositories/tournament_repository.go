package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TournamentRepository defines the interface for tournament data access
type TournamentRepository interface {
	// Basic CRUD operations
	Save(ctx context.Context, tournament *entities.Tournament) error
	Update(ctx context.Context, tournament *entities.Tournament) error
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Tournament, error)
	FindAll(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Tournament, int64, error)
	Delete(ctx context.Context, id primitive.ObjectID) error

	// Specific queries
	FindByOrganizerID(ctx context.Context, organizerID primitive.ObjectID, page, limit int) ([]*entities.Tournament, int64, error)
	FindByStatus(ctx context.Context, status string, page, limit int) ([]*entities.Tournament, int64, error)
	FindUpcoming(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Tournament, int64, error)
	FindLive(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Tournament, int64, error)
	FindByYear(ctx context.Context, year int, page, limit int) ([]*entities.Tournament, int64, error)
	FindBySportType(ctx context.Context, sportType string, page, limit int) ([]*entities.Tournament, int64, error)

	// Competition management
	AddCompetition(ctx context.Context, tournamentID, competitionID primitive.ObjectID) error
	RemoveCompetition(ctx context.Context, tournamentID, competitionID primitive.ObjectID) error
	GetCompetitions(ctx context.Context, tournamentID primitive.ObjectID) ([]primitive.ObjectID, error)

	// Registration operations
	RegisterAthlete(ctx context.Context, tournamentID, athleteID primitive.ObjectID) error
	UnregisterAthlete(ctx context.Context, tournamentID, athleteID primitive.ObjectID) error
	IsAthleteRegistered(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (bool, error)
	GetRegisteredAthletes(ctx context.Context, tournamentID primitive.ObjectID) ([]primitive.ObjectID, error)

	// Status operations
	UpdateStatus(ctx context.Context, tournamentID primitive.ObjectID, status string) error
	IncrementCompletedRounds(ctx context.Context, tournamentID primitive.ObjectID) error
	PublishResults(ctx context.Context, tournamentID primitive.ObjectID) error

	// Athlete queries
	FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID, page, limit int) ([]*entities.Tournament, int64, error)
}
