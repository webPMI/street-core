package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TournamentStandingRepository defines the interface for tournament standings data access
type TournamentStandingRepository interface {
	// Basic CRUD operations
	Save(ctx context.Context, standing *entities.TournamentStanding) error
	Update(ctx context.Context, standing *entities.TournamentStanding) error
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.TournamentStanding, error)
	Delete(ctx context.Context, id primitive.ObjectID) error

	// Tournament queries
	FindByTournamentID(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentStanding, error)
	FindByTournamentIDSorted(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentStanding, error)
	FindByTournamentAndAthleteID(ctx context.Context, tournamentID, athleteID primitive.ObjectID) (*entities.TournamentStanding, error)

	// Athlete queries
	FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID) ([]*entities.TournamentStanding, error)

	// Bulk operations
	SaveMany(ctx context.Context, standings []*entities.TournamentStanding) error
	UpdateMany(ctx context.Context, standings []*entities.TournamentStanding) error

	// Result operations
	AddResult(ctx context.Context, standingID primitive.ObjectID, result entities.CompetitionResult) error
	RecalculateStandings(ctx context.Context, tournamentID primitive.ObjectID, scoringConfig entities.TournamentScoringConfig) error

	// Statistics
	GetTopStandings(ctx context.Context, tournamentID primitive.ObjectID, limit int) ([]*entities.TournamentStanding, error)
	GetQualifiedAthletes(ctx context.Context, tournamentID primitive.ObjectID) ([]*entities.TournamentStanding, error)
}
