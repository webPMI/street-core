package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CompetitionRepository defines the interface for competition data access
type CompetitionRepository interface {
	// Basic CRUD operations
	Save(ctx context.Context, competition *entities.Competition) error
	Update(ctx context.Context, competition *entities.Competition) error
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Competition, error)
	FindAll(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error)
	Delete(ctx context.Context, id primitive.ObjectID) error

	// Specific queries
	FindByOrganizerID(ctx context.Context, organizerID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error)
	FindByStatus(ctx context.Context, status string, page, limit int) ([]*entities.Competition, int64, error)
	FindUpcoming(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error)
	FindLive(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error)

	// Registration operations
	RegisterAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) error
	UnregisterAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) error
	IsAthleteRegistered(ctx context.Context, competitionID, athleteID primitive.ObjectID) (bool, error)

	// Judge operations
	AddJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) error
	RemoveJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) error
	IsJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) (bool, error)

	// Participant queries
	FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error)
}
