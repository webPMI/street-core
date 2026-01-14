package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CompetitionResult represents a single competition result within the tournament
type CompetitionResult struct {
	CompetitionID   primitive.ObjectID `json:"competitionId" bson:"competitionId"`
	CompetitionName string             `json:"competitionName" bson:"competitionName"`
	Date            time.Time          `json:"date" bson:"date"`
	Position        int                `json:"position" bson:"position"`                               // Final position in this competition
	Points          float64            `json:"points" bson:"points"`                                   // Points earned in this competition
	TimeResult      *float64           `json:"timeResult,omitempty" bson:"timeResult,omitempty"`       // Time result (if applicable)
	Score           *float64           `json:"score,omitempty" bson:"score,omitempty"`                 // Raw score (if applicable)
	DidNotFinish    bool               `json:"didNotFinish" bson:"didNotFinish"`                       // DNF flag
	DidNotStart     bool               `json:"didNotStart" bson:"didNotStart"`                         // DNS flag
	Disqualified    bool               `json:"disqualified" bson:"disqualified"`                       // DQ flag
	Notes           string             `json:"notes,omitempty" bson:"notes,omitempty"`                 // Additional notes
	IsDropped       bool               `json:"isDropped" bson:"isDropped"`                             // If this result is dropped (worst result)
}

// TournamentStatistics represents statistics for an athlete in the tournament
type TournamentStatistics struct {
	Wins              int     `json:"wins" bson:"wins"`                           // Number of 1st places
	Podiums           int     `json:"podiums" bson:"podiums"`                     // Number of top 3 finishes
	TopFive           int     `json:"topFive" bson:"topFive"`                     // Number of top 5 finishes
	TopTen            int     `json:"topTen" bson:"topTen"`                       // Number of top 10 finishes
	DNFs              int     `json:"dnfs" bson:"dnfs"`                           // Number of Did Not Finish
	DNSs              int     `json:"dnss" bson:"dnss"`                           // Number of Did Not Start
	Disqualifications int     `json:"disqualifications" bson:"disqualifications"` // Number of disqualifications
	BestPosition      int     `json:"bestPosition" bson:"bestPosition"`           // Best position achieved
	WorstPosition     int     `json:"worstPosition" bson:"worstPosition"`         // Worst position achieved
	AveragePosition   float64 `json:"averagePosition" bson:"averagePosition"`     // Average position
	ConsecutivePodiums int    `json:"consecutivePodiums" bson:"consecutivePodiums"` // Current consecutive podiums streak
	ParticipationRate float64 `json:"participationRate" bson:"participationRate"` // % of competitions attended
}

// TournamentStanding represents the standing of an athlete in a tournament
type TournamentStanding struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	TournamentID primitive.ObjectID `json:"tournamentId" bson:"tournamentId" validate:"required"`
	AthleteID    primitive.ObjectID `json:"athleteId" bson:"athleteId" validate:"required"`
	AthleteName  string             `json:"athleteName" bson:"athleteName"`
	AthleteNumber *int              `json:"athleteNumber,omitempty" bson:"athleteNumber,omitempty"` // Race number

	// Current standing
	Position         int     `json:"position" bson:"position"`                   // Current position in tournament
	PreviousPosition int     `json:"previousPosition" bson:"previousPosition"`   // Position after previous round
	PositionChange   int     `json:"positionChange" bson:"positionChange"`       // Change since last round (+/-)
	TotalPoints      float64 `json:"totalPoints" bson:"totalPoints"`             // Total points accumulated
	CountedPoints    float64 `json:"countedPoints" bson:"countedPoints"`         // Points after dropping worst results
	DroppedPoints    float64 `json:"droppedPoints" bson:"droppedPoints"`         // Points from dropped results

	// Participation
	CompetitionsEntered   int `json:"competitionsEntered" bson:"competitionsEntered"`     // Number of competitions entered
	CompetitionsCompleted int `json:"competitionsCompleted" bson:"competitionsCompleted"` // Number of competitions completed
	CompetitionsRequired  int `json:"competitionsRequired" bson:"competitionsRequired"`   // Minimum required to qualify

	// Results breakdown
	Results []CompetitionResult `json:"results" bson:"results"` // Individual competition results

	// Statistics
	Statistics TournamentStatistics `json:"statistics" bson:"statistics"`

	// Tie-breaker information
	TieBreakerValue float64 `json:"tieBreakerValue" bson:"tieBreakerValue"` // Value used for tie-breaking

	// Status
	IsQualified  bool `json:"isQualified" bson:"isQualified"`   // Meets minimum requirements
	IsEligible   bool `json:"isEligible" bson:"isEligible"`     // Eligible for prizes
	IsDisqualified bool `json:"isDisqualified" bson:"isDisqualified"` // Disqualified from tournament

	// Metadata
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewTournamentStanding creates a new TournamentStanding
func NewTournamentStanding(tournamentID, athleteID primitive.ObjectID, athleteName string) *TournamentStanding {
	now := time.Now()
	return &TournamentStanding{
		ID:                    primitive.NewObjectID(),
		TournamentID:          tournamentID,
		AthleteID:             athleteID,
		AthleteName:           athleteName,
		Position:              0, // Will be calculated
		PreviousPosition:      0,
		PositionChange:        0,
		TotalPoints:           0,
		CountedPoints:         0,
		DroppedPoints:         0,
		CompetitionsEntered:   0,
		CompetitionsCompleted: 0,
		CompetitionsRequired:  0,
		Results:               []CompetitionResult{},
		Statistics: TournamentStatistics{
			BestPosition:  999999, // Initialize with high number
			WorstPosition: 0,
		},
		IsQualified:    false,
		IsEligible:     true,
		IsDisqualified: false,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}

// AddResult adds a competition result to the standing
func (ts *TournamentStanding) AddResult(result CompetitionResult) {
	// Check if result already exists (update instead)
	for i, r := range ts.Results {
		if r.CompetitionID == result.CompetitionID {
			ts.Results[i] = result
			ts.RecalculateStanding()
			ts.UpdatedAt = time.Now()
			return
		}
	}

	// Add new result
	ts.Results = append(ts.Results, result)
	ts.CompetitionsEntered++

	if !result.DidNotFinish && !result.DidNotStart && !result.Disqualified {
		ts.CompetitionsCompleted++
	}

	ts.RecalculateStanding()
	ts.UpdatedAt = time.Now()
}

// RecalculateStanding recalculates points and statistics
func (ts *TournamentStanding) RecalculateStanding() {
	ts.TotalPoints = 0
	ts.Statistics = TournamentStatistics{
		BestPosition:  999999,
		WorstPosition: 0,
	}

	totalPositions := 0
	sumPositions := 0
	consecutivePodiums := 0
	lastWasPodium := true

	for _, result := range ts.Results {
		// Skip non-finishes
		if result.DidNotFinish || result.DidNotStart || result.Disqualified {
			if result.DidNotFinish {
				ts.Statistics.DNFs++
			}
			if result.DidNotStart {
				ts.Statistics.DNSs++
			}
			if result.Disqualified {
				ts.Statistics.Disqualifications++
			}
			continue
		}

		// Add points
		if !result.IsDropped {
			ts.TotalPoints += result.Points
		} else {
			ts.DroppedPoints += result.Points
		}

		// Update statistics
		if result.Position == 1 {
			ts.Statistics.Wins++
		}
		if result.Position <= 3 {
			ts.Statistics.Podiums++
			if lastWasPodium {
				consecutivePodiums++
			}
		} else {
			lastWasPodium = false
			consecutivePodiums = 0
		}
		if result.Position <= 5 {
			ts.Statistics.TopFive++
		}
		if result.Position <= 10 {
			ts.Statistics.TopTen++
		}

		// Best/worst positions
		if result.Position < ts.Statistics.BestPosition {
			ts.Statistics.BestPosition = result.Position
		}
		if result.Position > ts.Statistics.WorstPosition {
			ts.Statistics.WorstPosition = result.Position
		}

		// For average
		totalPositions++
		sumPositions += result.Position
	}

	// Calculate counted points (total - dropped)
	ts.CountedPoints = ts.TotalPoints

	// Calculate average position
	if totalPositions > 0 {
		ts.Statistics.AveragePosition = float64(sumPositions) / float64(totalPositions)
	}

	// Update consecutive podiums
	ts.Statistics.ConsecutivePodiums = consecutivePodiums

	// Calculate participation rate
	if ts.CompetitionsEntered > 0 {
		ts.Statistics.ParticipationRate = float64(ts.CompetitionsCompleted) / float64(ts.CompetitionsEntered) * 100
	}

	// Check if qualified (meets minimum requirements)
	if ts.CompetitionsRequired > 0 {
		ts.IsQualified = ts.CompetitionsCompleted >= ts.CompetitionsRequired
	} else {
		ts.IsQualified = true
	}
}

// UpdatePosition updates the position and calculates change
func (ts *TournamentStanding) UpdatePosition(newPosition int) {
	ts.PositionChange = ts.Position - newPosition // Positive = moved up, Negative = moved down
	ts.PreviousPosition = ts.Position
	ts.Position = newPosition
	ts.UpdatedAt = time.Now()
}

// MarkWorstResults marks the worst N results as dropped
func (ts *TournamentStanding) MarkWorstResults(dropCount int) {
	if dropCount <= 0 || len(ts.Results) <= dropCount {
		return
	}

	// Reset all dropped flags
	for i := range ts.Results {
		ts.Results[i].IsDropped = false
	}

	// Find worst results (highest position numbers, excluding DNF/DNS/DQ)
	validResults := []int{}
	for i, result := range ts.Results {
		if !result.DidNotFinish && !result.DidNotStart && !result.Disqualified {
			validResults = append(validResults, i)
		}
	}

	// Sort by position (worst first)
	for i := 0; i < len(validResults)-1; i++ {
		for j := i + 1; j < len(validResults); j++ {
			if ts.Results[validResults[i]].Position < ts.Results[validResults[j]].Position {
				validResults[i], validResults[j] = validResults[j], validResults[i]
			}
		}
	}

	// Mark worst N as dropped
	for i := 0; i < dropCount && i < len(validResults); i++ {
		ts.Results[validResults[i]].IsDropped = true
	}

	ts.RecalculateStanding()
}

// Disqualify disqualifies the athlete from the tournament
func (ts *TournamentStanding) Disqualify() {
	ts.IsDisqualified = true
	ts.IsQualified = false
	ts.IsEligible = false
	ts.UpdatedAt = time.Now()
}

// Reinstate reinstates a disqualified athlete
func (ts *TournamentStanding) Reinstate() {
	ts.IsDisqualified = false
	ts.IsEligible = true
	ts.RecalculateStanding() // Will recalculate qualification
	ts.UpdatedAt = time.Now()
}

// PrepareForUpdate updates the timestamp
func (ts *TournamentStanding) PrepareForUpdate() {
	ts.UpdatedAt = time.Now()
}

// Validate performs basic validation
func (ts *TournamentStanding) Validate() error {
	if ts.TournamentID.IsZero() {
		return ErrStandingInvalidInput
	}
	if ts.AthleteID.IsZero() {
		return ErrStandingInvalidInput
	}

	return nil
}

// Domain errors for TournamentStanding
var (
	ErrStandingInvalidInput = newStandingDomainError("invalid standing input data")
	ErrStandingNotFound     = newStandingDomainError("standing not found")
)

type standingDomainError struct {
	message string
}

func newStandingDomainError(message string) *standingDomainError {
	return &standingDomainError{message: message}
}

func (e *standingDomainError) Error() string {
	return e.message
}
