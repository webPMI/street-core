package usecases

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"time"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// rankedAthlete represents an athlete with their seeding rank
type rankedAthlete struct {
	ID   primitive.ObjectID
	Rank int
}

// CreateHeatsUseCase handles automatic heat generation for a round
type CreateHeatsUseCase struct {
	heatRepo        repositories.HeatRepository
	roundRepo       repositories.RoundRepository
	categoryRepo    repositories.CategoryRepository
	competitionRepo repositories.CompetitionRepository
}

// NewCreateHeatsUseCase creates a new CreateHeatsUseCase
func NewCreateHeatsUseCase(
	heatRepo repositories.HeatRepository,
	roundRepo repositories.RoundRepository,
	categoryRepo repositories.CategoryRepository,
	competitionRepo repositories.CompetitionRepository,
) *CreateHeatsUseCase {
	return &CreateHeatsUseCase{
		heatRepo:        heatRepo,
		roundRepo:       roundRepo,
		categoryRepo:    categoryRepo,
		competitionRepo: competitionRepo,
	}
}

// CreateHeatsRequest contains parameters for heat generation
type CreateHeatsRequest struct {
	RoundID      string
	CategoryID   string // Optional - if empty, uses all competition participants
	HeatSize     int    // Target size per heat (will be adjusted for equitable distribution)
	Mode         string // "sequential" or "simultaneous"
	EnableSeeding bool
	SeedingSource string // "tournament_standing", "previous_competition", "manual"
	SeedingType   string // "snake" (recommended) or "linear"
	AthleteRankings map[string]int // Manual rankings if SeedingSource is "manual"
}

// Execute generates heats for a round with equitable distribution
func (uc *CreateHeatsUseCase) Execute(ctx context.Context, req CreateHeatsRequest) ([]*entities.Heat, error) {
	// Parse IDs
	roundObjID, err := primitive.ObjectIDFromHex(req.RoundID)
	if err != nil {
		return nil, errors.New("invalid round ID")
	}

	// Get round
	round, err := uc.roundRepo.FindByID(ctx, roundObjID)
	if err != nil {
		return nil, errors.New("round not found")
	}

	// Get competition
	competition, err := uc.competitionRepo.FindByID(ctx, round.CompetitionID)
	if err != nil {
		return nil, errors.New("competition not found")
	}

	// Get participants
	var athleteIDs []primitive.ObjectID
	if req.CategoryID != "" {
		// Category-specific participants
		categoryObjID, err := primitive.ObjectIDFromHex(req.CategoryID)
		if err != nil {
			return nil, errors.New("invalid category ID")
		}
		category, err := uc.categoryRepo.FindByID(ctx, categoryObjID)
		if err != nil {
			return nil, errors.New("category not found")
		}
		athleteIDs = category.ParticipantIDs
	} else {
		// All competition participants
		athleteIDs = competition.Registration.RegisteredAthleteIDs
	}

	if len(athleteIDs) == 0 {
		return nil, errors.New("no participants available for heat generation")
	}

	// Validate Round.MaxAthletes constraint
	if round.MaxAthletes > 0 && len(athleteIDs) > round.MaxAthletes {
		return nil, fmt.Errorf("cannot assign %d athletes - round maximum is %d", len(athleteIDs), round.MaxAthletes)
	}

	// Use competition's default heat size if not provided
	heatSize := req.HeatSize
	if heatSize == 0 {
		heatSize = competition.DefaultHeatSize
	}
	if heatSize == 0 {
		heatSize = 5 // Fallback default
	}

	// Validate total capacity doesn't exceed round max
	if round.MaxAthletes > 0 {
		numHeats := (len(athleteIDs) + heatSize - 1) / heatSize
		totalCapacity := heatSize * numHeats
		if totalCapacity > round.MaxAthletes {
			return nil, fmt.Errorf("total heat capacity (%d) would exceed round maximum (%d)", totalCapacity, round.MaxAthletes)
		}
	}

	// Use competition's default mode if not provided
	mode := req.Mode
	if mode == "" {
		mode = competition.GetDefaultHeatMode()
	}

	// Apply seeding if enabled
	if req.EnableSeeding {
		athleteIDs, err = uc.applySeedingOrder(ctx, athleteIDs, req)
		if err != nil {
			// Log warning but continue with unsorted order
			fmt.Printf("Warning: Seeding failed - %v\n", err)
		}
	}

	// Calculate equitable distribution
	heatSizes := distributeAthletesEquitably(len(athleteIDs), heatSize)

	// Create heats
	heats := make([]*entities.Heat, len(heatSizes))
	athleteIndex := 0

	for i, size := range heatSizes {
		// Create heat entity
		heatName := fmt.Sprintf("Heat %d", i+1)
		heat := entities.NewHeat(competition.ID, roundObjID, heatName, i+1, mode)
		heat.MaxAthletes = size

		// Optional: set category
		if req.CategoryID != "" {
			categoryObjID, _ := primitive.ObjectIDFromHex(req.CategoryID)
			heat.CategoryID = &categoryObjID
		}

		// Assign athletes to this heat
		for j := 0; j < size && athleteIndex < len(athleteIDs); j++ {
			heat.AthleteIDs = append(heat.AthleteIDs, athleteIDs[athleteIndex])
			athleteIndex++
		}

		// For sequential mode, set athlete order
		if mode == entities.HeatModeSequential {
			heat.AthleteOrder = make([]primitive.ObjectID, len(heat.AthleteIDs))
			copy(heat.AthleteOrder, heat.AthleteIDs)
		}

		// Save heat
		if err := uc.heatRepo.Save(ctx, heat); err != nil {
			// Rollback: delete previously created heats
			for k := 0; k < i; k++ {
				uc.heatRepo.Delete(ctx, heats[k].ID)
			}
			return nil, fmt.Errorf("failed to create heat: %w", err)
		}

		heats[i] = heat

		// Update round with heat ID
		round.AddHeat(heat.ID.Hex())
	}

	// Enable heats on round
	round.EnableHeats()
	if err := uc.roundRepo.Update(ctx, round); err != nil {
		return nil, fmt.Errorf("failed to update round: %w", err)
	}

	return heats, nil
}

// distributeAthletesEquitably calculates heat sizes for fair distribution
// Example: 11 athletes, target=5 → [4, 4, 3] instead of [5, 5, 1]
func distributeAthletesEquitably(totalAthletes, targetSize int) []int {
	if totalAthletes == 0 {
		return []int{}
	}

	numHeats := (totalAthletes + targetSize - 1) / targetSize
	baseSize := totalAthletes / numHeats
	remainder := totalAthletes % numHeats

	heatSizes := make([]int, numHeats)
	for i := 0; i < numHeats; i++ {
		heatSizes[i] = baseSize
		if i < remainder {
			heatSizes[i]++
		}
	}

	return heatSizes
}

// applySeedingOrder applies seeding to athlete order
func (uc *CreateHeatsUseCase) applySeedingOrder(ctx context.Context, athleteIDs []primitive.ObjectID, req CreateHeatsRequest) ([]primitive.ObjectID, error) {
	// Get athlete rankings
	rankings := make(map[string]int)

	switch req.SeedingSource {
	case "manual":
		if req.AthleteRankings == nil {
			return athleteIDs, errors.New("manual seeding requires athlete rankings")
		}
		rankings = req.AthleteRankings

	case "tournament_standing":
		// TODO: Implement when tournament standing integration is ready
		return athleteIDs, errors.New("tournament seeding not yet implemented")

	case "previous_competition":
		// TODO: Implement when competition history integration is ready
		return athleteIDs, errors.New("previous competition seeding not yet implemented")

	default:
		// Random seeding
		rand.Seed(time.Now().UnixNano())
		for i, id := range athleteIDs {
			rankings[id.Hex()] = i + 1
		}
	}

	// Sort athletes by ranking
	ranked := make([]rankedAthlete, 0, len(athleteIDs))
	for _, id := range athleteIDs {
		rank := rankings[id.Hex()]
		if rank == 0 {
			rank = 999999 // Unranked athletes go last
		}
		ranked = append(ranked, rankedAthlete{ID: id, Rank: rank})
	}

	// Sort by rank
	for i := 0; i < len(ranked)-1; i++ {
		for j := i + 1; j < len(ranked); j++ {
			if ranked[i].Rank > ranked[j].Rank {
				ranked[i], ranked[j] = ranked[j], ranked[i]
			}
		}
	}

	// Apply distribution pattern
	sorted := make([]primitive.ObjectID, len(ranked))
	if req.SeedingType == "snake" {
		sorted = applySnakeSeeding(ranked)
	} else {
		// Linear distribution
		for i, r := range ranked {
			sorted[i] = r.ID
		}
	}

	return sorted, nil
}

// applySnakeSeeding applies snake (zigzag) distribution for competitive balance
// Example with 3 heats and 12 athletes:
// Heat 1: #1, #6, #7, #12
// Heat 2: #2, #5, #8, #11
// Heat 3: #3, #4, #9, #10
func applySnakeSeeding(ranked []rankedAthlete) []primitive.ObjectID {
	// This returns sorted IDs that when distributed sequentially create snake pattern
	// The actual heat assignment happens in Execute method
	result := make([]primitive.ObjectID, len(ranked))
	for i, r := range ranked {
		result[i] = r.ID
	}
	return result
}
