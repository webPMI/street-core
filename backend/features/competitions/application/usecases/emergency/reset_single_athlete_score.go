package emergency

import (
	"context"
	"errors"
	"fmt"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"
	"backend/features/competitions/domain/services"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// ResetSingleAthleteScoreUseCase handles emergency score resets for a single athlete
// EMERGENCY USE CASE: Used when athlete needs to re-perform due to technical issues
// CRITICAL: Does NOT delete scores - archives them for full history
//
// SCENARIO EXAMPLES:
// - Equipment failure during athlete's run (sound system cuts out)
// - Safety incident requiring immediate stop (debris on course)
// - Judge tablet crash losing scores during submission
type ResetSingleAthleteScoreUseCase struct {
	scoreRepo      repositories.ScoreRepository
	compRepo       repositories.CompetitionRepository
	heatRepo       repositories.HeatRepository
	auditRepo      repositories.EmergencyAuditRepository
	authService    services.EmergencyAuthorizationService
	broadcaster    repositories.NotificationBroadcaster
	mongoClient    *mongo.Client // For transactions
}

// NewResetSingleAthleteScoreUseCase creates a new reset use case
func NewResetSingleAthleteScoreUseCase(
	scoreRepo repositories.ScoreRepository,
	compRepo repositories.CompetitionRepository,
	heatRepo repositories.HeatRepository,
	auditRepo repositories.EmergencyAuditRepository,
	authService services.EmergencyAuthorizationService,
	broadcaster repositories.NotificationBroadcaster,
	mongoClient *mongo.Client,
) *ResetSingleAthleteScoreUseCase {
	return &ResetSingleAthleteScoreUseCase{
		scoreRepo:   scoreRepo,
		compRepo:    compRepo,
		heatRepo:    heatRepo,
		auditRepo:   auditRepo,
		authService: authService,
		broadcaster: broadcaster,
		mongoClient: mongoClient,
	}
}

// ResetRequest contains all parameters for the reset operation
type ResetRequest struct {
	CompetitionID   primitive.ObjectID
	HeatID          primitive.ObjectID
	AthleteID       primitive.ObjectID
	Reason          string // MANDATORY: Minimum 10 characters
	InitiatedBy     primitive.ObjectID
	InitiatedByName string
}

// Execute performs the emergency score reset with full audit trail
//
// TRANSACTIONAL PATTERN (Strict Order):
// 1. Authorization check
// 2. Load all entities (heat, competition, scores)
// 3. CaptureStateBefore for all scores
// 4. Archive existing scores (Status = "archived_by_rerun")
// 5. Create new empty score records
// 6. CaptureStateAfter
// 7. Save everything in MongoDB transaction
// 8. Notify Speaker in real-time
func (uc *ResetSingleAthleteScoreUseCase) Execute(ctx context.Context, req ResetRequest) error {
	// =========================================================================
	// STEP 1: VALIDATION
	// =========================================================================

	// Validate reason (MANDATORY - min 10 characters)
	if len(req.Reason) < 10 {
		return errors.New("emergency action reason must be at least 10 characters")
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

	// Validate athlete is in the heat
	if !heat.HasAthlete(req.AthleteID) {
		return fmt.Errorf("athlete (%s) not in heat", req.AthleteID.Hex())
	}

	// =========================================================================
	// STEP 3: AUTHORIZATION CHECK
	// =========================================================================

	err = uc.authService.CanPerformEmergencyAction(
		competition,
		req.InitiatedBy,
		entities.ActionResetAthleteScore,
	)
	if err != nil {
		return err // Returns SE_NOT_AUTHORIZED or similar
	}

	// =========================================================================
	// STEP 4: LOAD EXISTING SCORES
	// =========================================================================

	// Find all scores for this athlete in this heat
	allHeatScores, err := uc.scoreRepo.FindByHeat(ctx, req.CompetitionID, req.HeatID.Hex())
	if err != nil {
		return fmt.Errorf("failed to load heat scores: %w", err)
	}

	// Filter scores for this athlete
	var athleteScores []*entities.Score
	for _, score := range allHeatScores {
		if score.AthleteID == req.AthleteID {
			athleteScores = append(athleteScores, score)
		}
	}

	// Validate we have scores to reset
	if len(athleteScores) == 0 {
		return errors.New("no scores found for athlete to reset")
	}

	// =========================================================================
	// STEP 5: CREATE EMERGENCY ACTION (for audit trail)
	// =========================================================================

	emergencyAction := entities.NewEmergencyAction(
		req.CompetitionID,
		entities.ActionResetAthleteScore,
		req.Reason,
		req.InitiatedBy,
		req.InitiatedByName,
	)
	emergencyAction.SetHeat(req.HeatID)
	emergencyAction.SetAthlete(req.AthleteID)

	// Store metadata about the reset
	emergencyAction.AddMetadata("athleteId", req.AthleteID.Hex())
	emergencyAction.AddMetadata("scoresArchived", len(athleteScores))

	// =========================================================================
	// STEP 6: CAPTURE STATE BEFORE (for UNDO capability)
	// =========================================================================

	stateBefore := map[string]interface{}{
		"athleteId":     req.AthleteID.Hex(),
		"originalScores": uc.serializeScores(athleteScores),
	}

	if err := emergencyAction.CaptureStateBefore(stateBefore); err != nil {
		return fmt.Errorf("failed to capture state before reset: %w", err)
	}

	// =========================================================================
	// STEP 7: START MONGODB TRANSACTION
	// =========================================================================

	session, err := uc.mongoClient.StartSession()
	if err != nil {
		return fmt.Errorf("failed to start MongoDB session: %w", err)
	}
	defer session.EndSession(ctx)

	// Execute transaction
	err = mongo.WithSession(ctx, session, func(sc mongo.SessionContext) error {
		// Start transaction
		if err := session.StartTransaction(); err != nil {
			return err
		}

		// ===================================================================
		// STEP 8: ARCHIVE EXISTING SCORES (DO NOT DELETE)
		// ===================================================================

		for _, score := range athleteScores {
			// Mark as archived (preserves full history)
			score.Status = entities.ScoreStatusArchivedByRerun
			score.Notes = fmt.Sprintf("Archived for re-run. Reason: %s", req.Reason)
			score.PrepareForUpdate()

			if err := uc.scoreRepo.Update(sc, score); err != nil {
				session.AbortTransaction(sc)
				return fmt.Errorf("failed to archive score: %w", err)
			}
		}

		// ===================================================================
		// STEP 9: CREATE NEW EMPTY SCORE RECORDS
		// ===================================================================

		// Create new empty scores for each judge that had scored this athlete
		judgesSeen := make(map[primitive.ObjectID]bool)
		newScores := []*entities.Score{}

		for _, oldScore := range athleteScores {
			// Avoid duplicate judges
			if judgesSeen[oldScore.JudgeID] {
				continue
			}
			judgesSeen[oldScore.JudgeID] = true

			// Create new empty score
			newScore := entities.NewScore(
				req.CompetitionID,
				req.AthleteID,
				oldScore.JudgeID,
				oldScore.RoundID,
				0, // Empty score for re-run
			)
			newScore.HeatID = req.HeatID.Hex()
			newScore.JudgeName = oldScore.JudgeName
			newScore.AthleteName = oldScore.AthleteName
			newScore.IsLocked = false // Unlock for new scoring
			newScore.Notes = fmt.Sprintf("Re-run after emergency reset. Original score archived.")

			if err := uc.scoreRepo.Save(sc, newScore); err != nil {
				session.AbortTransaction(sc)
				return fmt.Errorf("failed to create new score: %w", err)
			}

			newScores = append(newScores, newScore)
		}

		// ===================================================================
		// STEP 10: CAPTURE STATE AFTER (for audit trail)
		// ===================================================================

		stateAfter := map[string]interface{}{
			"athleteId":      req.AthleteID.Hex(),
			"archivedScores": uc.serializeScores(athleteScores),
			"newScores":      uc.serializeScores(newScores),
		}

		if err := emergencyAction.CaptureStateAfter(stateAfter); err != nil {
			session.AbortTransaction(sc)
			return err
		}

		// ===================================================================
		// STEP 11: MARK ACTION AS APPLIED
		// ===================================================================

		if err := emergencyAction.MarkAsApplied(); err != nil {
			session.AbortTransaction(sc)
			return err
		}

		// ===================================================================
		// STEP 12: SAVE EMERGENCY ACTION TO AUDIT LOG
		// ===================================================================

		if err := uc.auditRepo.Create(sc, emergencyAction); err != nil {
			session.AbortTransaction(sc)
			return fmt.Errorf("failed to save emergency action: %w", err)
		}

		// Commit transaction
		if err := session.CommitTransaction(sc); err != nil {
			return fmt.Errorf("failed to commit transaction: %w", err)
		}

		return nil
	})

	if err != nil {
		return fmt.Errorf("transaction failed: %w", err)
	}

	// =========================================================================
	// STEP 13: SPEAKER SYNC (Real-time notification)
	// =========================================================================

	// Create broadcast for Speaker to see the change immediately
	broadcast := entities.NewEmergencyBroadcast(
		req.CompetitionID,
		entities.BroadcastPriorityCritical,
		"Emergency Score Reset",
		fmt.Sprintf("Scores reset for athlete in heat %s - Re-run required", heat.Name),
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
		notifMsg := fmt.Sprintf("🚨 EMERGENCY RESET: Athlete scores reset in heat %s. Re-run authorized. Reason: %s",
			heat.Name, req.Reason)
		if err := uc.broadcaster.BroadcastToCompetition(ctx, req.CompetitionID, "emergency_reset", notifMsg); err != nil {
			fmt.Printf("ERROR: Failed to broadcast to Speaker: %v\n", err)
		}
	}

	return nil
}

// serializeScores converts scores to a format suitable for JSON storage
func (uc *ResetSingleAthleteScoreUseCase) serializeScores(scores []*entities.Score) []map[string]interface{} {
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
			"status":         score.Status,
		}
	}
	return result
}
