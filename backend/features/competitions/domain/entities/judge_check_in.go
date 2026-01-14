package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// JudgeCheckIn status constants
const (
	CheckInStatusPending   = "pending"
	CheckInStatusCheckedIn = "checked_in"
	CheckInStatusNoShow    = "no_show"
)

// JudgeCheckIn represents a judge check-in for a competition
type JudgeCheckIn struct {
	ID             primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID  primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	JudgeID        primitive.ObjectID `json:"judgeId" bson:"judgeId" validate:"required"`
	JudgeName      string             `json:"judgeName" bson:"judgeName"`
	Status         string             `json:"status" bson:"status" validate:"required,oneof=pending checked_in no_show"`
	CheckInAt      *time.Time         `json:"checkInAt,omitempty" bson:"checkInAt,omitempty"`
	WindowStartsAt time.Time          `json:"windowStartsAt" bson:"windowStartsAt"`
	Notes          string             `json:"notes,omitempty" bson:"notes,omitempty"`
	CreatedAt      time.Time          `json:"createdAt" bson:"createdAt"`
	UpdatedAt      time.Time          `json:"updatedAt" bson:"updatedAt"`
}

// NewJudgeCheckIn creates a new judge check-in
// Check-in window opens 24 hours before competition start
func NewJudgeCheckIn(competitionID, judgeID primitive.ObjectID, judgeName string, competitionStartDate time.Time) *JudgeCheckIn {
	now := time.Now()
	// Window opens 24 hours before competition start
	windowStartsAt := competitionStartDate.Add(-24 * time.Hour)

	return &JudgeCheckIn{
		ID:             primitive.NewObjectID(),
		CompetitionID:  competitionID,
		JudgeID:        judgeID,
		JudgeName:      judgeName,
		Status:         CheckInStatusPending,
		WindowStartsAt: windowStartsAt,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}

// CheckIn marks the judge as checked in
func (jc *JudgeCheckIn) CheckIn(notes string) error {
	if jc.Status == CheckInStatusCheckedIn {
		return ErrAlreadyCheckedIn
	}

	now := time.Now()

	// Check if check-in window is open
	if now.Before(jc.WindowStartsAt) {
		return ErrCheckInWindowNotOpen
	}

	jc.Status = CheckInStatusCheckedIn
	jc.CheckInAt = &now
	jc.Notes = notes
	jc.UpdatedAt = now

	return nil
}

// MarkAsNoShow marks the judge as no-show
func (jc *JudgeCheckIn) MarkAsNoShow() {
	jc.Status = CheckInStatusNoShow
	jc.UpdatedAt = time.Now()
}

// IsCheckedIn returns true if the judge is checked in
func (jc *JudgeCheckIn) IsCheckedIn() bool {
	return jc.Status == CheckInStatusCheckedIn
}

// IsPending returns true if check-in is pending
func (jc *JudgeCheckIn) IsPending() bool {
	return jc.Status == CheckInStatusPending
}

// IsWindowOpen returns true if the check-in window is currently open
func (jc *JudgeCheckIn) IsWindowOpen() bool {
	return time.Now().After(jc.WindowStartsAt) || time.Now().Equal(jc.WindowStartsAt)
}

// Judge check-in specific errors
var (
	ErrAlreadyCheckedIn      = newDomainError("judge already checked in")
	ErrCheckInWindowNotOpen  = newDomainError("check-in window is not open yet")
	ErrCheckInNotFound       = newDomainError("check-in record not found")
)
