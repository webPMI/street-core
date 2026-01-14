package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Score status constants
const (
	ScoreStatusActive          = "active"
	ScoreStatusArchivedByRerun = "archived_by_rerun"
	ScoreStatusArchivedByReset = "archived_by_reset"
)

// Score represents a judge's score for an athlete in a competition round
type Score struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	RoundID       string             `json:"roundId" bson:"roundId"`
	AthleteID     primitive.ObjectID `json:"athleteId" bson:"athleteId" validate:"required"`
	AthleteName   string             `json:"athleteName" bson:"athleteName"`
	JudgeID       primitive.ObjectID `json:"judgeId" bson:"judgeId" validate:"required"`
	JudgeName     string             `json:"judgeName" bson:"judgeName"`

	// Score values
	TotalScore     float64            `json:"totalScore" bson:"totalScore"`
	CriteriaScores map[string]float64 `json:"criteriaScores,omitempty" bson:"criteriaScores,omitempty"` // Breakdown by criterion

	// Heat association (optional - links score to specific heat)
	HeatID string `json:"heatId,omitempty" bson:"heatId,omitempty"`

	// Tie handling (for racing/simultaneous modes)
	Position    int    `json:"position,omitempty" bson:"position,omitempty"`       // Finish position (1st, 2nd, etc.)
	IsTied      bool   `json:"isTied" bson:"isTied"`                               // Indicates tied position
	TieBreaker  string `json:"tieBreaker,omitempty" bson:"tieBreaker,omitempty"`   // Tie-break method used
	PhotoFinish bool   `json:"photoFinish,omitempty" bson:"photoFinish,omitempty"` // Manual photo finish review

	// SECURITY: Score Lock/Unlock System (Grace Period for Corrections)
	IsLocked           bool                `json:"isLocked" bson:"isLocked"`                                     // Whether score is locked for editing
	UnlockRequestedAt  *time.Time          `json:"unlockRequestedAt,omitempty" bson:"unlockRequestedAt,omitempty"`   // When unlock was requested
	UnlockRequestedBy  *primitive.ObjectID `json:"unlockRequestedBy,omitempty" bson:"unlockRequestedBy,omitempty"`   // Judge who requested unlock
	UnlockAuthorizedBy *primitive.ObjectID `json:"unlockAuthorizedBy,omitempty" bson:"unlockAuthorizedBy,omitempty"` // Organizer who authorized
	UnlockAuthorizedAt *time.Time          `json:"unlockAuthorizedAt,omitempty" bson:"unlockAuthorizedAt,omitempty"` // When unlock was authorized
	UnlockExpiresAt    *time.Time          `json:"unlockExpiresAt,omitempty" bson:"unlockExpiresAt,omitempty"`       // When unlock window expires

	// EMERGENCY: Score Under Review System (Protest Management)
	IsUnderReview      bool       `json:"isUnderReview" bson:"isUnderReview"`                               // Whether score is under review (hidden from public)
	ReviewReason       string     `json:"reviewReason,omitempty" bson:"reviewReason,omitempty"`             // Reason for review
	ReviewRequestedAt  *time.Time `json:"reviewRequestedAt,omitempty" bson:"reviewRequestedAt,omitempty"`   // When review was requested
	ReviewResolvedAt   *time.Time `json:"reviewResolvedAt,omitempty" bson:"reviewResolvedAt,omitempty"`     // When review was resolved
	ReviewApproved     *bool      `json:"reviewApproved,omitempty" bson:"reviewApproved,omitempty"`         // Whether original score was approved

	// EMERGENCY: Admin Override System (Critical for Protests)
	IsOverridden           bool                `json:"isOverridden" bson:"isOverridden"`                                             // Whether score was admin-overridden
	OriginalJudgeScore     float64             `json:"originalJudgeScore,omitempty" bson:"originalJudgeScore,omitempty"`             // Original score before override
	OriginalCriteriaScores map[string]float64  `json:"originalCriteriaScores,omitempty" bson:"originalCriteriaScores,omitempty"`     // Original criteria before override
	OverriddenBy           *primitive.ObjectID `json:"overriddenBy,omitempty" bson:"overriddenBy,omitempty"`                         // Admin who overrode
	OverriddenAt           *time.Time          `json:"overriddenAt,omitempty" bson:"overriddenAt,omitempty"`                         // When override occurred
	OverrideReason         string              `json:"overrideReason,omitempty" bson:"overrideReason,omitempty"`                     // Reason for override

	// EMERGENCY: Score Status for Re-run Scenarios
	Status string `json:"status" bson:"status"` // "active", "archived_by_rerun", "archived_by_reset"

	// Metadata
	Notes       string    `json:"notes,omitempty" bson:"notes,omitempty"`
	SubmittedAt time.Time `json:"submittedAt" bson:"submittedAt"`
	CreatedAt   time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewScore creates a new Score entity
func NewScore(competitionID, athleteID, judgeID primitive.ObjectID, roundID string, score float64) *Score {
	now := time.Now()
	return &Score{
		ID:                     primitive.NewObjectID(),
		CompetitionID:          competitionID,
		RoundID:                roundID,
		AthleteID:              athleteID,
		JudgeID:                judgeID,
		TotalScore:             score,
		CriteriaScores:         make(map[string]float64),
		OriginalCriteriaScores: make(map[string]float64),
		IsLocked:               true,                  // SECURITY: Scores start locked after submission
		Status:                 ScoreStatusActive,     // EMERGENCY: Scores start as active
		IsOverridden:           false,                 // EMERGENCY: Not overridden by default
		SubmittedAt:            now,
		CreatedAt:              now,
		UpdatedAt:              now,
	}
}

// AddCriteriaScore adds or updates a criteria-specific score
func (s *Score) AddCriteriaScore(criterionName string, score float64) {
	if s.CriteriaScores == nil {
		s.CriteriaScores = make(map[string]float64)
	}
	s.CriteriaScores[criterionName] = score
	s.UpdatedAt = time.Now()
}

// CalculateTotalFromCriteria calculates total score from criteria scores
func (s *Score) CalculateTotalFromCriteria() float64 {
	total := 0.0
	for _, score := range s.CriteriaScores {
		total += score
	}
	s.TotalScore = total
	return total
}

// PrepareForUpdate updates the timestamp
func (s *Score) PrepareForUpdate() {
	s.UpdatedAt = time.Now()
}

// Validate ensures the score entity is valid
func (s *Score) Validate() error {
	if s.CompetitionID.IsZero() {
		return ErrInvalidScore("competition ID is required")
	}
	if s.AthleteID.IsZero() {
		return ErrInvalidScore("athlete ID is required")
	}
	if s.JudgeID.IsZero() {
		return ErrInvalidScore("judge ID is required")
	}
	if s.TotalScore < 0 {
		return ErrInvalidScore("total score cannot be negative")
	}
	return nil
}

// ErrInvalidScore creates an invalid score error
func ErrInvalidScore(msg string) error {
	return &ValidationError{Message: msg}
}

// ValidationError represents a validation error
type ValidationError struct {
	Message string
}

func (e *ValidationError) Error() string {
	return e.Message
}

// =============================================================================
// SECURITY: SCORE LOCK/UNLOCK SYSTEM (Grace Period for Corrections)
// =============================================================================

// RequestUnlock allows a judge to request permission to unlock a score for correction
func (s *Score) RequestUnlock(judgeID primitive.ObjectID) error {
	// Validate the requesting judge is the one who submitted the score
	if s.JudgeID != judgeID {
		return ErrInvalidScore("only the original judge can request unlock")
	}

	// Check if score is already unlocked
	if !s.IsLocked {
		return ErrInvalidScore("score is already unlocked")
	}

	// Check if there's already a pending unlock request
	if s.UnlockRequestedAt != nil && s.UnlockAuthorizedAt == nil {
		return ErrInvalidScore("unlock request already pending")
	}

	// Check if score is within active unlock window
	if s.IsWithinGracePeriod() {
		return ErrInvalidScore("score is already within active grace period")
	}

	now := time.Now()
	s.UnlockRequestedAt = &now
	s.UnlockRequestedBy = &judgeID
	// Clear previous authorization if any
	s.UnlockAuthorizedBy = nil
	s.UnlockAuthorizedAt = nil
	s.UnlockExpiresAt = nil
	s.UpdatedAt = now

	return nil
}

// AuthorizeUnlock allows an organizer to authorize a score unlock with grace period
func (s *Score) AuthorizeUnlock(organizerID primitive.ObjectID, gracePeriodMinutes int) error {
	// Validate there's a pending unlock request
	if s.UnlockRequestedAt == nil {
		return ErrInvalidScore("no unlock request to authorize")
	}

	// Validate grace period
	if gracePeriodMinutes <= 0 {
		return ErrInvalidScore("grace period must be positive")
	}

	now := time.Now()
	expiresAt := now.Add(time.Duration(gracePeriodMinutes) * time.Minute)

	s.IsLocked = false
	s.UnlockAuthorizedBy = &organizerID
	s.UnlockAuthorizedAt = &now
	s.UnlockExpiresAt = &expiresAt
	s.UpdatedAt = now

	return nil
}

// Lock locks the score, preventing further edits
func (s *Score) Lock() error {
	if s.IsLocked {
		return ErrInvalidScore("score is already locked")
	}

	now := time.Now()
	s.IsLocked = true
	// Clear unlock metadata
	s.UnlockRequestedAt = nil
	s.UnlockRequestedBy = nil
	s.UnlockAuthorizedBy = nil
	s.UnlockAuthorizedAt = nil
	s.UnlockExpiresAt = nil
	s.UpdatedAt = now

	return nil
}

// CanEdit checks if the score can currently be edited
func (s *Score) CanEdit() bool {
	// Score must be unlocked
	if s.IsLocked {
		return false
	}

	// Must be within grace period
	if !s.IsWithinGracePeriod() {
		return false
	}

	return true
}

// IsWithinGracePeriod checks if the current time is within the unlock grace period
func (s *Score) IsWithinGracePeriod() bool {
	// No grace period set
	if s.UnlockExpiresAt == nil {
		return false
	}

	// Check if current time is before expiration
	return time.Now().Before(*s.UnlockExpiresAt)
}

// ClearUnlockRequest clears the unlock request (used when request is denied)
func (s *Score) ClearUnlockRequest() {
	s.UnlockRequestedAt = nil
	s.UnlockRequestedBy = nil
	s.UpdatedAt = time.Now()
}

// AutoLockIfExpired automatically locks the score if grace period has expired
func (s *Score) AutoLockIfExpired() bool {
	// Only process if score is currently unlocked
	if s.IsLocked {
		return false
	}

	// Check if grace period has expired
	if !s.IsWithinGracePeriod() {
		s.IsLocked = true
		s.UpdatedAt = time.Now()
		return true
	}

	return false
}

// =============================================================================
// EMERGENCY: ADMIN OVERRIDE SYSTEM (Crisis Score Management)
// =============================================================================
// Admin override allows organizers and head judges to modify scores during emergencies
// USE CASES:
// - Judge tablet failure requiring manual score entry
// - Athlete swap requiring score correction
// - Critical scoring error that needs immediate correction
// - Technical malfunction requiring score override

// AdminOverrideScore allows an admin to override a score during emergencies
// SECURITY: This bypasses ALL lock/unlock validation - reason is MANDATORY (min 10 chars)
// AUDIT: Original score, override reason, and admin identity are preserved
// CRITICAL: Preserves original judge score for protest handling
func (s *Score) AdminOverrideScore(
	adminID primitive.ObjectID,
	adminName string,
	newTotalScore float64,
	newCriteriaScores map[string]float64,
	reason string,
) error {
	// SECURITY: Validate reason (minimum 10 characters as per emergency requirements)
	if len(reason) < 10 {
		return ErrInvalidScore("admin override reason must be at least 10 characters")
	}

	// Validate new score
	if newTotalScore < 0 {
		return ErrInvalidScore("override score cannot be negative")
	}

	// CRITICAL: Preserve original judge score BEFORE override (for protests)
	if !s.IsOverridden {
		// First time override - save original values
		s.OriginalJudgeScore = s.TotalScore
		if s.CriteriaScores != nil {
			s.OriginalCriteriaScores = make(map[string]float64)
			for k, v := range s.CriteriaScores {
				s.OriginalCriteriaScores[k] = v
			}
		}
	}

	// EMERGENCY BYPASS: Override score regardless of lock status
	now := time.Now()

	// Update score values
	s.TotalScore = newTotalScore
	if newCriteriaScores != nil {
		s.CriteriaScores = newCriteriaScores
	}

	// Mark as overridden
	s.IsOverridden = true
	s.OverriddenBy = &adminID
	s.OverriddenAt = &now
	s.OverrideReason = reason

	// Force unlock for immediate edit
	s.IsLocked = false

	// Clear any pending unlock requests
	s.UnlockRequestedAt = nil
	s.UnlockRequestedBy = nil
	s.UnlockAuthorizedBy = nil
	s.UnlockAuthorizedAt = nil
	s.UnlockExpiresAt = nil

	s.UpdatedAt = now

	// Note: The EmergencyAction entity will capture:
	// - StateBefore: Original score values (including OriginalJudgeScore)
	// - StateAfter: New score values with IsOverridden=true
	// - Reason: Admin override reason
	// - InitiatedBy: Admin who performed override

	return nil
}

// EmergencyResetScore resets the score to zero for emergency re-run scenarios
// USE CASES:
// - Athlete needs to re-perform due to equipment failure
// - Technical issue during performance (e.g., sound system failure)
// - Safety incident requiring re-run
//
// SECURITY: This bypasses ALL lock/unlock validation - reason is MANDATORY
// AUDIT: State before/after is captured in EmergencyAction entity
func (s *Score) EmergencyResetScore(adminID primitive.ObjectID, reason string) error {
	// SECURITY: Validate reason (minimum 10 characters)
	if len(reason) < 10 {
		return ErrInvalidScore("emergency reset reason must be at least 10 characters")
	}

	// EMERGENCY BYPASS: Reset score regardless of lock status

	// Reset all score values
	s.TotalScore = 0
	s.CriteriaScores = make(map[string]float64)

	// Force unlock to allow new scoring
	s.IsLocked = false

	// Clear any pending unlock requests
	s.UnlockRequestedAt = nil
	s.UnlockRequestedBy = nil
	s.UnlockAuthorizedBy = nil
	s.UnlockAuthorizedAt = nil
	s.UnlockExpiresAt = nil

	s.UpdatedAt = time.Now()

	// Note: The EmergencyAction entity will capture:
	// - StateBefore: Original score values
	// - StateAfter: Reset score (0)
	// - Reason: Reset reason
	// - InitiatedBy: Admin who performed reset

	return nil
}

// MarkUnderReview marks a score as under review (hidden from public view)
// Used during protests or when a score is being investigated
func (s *Score) MarkUnderReview(reason string) error {
	if len(reason) < 5 {
		return ErrInvalidScore("review reason must be at least 5 characters")
	}

	if s.IsUnderReview {
		return ErrInvalidScore("score is already under review")
	}

	now := time.Now()
	s.IsUnderReview = true
	s.ReviewReason = reason
	s.ReviewRequestedAt = &now
	s.UpdatedAt = now

	return nil
}

// ResolveReview resolves the review and restores public visibility
func (s *Score) ResolveReview(approved bool) error {
	if !s.IsUnderReview {
		return ErrInvalidScore("score is not under review")
	}

	now := time.Now()
	s.IsUnderReview = false
	s.ReviewResolvedAt = &now
	s.ReviewApproved = &approved
	s.UpdatedAt = now

	return nil
}
