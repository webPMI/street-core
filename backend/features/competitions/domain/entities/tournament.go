package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Tournament scoring system constants
const (
	TournamentScoringPoints      = "points"       // F1-style points system
	TournamentScoringTime        = "time"         // Sum/average of times
	TournamentScoringElimination = "elimination"  // Bracket-style elimination
	TournamentScoringBestResult  = "best_result"  // Best N results count
	TournamentScoringCustom      = "custom"       // Custom formula
)

// Tournament status constants
const (
	TournamentStatusUpcoming  = "upcoming"
	TournamentStatusLive      = "live"
	TournamentStatusCompleted = "completed"
	TournamentStatusCancelled = "cancelled"
	TournamentStatusPostponed = "postponed"
)

// Tournament registration status constants
const (
	TournamentRegistrationOpen   = "open"
	TournamentRegistrationClosed = "closed"
	TournamentRegistrationFull   = "full"
)

// TournamentScoringConfig defines the scoring configuration for a tournament
type TournamentScoringConfig struct {
	// Points system configuration (for ScoringPoints)
	PointsMap map[int]int `json:"pointsMap,omitempty" bson:"pointsMap,omitempty"` // Position -> Points (e.g., 1->25, 2->18, 3->15...)

	// Best results configuration (for ScoringBestResult)
	CountBestOf int `json:"countBestOf,omitempty" bson:"countBestOf,omitempty"` // Count best N results (e.g., best 3 of 5)

	// Custom formula (for ScoringCustom)
	CustomFormula string `json:"customFormula,omitempty" bson:"customFormula,omitempty"` // Custom scoring formula

	// Time aggregation (for ScoringTime)
	TimeAggregation string `json:"timeAggregation,omitempty" bson:"timeAggregation,omitempty"` // "sum" or "average"

	// General settings
	TieBreaker   string  `json:"tieBreaker,omitempty" bson:"tieBreaker,omitempty"`     // "best_finish", "head_to_head", "last_race"
	MinimumRaces int     `json:"minimumRaces,omitempty" bson:"minimumRaces,omitempty"` // Minimum races to qualify for standings
	DropWorst    int     `json:"dropWorst,omitempty" bson:"dropWorst,omitempty"`       // Number of worst results to drop
	Multiplier   float64 `json:"multiplier,omitempty" bson:"multiplier,omitempty"`     // Score multiplier
}

// TournamentSchedule represents tournament schedule information
type TournamentSchedule struct {
	StartDate    time.Time  `json:"startDate" bson:"startDate" validate:"required"`
	EndDate      time.Time  `json:"endDate" bson:"endDate" validate:"required"`
	Season       string     `json:"season,omitempty" bson:"season,omitempty"`         // e.g., "2025", "Winter 2025"
	Year         int        `json:"year" bson:"year" validate:"required"`
	TimeZone     string     `json:"timeZone,omitempty" bson:"timeZone,omitempty"`
	Venue        string     `json:"venue,omitempty" bson:"venue,omitempty"`           // Main venue (if applicable)
	Country      string     `json:"country,omitempty" bson:"country,omitempty"`
}

// TournamentRegistrationConfig represents tournament registration configuration
type TournamentRegistrationConfig struct {
	MaxParticipants          int                  `json:"maxParticipants" bson:"maxParticipants"`
	CurrentParticipants      int                  `json:"currentParticipants" bson:"currentParticipants"`
	RegistrationDeadline     *time.Time           `json:"registrationDeadline,omitempty" bson:"registrationDeadline,omitempty"`
	RegistrationStatus       string               `json:"registrationStatus" bson:"registrationStatus"` // open, closed, full
	AllowLateRegistration    bool                 `json:"allowLateRegistration" bson:"allowLateRegistration"`
	RequiresApproval         bool                 `json:"requiresApproval" bson:"requiresApproval"`
	EntryFee                 *float64             `json:"entryFee,omitempty" bson:"entryFee,omitempty"`
	Currency                 string               `json:"currency,omitempty" bson:"currency,omitempty"`
	AllowIndividualRaceEntry bool                 `json:"allowIndividualRaceEntry" bson:"allowIndividualRaceEntry"` // Allow registration to individual competitions
}

// Tournament represents a tournament entity that contains multiple competitions
type Tournament struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title       string             `json:"title" bson:"title" validate:"required,min=3,max=255"`
	Description string             `json:"description" bson:"description" validate:"required,min=10,max=2000"`

	// Organizer
	OrganizerID   primitive.ObjectID `json:"organizerId" bson:"organizerId" validate:"required"`
	OrganizerName string             `json:"organizerName" bson:"organizerName"`
	ClubID        primitive.ObjectID `json:"clubId,omitempty" bson:"clubId,omitempty"`
	ClubName      string             `json:"clubName,omitempty" bson:"clubName,omitempty"`

	// Type & Format
	SportType  string `json:"sportType" bson:"sportType" validate:"required"`     // motocross, enduro, trial, etc.
	Discipline string `json:"discipline" bson:"discipline" validate:"required"`   // Professional, Amateur, Junior, etc.
	Category   string `json:"category,omitempty" bson:"category,omitempty"`       // Age group, skill level, etc.
	Format     string `json:"format" bson:"format" validate:"required"`           // championship, series, cup, etc.

	// Embedded value objects
	Schedule     TournamentSchedule            `json:"schedule" bson:"schedule" validate:"required"`
	Registration TournamentRegistrationConfig  `json:"registration" bson:"registration"`

	// Scoring
	ScoringSystem string                  `json:"scoringSystem" bson:"scoringSystem" validate:"required,oneof=points time elimination best_result custom"`
	ScoringConfig TournamentScoringConfig `json:"scoringConfig" bson:"scoringConfig"`

	// Competitions (Rounds/Dates)
	CompetitionIDs    []primitive.ObjectID `json:"competitionIds" bson:"competitionIds"`
	TotalCompetitions int                  `json:"totalCompetitions" bson:"totalCompetitions"`
	CompletedRounds   int                  `json:"completedRounds" bson:"completedRounds"`

	// Participants
	RegisteredAthleteIDs []primitive.ObjectID `json:"registeredAthleteIds,omitempty" bson:"registeredAthleteIds,omitempty"`

	// Status
	Status           string `json:"status" bson:"status" validate:"required,oneof=upcoming live completed cancelled postponed"`
	IsLive           bool   `json:"isLive" bson:"isLive"`
	IsPublic         bool   `json:"isPublic" bson:"isPublic"`
	IsFeatured       bool   `json:"isFeatured" bson:"isFeatured"`

	// Results & Standings
	StandingsID        string     `json:"standingsId,omitempty" bson:"standingsId,omitempty"`
	IsResultsPublished bool       `json:"isResultsPublished" bson:"isResultsPublished"`
	ResultsPublishedAt *time.Time `json:"resultsPublishedAt,omitempty" bson:"resultsPublishedAt,omitempty"`

	// Prizes & Rules
	Prizes string `json:"prizes,omitempty" bson:"prizes,omitempty"`
	Rules  string `json:"rules,omitempty" bson:"rules,omitempty"`

	// Media
	BannerUrl string   `json:"bannerUrl,omitempty" bson:"bannerUrl,omitempty"`
	PosterUrl string   `json:"posterUrl,omitempty" bson:"posterUrl,omitempty"`
	ImageUrls []string `json:"imageUrls,omitempty" bson:"imageUrls,omitempty"`
	Tags      []string `json:"tags,omitempty" bson:"tags,omitempty"`

	// Metadata
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewTournament creates a new Tournament with defaults
func NewTournament(title, description string, organizerID primitive.ObjectID, sportType, discipline, format string) *Tournament {
	now := time.Now()
	return &Tournament{
		ID:            primitive.NewObjectID(),
		Title:         title,
		Description:   description,
		OrganizerID:   organizerID,
		SportType:     sportType,
		Discipline:    discipline,
		Format:        format,
		ScoringSystem: TournamentScoringPoints, // Default to points system
		ScoringConfig: TournamentScoringConfig{
			PointsMap: map[int]int{
				1: 25, 2: 18, 3: 15, 4: 12, 5: 10,
				6: 8, 7: 6, 8: 4, 9: 2, 10: 1,
			},
			TieBreaker: "best_finish",
		},
		Registration: TournamentRegistrationConfig{
			MaxParticipants:          100,
			RegistrationStatus:       TournamentRegistrationOpen,
			AllowIndividualRaceEntry: true,
			AllowLateRegistration:    false,
		},
		Status:            TournamentStatusUpcoming,
		IsLive:            false,
		IsPublic:          true,
		IsFeatured:        false,
		CompetitionIDs:    []primitive.ObjectID{},
		CompletedRounds:   0,
		TotalCompetitions: 0,
		CreatedAt:         now,
		UpdatedAt:         now,
	}
}

// CanRegister checks if registration is allowed
func (t *Tournament) CanRegister() bool {
	// Check if registration is open
	if t.Registration.RegistrationStatus != TournamentRegistrationOpen {
		return false
	}

	// Check if deadline has passed
	if t.Registration.RegistrationDeadline != nil && time.Now().After(*t.Registration.RegistrationDeadline) {
		// Allow late registration if enabled
		if !t.Registration.AllowLateRegistration {
			return false
		}
	}

	// Check if max participants reached
	if t.Registration.MaxParticipants > 0 && t.Registration.CurrentParticipants >= t.Registration.MaxParticipants {
		return false
	}

	// Check if tournament has started and late registration is not allowed
	if t.Status != TournamentStatusUpcoming && !t.Registration.AllowLateRegistration {
		return false
	}

	return true
}

// IsRegistrationOpen checks if registration is currently open
func (t *Tournament) IsRegistrationOpen() bool {
	return t.Registration.RegistrationStatus == TournamentRegistrationOpen &&
		(t.Status == TournamentStatusUpcoming || t.Registration.AllowLateRegistration) &&
		(t.Registration.RegistrationDeadline == nil || time.Now().Before(*t.Registration.RegistrationDeadline) || t.Registration.AllowLateRegistration)
}

// IsAthleteRegistered checks if athlete is registered
func (t *Tournament) IsAthleteRegistered(athleteID primitive.ObjectID) bool {
	for _, id := range t.RegisteredAthleteIDs {
		if id == athleteID {
			return true
		}
	}
	return false
}

// AddAthlete adds an athlete to the tournament
func (t *Tournament) AddAthlete(athleteID primitive.ObjectID) error {
	// Check if already registered
	if t.IsAthleteRegistered(athleteID) {
		return ErrTournamentAlreadyRegistered
	}

	// Check if can register
	if !t.CanRegister() {
		return ErrTournamentRegistrationClosed
	}

	// Add to registered athletes
	t.RegisteredAthleteIDs = append(t.RegisteredAthleteIDs, athleteID)
	t.Registration.CurrentParticipants++

	// Update registration status if needed
	if t.Registration.MaxParticipants > 0 && t.Registration.CurrentParticipants >= t.Registration.MaxParticipants {
		t.Registration.RegistrationStatus = TournamentRegistrationFull
	}

	t.UpdatedAt = time.Now()
	return nil
}

// RemoveAthlete removes an athlete from the tournament
func (t *Tournament) RemoveAthlete(athleteID primitive.ObjectID) error {
	// Find and remove athlete
	found := false
	for i, id := range t.RegisteredAthleteIDs {
		if id == athleteID {
			t.RegisteredAthleteIDs = append(
				t.RegisteredAthleteIDs[:i],
				t.RegisteredAthleteIDs[i+1:]...,
			)
			found = true
			break
		}
	}

	if !found {
		return ErrTournamentNotRegistered
	}

	t.Registration.CurrentParticipants--

	// Update registration status if was full
	if t.Registration.RegistrationStatus == TournamentRegistrationFull {
		t.Registration.RegistrationStatus = TournamentRegistrationOpen
	}

	t.UpdatedAt = time.Now()
	return nil
}

// AddCompetition adds a competition to the tournament
func (t *Tournament) AddCompetition(competitionID primitive.ObjectID) error {
	// Check if competition already added
	for _, id := range t.CompetitionIDs {
		if id == competitionID {
			return ErrTournamentCompetitionAlreadyAdded
		}
	}

	t.CompetitionIDs = append(t.CompetitionIDs, competitionID)
	t.TotalCompetitions++
	t.UpdatedAt = time.Now()

	return nil
}

// RemoveCompetition removes a competition from the tournament
func (t *Tournament) RemoveCompetition(competitionID primitive.ObjectID) error {
	found := false
	for i, id := range t.CompetitionIDs {
		if id == competitionID {
			t.CompetitionIDs = append(
				t.CompetitionIDs[:i],
				t.CompetitionIDs[i+1:]...,
			)
			found = true
			break
		}
	}

	if !found {
		return ErrTournamentCompetitionNotFound
	}

	t.TotalCompetitions--
	t.UpdatedAt = time.Now()

	return nil
}

// MarkAsLive marks the tournament as live
func (t *Tournament) MarkAsLive() {
	t.Status = TournamentStatusLive
	t.IsLive = true
	t.UpdatedAt = time.Now()
}

// MarkAsCompleted marks the tournament as completed
func (t *Tournament) MarkAsCompleted() {
	t.Status = TournamentStatusCompleted
	t.IsLive = false
	t.UpdatedAt = time.Now()
}

// PublishResults publishes the tournament results
func (t *Tournament) PublishResults() error {
	if t.Status != TournamentStatusCompleted && t.Status != TournamentStatusLive {
		return ErrTournamentInvalidStatus
	}

	now := time.Now()
	t.IsResultsPublished = true
	t.ResultsPublishedAt = &now
	t.UpdatedAt = now

	return nil
}

// IncrementCompletedRounds increments the completed rounds counter
func (t *Tournament) IncrementCompletedRounds() {
	t.CompletedRounds++
	t.UpdatedAt = time.Now()
}

// IsOwner checks if the given user ID is the organizer
func (t *Tournament) IsOwner(userID primitive.ObjectID) bool {
	return t.OrganizerID == userID
}

// PrepareForUpdate updates the timestamp
func (t *Tournament) PrepareForUpdate() {
	t.UpdatedAt = time.Now()
}

// Validate performs basic validation
func (t *Tournament) Validate() error {
	if t.Title == "" {
		return ErrTournamentInvalidInput
	}
	if t.Description == "" {
		return ErrTournamentInvalidInput
	}
	if t.OrganizerID.IsZero() {
		return ErrTournamentInvalidInput
	}
	if t.Schedule.StartDate.After(t.Schedule.EndDate) {
		return ErrTournamentInvalidInput
	}
	if t.ScoringSystem == "" {
		return ErrTournamentInvalidInput
	}

	return nil
}

// Domain errors for Tournament
var (
	ErrTournamentAlreadyRegistered       = newTournamentDomainError("athlete already registered in tournament")
	ErrTournamentNotRegistered           = newTournamentDomainError("athlete not registered in tournament")
	ErrTournamentRegistrationClosed      = newTournamentDomainError("tournament registration is closed")
	ErrTournamentInvalidStatus           = newTournamentDomainError("invalid tournament status")
	ErrTournamentInvalidInput            = newTournamentDomainError("invalid tournament input data")
	ErrTournamentCompetitionAlreadyAdded = newTournamentDomainError("competition already added to tournament")
	ErrTournamentCompetitionNotFound     = newTournamentDomainError("competition not found in tournament")
)

type tournamentDomainError struct {
	message string
}

func newTournamentDomainError(message string) *tournamentDomainError {
	return &tournamentDomainError{message: message}
}

func (e *tournamentDomainError) Error() string {
	return e.message
}
