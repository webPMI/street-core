package emergency

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"
	"backend/features/competitions/domain/services"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SwapAthleteScoresUseCase handles emergency score swaps between two athletes
// EMERGENCY USE CASE: Used when scores were accidentally assigned to wrong athletes
// CRITICAL: This is the most delicate emergency operation - requires full audit trail
//
// SCENARIO EXAMPLES:
// - Two athletes with similar names, judge confused them during scoring
// - Athlete order was wrong in heat, scores need to be swapped
// - Technical error in tablet showing wrong athlete names
type SwapAthleteScoresUseCase struct {
	scoreRepo      repositories.ScoreRepository
	compRepo       repositories.CompetitionRepository
	heatRepo       repositories.HeatRepository
	auditRepo      repositories.EmergencyAuditRepository
	authService    services.EmergencyAuthorizationService
	broadcaster    repositories.NotificationBroadcaster
}

// NewSwapAthleteScoresUseCase creates a new swap athlete scores use case
func NewSwapAthleteScoresUseCase(
	scoreRepo repositories.ScoreRepository,
	compRepo repositories.CompetitionRepository,
	heatRepo repositories.HeatRepository,
	auditRepo repositories.EmergencyAuditRepository,
	authService services.EmergencyAuthorizationService,
	broadcaster repositories.NotificationBroadcaster,
) *SwapAthleteScoresUseCase {
	return &SwapAthleteScoresUseCase{
		scoreRepo:   scoreRepo,
		compRepo:    compRepo,
		heatRepo:    heatRepo,
		auditRepo:   auditRepo,
		authService: authService,
		broadcaster: broadcaster,
	}
}

// SwapRequest contains all parameters for the swap operation
type SwapRequest struct {
	CompetitionID primitive.ObjectID
	HeatID        primitive.ObjectID
	AthleteID1    primitive.ObjectID
	AthleteID2    primitive.ObjectID
	Reason        string // MANDATORY: Minimum 10 characters
	InitiatedBy   primitive.ObjectID
	InitiatedByName string
}

// Execute performs the emergency score swap with full audit trail
//
// TRANSACTIONAL PATTERN (Strict Order):
// 1. Authorization check
// 2. Load all entities (heat, competition, scores)
// 3. CaptureStateBefore for BOTH scores
// 4. Apply the swap
// 5. CaptureStateAfter for BOTH scores
// 6. Save entities + emergency action (transactional)
// 7. Notify Speaker in real-time
func (uc *SwapAthleteScoresUseCase) Execute(ctx context.Context, req SwapRequest) error {
	// =========================================================================
	// STEP 1: VALIDATION
	// =========================================================================

	// Validate reason (MANDATORY - min 10 characters)
	if len(req.Reason) < 10 {
		return errors.New("emergency action reason must be at least 10 characters")
	}

	// Validate that athletes are different
	if req.AthleteID1 == req.AthleteID2 {
		return errors.New("cannot swap scores for the same athlete")
	}

	// =========================================================================
	// STEP 2: LOAD ENTITIES
	// =========================================================================

	// Load competition
	competition, err := uc.compRepo.FindByID(ctx, req.CompetitionID)
	if err != nil {
		return fmt.Errorf("competition not found: %w", err)
	}

	// Load heat
	heat, err := uc.heatRepo.FindByID(ctx, req.HeatID)
	if err != nil {
		return fmt.Errorf("heat not found: %w", err)
	}

	// Validate both athletes are in the heat
	if !heat.HasAthlete(req.AthleteID1) {
		return fmt.Errorf("athlete 1 (%s) not in heat", req.AthleteID1.Hex())
	}
	if !heat.HasAthlete(req.AthleteID2) {
		return fmt.Errorf("athlete 2 (%s) not in heat", req.AthleteID2.Hex())
	}

	// =========================================================================
	// STEP 3: AUTHORIZATION CHECK
	// =========================================================================

	err = uc.authService.CanPerformEmergencyAction(
		competition,
		req.InitiatedBy,
		entities.ActionSwapAthleteScores,
	)
	if err != nil {
		return err // Returns SE_NOT_AUTHORIZED or similar
	}

	// =========================================================================
	// STEP 4: LOAD SCORES FOR BOTH ATHLETES
	// =========================================================================

	// Find all scores for this heat
	allHeatScores, err := uc.scoreRepo.FindByHeat(ctx, req.CompetitionID, req.HeatID.Hex())
	if err != nil {
		return fmt.Errorf("failed to load heat scores: %w", err)
	}

	// Filter scores for athlete 1
	var athlete1Scores []*entities.Score
	for _, score := range allHeatScores {
		if score.AthleteID == req.AthleteID1 {
			athlete1Scores = append(athlete1Scores, score)
		}
	}

	// Filter scores for athlete 2
	var athlete2Scores []*entities.Score
	for _, score := range allHeatScores {
		if score.AthleteID == req.AthleteID2 {
			athlete2Scores = append(athlete2Scores, score)
		}
	}

	// Validate we have scores to swap
	if len(athlete1Scores) == 0 && len(athlete2Scores) == 0 {
		return errors.New("no scores found for either athlete")
	}

	// =========================================================================
	// STEP 5: CREATE EMERGENCY ACTION (for audit trail)
	// =========================================================================

	emergencyAction := entities.NewEmergencyAction(
		req.CompetitionID,
		entities.ActionSwapAthleteScores,
		req.Reason,
		req.InitiatedBy,
		req.InitiatedByName,
	)
	emergencyAction.SetHeat(req.HeatID)

	// Store metadata about the swap
	emergencyAction.AddMetadata("athleteId1", req.AthleteID1.Hex())
	emergencyAction.AddMetadata("athleteId2", req.AthleteID2.Hex())
	emergencyAction.AddMetadata("scoresSwapped", len(athlete1Scores)+len(athlete2Scores))

	// =========================================================================
	// STEP 6: CAPTURE STATE BEFORE (for UNDO capability)
	// =========================================================================

	stateBefore := map[string]interface{}{
		"athlete1": map[string]interface{}{
			"athleteId": req.AthleteID1.Hex(),
			"scores":    uc.serializeScores(athlete1Scores),
		},
		"athlete2": map[string]interface{}{
			"athleteId": req.AthleteID2.Hex(),
			"scores":    uc.serializeScores(athlete2Scores),
		},
	}

	if err := emergencyAction.CaptureStateBefore(stateBefore); err != nil {
		return fmt.Errorf("failed to capture state before swap: %w", err)
	}

	// =========================================================================
	// STEP 7: APPLY THE SWAP (Core Emergency Operation)
	// =========================================================================

	// Swap athlete IDs in all scores
	for _, score := range athlete1Scores {
		score.AthleteID = req.AthleteID2
		score.PrepareForUpdate()
	}

	for _, score := range athlete2Scores {
		score.AthleteID = req.AthleteID1
		score.PrepareForUpdate()
	}

	// =========================================================================
	// STEP 8: CAPTURE STATE AFTER (for audit trail)
	// =========================================================================

	stateAfter := map[string]interface{}{
		"athlete1": map[string]interface{}{
			"athleteId": req.AthleteID1.Hex(),
			"scores":    uc.serializeScores(athlete2Scores), // Now has athlete 2's scores
		},
		"athlete2": map[string]interface{}{
			"athleteId": req.AthleteID2.Hex(),
			"scores":    uc.serializeScores(athlete1Scores), // Now has athlete 1's scores
		},
	}

	if err := emergencyAction.CaptureStateAfter(stateAfter); err != nil {
		return fmt.Errorf("failed to capture state after swap: %w", err)
	}

	// =========================================================================
	// STEP 9: SAVE EVERYTHING (Transactional - as much as possible)
	// =========================================================================

	// Save all updated scores for athlete 1 (now has athlete 2's ID)
	for _, score := range athlete1Scores {
		if err := uc.scoreRepo.Update(ctx, score); err != nil {
			// CRITICAL: Partial failure - need to rollback or log
			emergencyAction.MarkAsFailed(fmt.Sprintf("Failed to update score: %v", err))
			uc.auditRepo.Create(ctx, emergencyAction)
			return errors.New("failed to save swapped scores - partial state")
		}
	}

	// Save all updated scores for athlete 2 (now has athlete 1's ID)
	for _, score := range athlete2Scores {
		if err := uc.scoreRepo.Update(ctx, score); err != nil {
			// CRITICAL: Partial failure - need to rollback or log
			emergencyAction.MarkAsFailed(fmt.Sprintf("Failed to update score: %v", err))
			uc.auditRepo.Create(ctx, emergencyAction)
			return errors.New("failed to save swapped scores - partial state")
		}
	}

	// Mark action as successfully applied
	if err := emergencyAction.MarkAsApplied(); err != nil {
		return err
	}

	// Save emergency action to audit log
	if err := uc.auditRepo.Create(ctx, emergencyAction); err != nil {
		// Log error but don't fail the operation - scores were already swapped
		// This is eventual consistency - audit log will be synced later
		fmt.Printf("ERROR: Failed to save emergency action to audit log: %v\n", err)
	}

	// =========================================================================
	// STEP 10: SPEAKER SYNC (Real-time notification)
	// =========================================================================

	// Create broadcast for Speaker to see the change immediately
	broadcast := entities.NewEmergencyBroadcast(
		req.CompetitionID,
		entities.BroadcastPriorityCritical,
		"Emergency Score Swap",
		fmt.Sprintf("Scores swapped between athletes in heat %s", heat.Name),
		entities.TargetAllSpeakers,
		req.InitiatedBy,
		req.InitiatedByName,
	)
	broadcast.SetHeat(req.HeatID)
	broadcast.SetAction(emergencyAction.ID)
	broadcast.RequireAcknowledgment()

	// Send broadcast (async - don't block on this)
	if err := uc.auditRepo.CreateBroadcast(ctx, broadcast); err != nil {
		fmt.Printf("ERROR: Failed to create broadcast: %v\n", err)
	}

	// Send real-time notification via broadcaster
	if uc.broadcaster != nil {
		notifMsg := fmt.Sprintf("🚨 EMERGENCY SWAP: Scores swapped for athletes in heat %s. Reason: %s",
			heat.Name, req.Reason)
		if err := uc.broadcaster.BroadcastToCompetition(ctx, req.CompetitionID, "emergency_swap", notifMsg); err != nil {
			fmt.Printf("ERROR: Failed to broadcast to Speaker: %v\n", err)
		}
	}

	return nil
}

// serializeScores converts scores to a format suitable for JSON storage
func (uc *SwapAthleteScoresUseCase) serializeScores(scores []*entities.Score) []map[string]interface{} {
	result := make([]map[string]interface{}, len(scores))
	for i, score := range scores {
		result[i] = map[string]interface{}{
			"scoreId":        score.ID.Hex(),
			"judgeId":        score.JudgeID.Hex(),
			"judgeName":      score.JudgeName,
			"totalScore":     score.TotalScore,
			"athleteId":      score.AthleteID.Hex(),
			"athleteName":    score.AthleteName,
			"criteriaScores": score.CriteriaScores,
		}
	}
	return result
}
