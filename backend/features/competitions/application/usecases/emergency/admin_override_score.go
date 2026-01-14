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

// AdminOverrideScoreUseCase handles emergency manual score entry by admins
// EMERGENCY USE CASE: Used when judge tablet fails and score must be entered manually
// CRITICAL: Preserves original judge score for protest handling
//
// SCENARIO EXAMPLES:
// - Judge tablet battery dies during score submission
// - Network failure prevents judge from submitting score
// - Organizer needs to manually enter score from paper backup
type AdminOverrideScoreUseCase struct {
	scoreRepo      repositories.ScoreRepository
	compRepo       repositories.CompetitionRepository
	heatRepo       repositories.HeatRepository
	auditRepo      repositories.EmergencyAuditRepository
	authService    services.EmergencyAuthorizationService
	broadcaster    repositories.NotificationBroadcaster
	mongoClient    *mongo.Client // For transactions
}

// NewAdminOverrideScoreUseCase creates a new admin override use case
func NewAdminOverrideScoreUseCase(
	scoreRepo repositories.ScoreRepository,
	compRepo repositories.CompetitionRepository,
	heatRepo repositories.HeatRepository,
	auditRepo repositories.EmergencyAuditRepository,
	authService services.EmergencyAuthorizationService,
	broadcaster repositories.NotificationBroadcaster,
	mongoClient *mongo.Client,
) *AdminOverrideScoreUseCase {
	return &AdminOverrideScoreUseCase{
		scoreRepo:   scoreRepo,
		compRepo:    compRepo,
		heatRepo:    heatRepo,
		auditRepo:   auditRepo,
		authService: authService,
		broadcaster: broadcaster,
		mongoClient: mongoClient,
	}
}

// OverrideRequest contains all parameters for the override operation
type OverrideRequest struct {
	CompetitionID      primitive.ObjectID
	ScoreID            primitive.ObjectID // Existing score to override
	NewTotalScore      float64
	NewCriteriaScores  map[string]float64
	Reason             string // MANDATORY: Minimum 10 characters
	InitiatedBy        primitive.ObjectID
	InitiatedByName    string
}

// Execute performs the emergency score override with full audit trail
//
// TRANSACTIONAL PATTERN (Strict Order):
// 1. Authorization check
// 2. Load all entities (score, competition, heat)
// 3. CaptureStateBefore (including OriginalJudgeScore)
// 4. Apply the override (preserves original score)
// 5. CaptureStateAfter (with IsOverridden=true)
// 6. Save everything in MongoDB transaction
// 7. Notify Speaker in real-time
func (uc *AdminOverrideScoreUseCase) Execute(ctx context.Context, req OverrideRequest) error {
	// =========================================================================
	// STEP 1: VALIDATION
	// =========================================================================

	// Validate reason (MANDATORY - min 10 characters)
	if len(req.Reason) < 10 {
		return errors.New("emergency action reason must be at least 10 characters")
	}

	// Validate new score
	if req.NewTotalScore < 0 {
		return errors.New("override score cannot be negative")
	}

	// =========================================================================
	// STEP 2: LOAD ENTITIES
	// =========================================================================

	// Load score
	score, err := uc.scoreRepo.FindByID(ctx, req.ScoreID)
	if err != nil {
		return fmt.Errorf("score not found: %w", err)
	}

	// Load competition
	competition, err := uc.compRepo.FindByID(ctx, score.CompetitionID)
	if err != nil {
		return fmt.Errorf("competition not found: %w", err)
	}

	// Load heat (if score is associated with a heat)
	var heat *entities.Heat
	if score.HeatID != "" {
		heatID, err := primitive.ObjectIDFromHex(score.HeatID)
		if err == nil {
			heat, _ = uc.heatRepo.FindByID(ctx, heatID)
		}
	}

	// =========================================================================
	// STEP 3: AUTHORIZATION CHECK
	// =========================================================================

	err = uc.authService.CanPerformEmergencyAction(
		competition,
		req.InitiatedBy,
		entities.ActionAdminOverrideScore,
	)
	if err != nil {
		return err // Returns SE_NOT_AUTHORIZED or similar
	}

	// =========================================================================
	// STEP 4: CREATE EMERGENCY ACTION (for audit trail)
	// =========================================================================

	emergencyAction := entities.NewEmergencyAction(
		score.CompetitionID,
		entities.ActionAdminOverrideScore,
		req.Reason,
		req.InitiatedBy,
		req.InitiatedByName,
	)
	emergencyAction.SetScore(req.ScoreID)
	emergencyAction.SetAthlete(score.AthleteID)

	if heat != nil {
		emergencyAction.SetHeat(heat.ID)
	}

	// Store metadata about the override
	emergencyAction.AddMetadata("scoreId", req.ScoreID.Hex())
	emergencyAction.AddMetadata("athleteId", score.AthleteID.Hex())
	emergencyAction.AddMetadata("judgeId", score.JudgeID.Hex())
	emergencyAction.AddMetadata("oldScore", score.TotalScore)
	emergencyAction.AddMetadata("newScore", req.NewTotalScore)

	// =========================================================================
	// STEP 5: CAPTURE STATE BEFORE (for UNDO capability)
	// =========================================================================

	stateBefore := map[string]interface{}{
		"scoreId":          score.ID.Hex(),
		"athleteId":        score.AthleteID.Hex(),
		"judgeId":          score.JudgeID.Hex(),
		"totalScore":       score.TotalScore,
		"criteriaScores":   score.CriteriaScores,
		"isOverridden":     score.IsOverridden,
		"originalJudgeScore": score.OriginalJudgeScore,
	}

	if err := emergencyAction.CaptureStateBefore(stateBefore); err != nil {
		return fmt.Errorf("failed to capture state before override: %w", err)
	}

	// =========================================================================
	// STEP 6: START MONGODB TRANSACTION
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
		// STEP 7: APPLY THE OVERRIDE (Preserves original score)
		// ===================================================================

		// Use entity method to apply override (automatically preserves original)
		if err := score.AdminOverrideScore(
			req.InitiatedBy,
			req.InitiatedByName,
			req.NewTotalScore,
			req.NewCriteriaScores,
			req.Reason,
		); err != nil {
			session.AbortTransaction(sc)
			return err
		}

		// ===================================================================
		// STEP 8: CAPTURE STATE AFTER (for audit trail)
		// ===================================================================

		stateAfter := map[string]interface{}{
			"scoreId":              score.ID.Hex(),
			"athleteId":            score.AthleteID.Hex(),
			"judgeId":              score.JudgeID.Hex(),
			"totalScore":           score.TotalScore,            // New overridden score
			"criteriaScores":       score.CriteriaScores,        // New overridden criteria
			"isOverridden":         score.IsOverridden,          // true
			"originalJudgeScore":   score.OriginalJudgeScore,    // Preserved original
			"overriddenBy":         score.OverriddenBy.Hex(),
			"overrideReason":       score.OverrideReason,
		}

		if err := emergencyAction.CaptureStateAfter(stateAfter); err != nil {
			session.AbortTransaction(sc)
			return err
		}

		// ===================================================================
		// STEP 9: SAVE SCORE WITH OVERRIDE
		// ===================================================================

		if err := uc.scoreRepo.Update(sc, score); err != nil {
			session.AbortTransaction(sc)
			return fmt.Errorf("failed to update score: %w", err)
		}

		// ===================================================================
		// STEP 10: MARK ACTION AS APPLIED
		// ===================================================================

		if err := emergencyAction.MarkAsApplied(); err != nil {
			session.AbortTransaction(sc)
			return err
		}

		// ===================================================================
		// STEP 11: SAVE EMERGENCY ACTION TO AUDIT LOG
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
	// STEP 12: SPEAKER SYNC (Real-time notification)
	// =========================================================================

	// Create broadcast for Speaker to see the change immediately
	heatName := "unknown heat"
	if heat != nil {
		heatName = heat.Name
	}

	broadcast := entities.NewEmergencyBroadcast(
		score.CompetitionID,
		entities.BroadcastPriorityWarning,
		"Admin Score Override",
		fmt.Sprintf("Score manually overridden for athlete in %s", heatName),
		entities.TargetAllSpeakers,
		req.InitiatedBy,
		req.InitiatedByName,
	)

	if heat != nil {
		broadcast.SetHeat(heat.ID)
	}
	broadcast.SetAction(emergencyAction.ID)

	// Send broadcast (async - don't block on this)
	if err := uc.auditRepo.CreateBroadcast(ctx, broadcast); err != nil {
		fmt.Printf("ERROR: Failed to create broadcast: %v\n", err)
	}

	// Send real-time notification via broadcaster
	if uc.broadcaster != nil {
		notifMsg := fmt.Sprintf("⚠️ ADMIN OVERRIDE: Score manually entered for athlete in %s (Judge tablet failure). Reason: %s",
			heatName, req.Reason)
		if err := uc.broadcaster.BroadcastToCompetition(ctx, score.CompetitionID, "emergency_override", notifMsg); err != nil {
			fmt.Printf("ERROR: Failed to broadcast to Speaker: %v\n", err)
		}
	}

	return nil
}
