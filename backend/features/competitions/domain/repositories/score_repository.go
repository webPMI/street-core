package repositories

import (
	"context"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ScoreRepository defines the interface for score persistence
type ScoreRepository interface {
	// Save creates a new score
	Save(ctx context.Context, score *entities.Score) error

	// Update updates an existing score
	Update(ctx context.Context, score *entities.Score) error

	// FindByID retrieves a score by ID
	FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Score, error)

	// FindByCompetitionID retrieves all scores for a competition
	FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.Score, error)

	// FindByCompetitionAndAthlete retrieves scores for a specific athlete in a competition
	FindByCompetitionAndAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) ([]*entities.Score, error)

	// FindByCompetitionAndRound retrieves all scores for a specific round
	FindByCompetitionAndRound(ctx context.Context, competitionID primitive.ObjectID, roundID string) ([]*entities.Score, error)

	// FindByJudgeAndCompetition retrieves all scores submitted by a judge for a competition
	FindByJudgeAndCompetition(ctx context.Context, judgeID, competitionID primitive.ObjectID) ([]*entities.Score, error)

	// FindExistingScore checks if a score already exists for judge-athlete-round combination
	FindExistingScore(ctx context.Context, competitionID, athleteID, judgeID primitive.ObjectID, roundID string) (*entities.Score, error)

	// FindByHeat retrieves all scores for a specific heat in a competition
	FindByHeat(ctx context.Context, competitionID primitive.ObjectID, heatID string) ([]*entities.Score, error)

	// Delete deletes a score
	Delete(ctx context.Context, id primitive.ObjectID) error
}
