package entities

import (
	"sort"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LeaderboardEntry represents a single entry in the leaderboard
type LeaderboardEntry struct {
	AthleteID     primitive.ObjectID `json:"athleteId" bson:"athleteId"`
	AthleteName   string             `json:"athleteName" bson:"athleteName"`
	AthleteNumber string             `json:"athleteNumber,omitempty" bson:"athleteNumber,omitempty"`
	ClubID        primitive.ObjectID `json:"clubId,omitempty" bson:"clubId,omitempty"`
	ClubName      string             `json:"clubName,omitempty" bson:"clubName,omitempty"`
	Position      int                `json:"position" bson:"position"`
	TotalScore    float64            `json:"totalScore" bson:"totalScore"`
	RoundScores   map[string]float64 `json:"roundScores" bson:"roundScores"`
}

// Leaderboard represents the competition leaderboard entity
type Leaderboard struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CompetitionID primitive.ObjectID `json:"competitionId" bson:"competitionId" validate:"required"`
	Entries       []LeaderboardEntry `json:"entries" bson:"entries"`
	UpdatedAt     time.Time          `json:"updatedAt" bson:"updatedAt"`
	CreatedAt     time.Time          `json:"createdAt" bson:"createdAt"`
}

// NewLeaderboard creates a new Leaderboard
func NewLeaderboard(competitionID primitive.ObjectID) *Leaderboard {
	now := time.Now()
	return &Leaderboard{
		ID:            primitive.NewObjectID(),
		CompetitionID: competitionID,
		Entries:       []LeaderboardEntry{},
		CreatedAt:     now,
		UpdatedAt:     now,
	}
}

// AddEntry adds or updates a leaderboard entry
func (l *Leaderboard) AddEntry(entry LeaderboardEntry) {
	// Check if athlete already exists
	found := false
	for i, e := range l.Entries {
		if e.AthleteID == entry.AthleteID {
			l.Entries[i] = entry
			found = true
			break
		}
	}

	if !found {
		l.Entries = append(l.Entries, entry)
	}

	l.UpdatedAt = time.Now()
}

// UpdateScore updates the score for an athlete in a specific round
func (l *Leaderboard) UpdateScore(athleteID primitive.ObjectID, roundID string, score float64) {
	for i, entry := range l.Entries {
		if entry.AthleteID == athleteID {
			if entry.RoundScores == nil {
				l.Entries[i].RoundScores = make(map[string]float64)
			}
			l.Entries[i].RoundScores[roundID] = score

			// Recalculate total score
			total := 0.0
			for _, s := range l.Entries[i].RoundScores {
				total += s
			}
			l.Entries[i].TotalScore = total
			break
		}
	}

	l.UpdatedAt = time.Now()
}

// SortByScore sorts entries by total score (descending)
func (l *Leaderboard) SortByScore() {
	sort.Slice(l.Entries, func(i, j int) bool {
		return l.Entries[i].TotalScore > l.Entries[j].TotalScore
	})

	// Update positions
	for i := range l.Entries {
		l.Entries[i].Position = i + 1
	}

	l.UpdatedAt = time.Now()
}

// GetTopThree returns the top 3 entries
func (l *Leaderboard) GetTopThree() (first, second, third *LeaderboardEntry) {
	if len(l.Entries) >= 1 {
		first = &l.Entries[0]
	}
	if len(l.Entries) >= 2 {
		second = &l.Entries[1]
	}
	if len(l.Entries) >= 3 {
		third = &l.Entries[2]
	}
	return
}

// GetEntryByAthleteID returns an entry by athlete ID
func (l *Leaderboard) GetEntryByAthleteID(athleteID primitive.ObjectID) *LeaderboardEntry {
	for _, entry := range l.Entries {
		if entry.AthleteID == athleteID {
			return &entry
		}
	}
	return nil
}

// PrepareForUpdate updates the timestamp
func (l *Leaderboard) PrepareForUpdate() {
	l.UpdatedAt = time.Now()
}
