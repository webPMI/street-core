package entities

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Competition type constants
const (
	CompetitionTypeIndividual = "individual"
	CompetitionTypeTeam       = "team"
	CompetitionTypeBoth       = "both"
)

// Competition format constants
const (
	FormatSingleRound = "single_round"
	FormatMultiRound  = "multi_round"
	FormatElimination = "elimination"
	FormatTimeTrial   = "time_trial"
	FormatPointsRace  = "points_race"
)

// Scoring type constants
const (
	ScoringTypePoints          = "points"
	ScoringTypeTime            = "time"
	ScoringTypeAverage         = "average"
	ScoringTypeSum             = "sum"
	ScoringTypeWeightedAverage = "weighted_average"
)

// Competition status constants
const (
	StatusUpcoming  = "upcoming"
	StatusLive      = "live"
	StatusCompleted = "completed"
	StatusCancelled = "cancelled"
	StatusPostponed = "postponed"
)

// Participant status constants
const (
	ParticipantStatusOpen   = "open"
	ParticipantStatusClosed = "closed"
	ParticipantStatusFull   = "full"
)

// Registration type constants
const (
	RegistrationTypeInternal = "internal"
	RegistrationTypeExternal = "external"
)

// Schedule represents competition schedule information
type Schedule struct {
	StartDate time.Time  `json:"startDate" bson:"startDate" validate:"required"`
	EndDate   time.Time  `json:"endDate" bson:"endDate" validate:"required"`
	Venue     string     `json:"venue,omitempty" bson:"venue,omitempty"`
	City      string     `json:"city,omitempty" bson:"city,omitempty"`
	Country   string     `json:"country,omitempty" bson:"country,omitempty"`
	Latitude  *float64   `json:"latitude,omitempty" bson:"latitude,omitempty"`
	Longitude *float64   `json:"longitude,omitempty" bson:"longitude,omitempty"`
	TimeZone  string     `json:"timeZone,omitempty" bson:"timeZone,omitempty"`
}

// Registration represents competition registration configuration
type Registration struct {
	MaxParticipants      int                    `json:"maxParticipants" bson:"maxParticipants"`
	MinParticipants      int                    `json:"minParticipants" bson:"minParticipants"`
	CurrentParticipants  int                    `json:"currentParticipants" bson:"currentParticipants"`
	RegistrationDeadline *time.Time             `json:"registrationDeadline,omitempty" bson:"registrationDeadline,omitempty"`
	RequiresApproval     bool                   `json:"requiresApproval" bson:"requiresApproval"`
	EntryFee             *float64               `json:"entryFee,omitempty" bson:"entryFee,omitempty"`
	Currency             string                 `json:"currency,omitempty" bson:"currency,omitempty"`
	RegisteredAthleteIDs []primitive.ObjectID   `json:"registeredAthleteIds,omitempty" bson:"registeredAthleteIds,omitempty"`
	WaitlistAthleteIDs   []primitive.ObjectID   `json:"waitlistAthleteIds,omitempty" bson:"waitlistAthleteIds,omitempty"`
	ParticipantStatus    string                 `json:"participantStatus" bson:"participantStatus"`
	// Registration Type: "internal" or "external"
	Type                   string `json:"type" bson:"type" validate:"required,oneof=internal external"`
	// External registration URL (required when type is "external")
	ExternalRegistrationURL *string `json:"externalRegistrationUrl,omitempty" bson:"externalRegistrationUrl,omitempty"`
	// External provider (e.g., "eventbrite", "ticketmaster")
	ExternalProvider string `json:"externalProvider,omitempty" bson:"externalProvider,omitempty"`
}

// ScoreCriterion represents a single judging criterion
type ScoreCriterion struct {
	Name     string  `json:"name" bson:"name" validate:"required"`
	Weight   float64 `json:"weight" bson:"weight" validate:"required,gte=0,lte=1"`
	MaxScore float64 `json:"maxScore" bson:"maxScore" validate:"required,gt=0"`
}

// ScoringCriteria defines how scores are calculated
type ScoringCriteria struct {
	Type        string           `json:"type" bson:"type" validate:"required,oneof=points time average sum weighted_average"`
	MinScore    float64          `json:"minScore" bson:"minScore"`
	MaxScore    float64          `json:"maxScore" bson:"maxScore" validate:"required,gt=0"`
	Criteria    []ScoreCriterion `json:"criteria,omitempty" bson:"criteria,omitempty"`
	DropHighest bool             `json:"dropHighest" bson:"dropHighest"`
	DropLowest  bool             `json:"dropLowest" bson:"dropLowest"`
}

// Competition represents a competition entity with all business rules
type Competition struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	EventID       primitive.ObjectID `json:"eventId,omitempty" bson:"eventId,omitempty"`
	Title         string             `json:"title" bson:"title" validate:"required,min=3,max=255"`
	Description   string             `json:"description" bson:"description" validate:"required,min=10,max=2000"`
	OrganizerID   primitive.ObjectID `json:"organizerId" bson:"organizerId" validate:"required"`
	OrganizerName string             `json:"organizerName" bson:"organizerName"`
	ClubID        primitive.ObjectID `json:"clubId,omitempty" bson:"clubId,omitempty"`
	ClubName      string             `json:"clubName,omitempty" bson:"clubName,omitempty"`

	// Tournament relationship (if part of a tournament)
	TournamentID   primitive.ObjectID `json:"tournamentId,omitempty" bson:"tournamentId,omitempty"`
	TournamentName string             `json:"tournamentName,omitempty" bson:"tournamentName,omitempty"`
	RoundNumber    *int               `json:"roundNumber,omitempty" bson:"roundNumber,omitempty"` // Round/Date number in tournament

	// Type & Format
	CompetitionType string `json:"competitionType" bson:"competitionType" validate:"required,oneof=individual team both"`
	Format          string `json:"format" bson:"format" validate:"required"`
	Discipline      string `json:"discipline" bson:"discipline" validate:"required,max=50"`
	Category        string `json:"category,omitempty" bson:"category,omitempty"`

	// Embedded value objects
	Schedule        Schedule        `json:"schedule" bson:"schedule" validate:"required"`
	Registration    Registration    `json:"registration" bson:"registration"`
	ScoringCriteria ScoringCriteria `json:"scoringCriteria" bson:"scoringCriteria" validate:"required"`

	// Judging
	JudgeIDs       []primitive.ObjectID `json:"judgeIds,omitempty" bson:"judgeIds,omitempty"`
	HeadJudgeIDs   []primitive.ObjectID `json:"headJudgeIds,omitempty" bson:"headJudgeIds,omitempty"`
	RequiredJudges int                  `json:"requiredJudges" bson:"requiredJudges"`

	// Rounds
	TotalRounds   int      `json:"totalRounds" bson:"totalRounds"`
	CurrentRound  int      `json:"currentRound" bson:"currentRound"`
	RoundIDs      []string `json:"roundIds,omitempty" bson:"roundIds,omitempty"`
	HasQualifying bool     `json:"hasQualifying" bson:"hasQualifying"`
	HasSemiFinals bool     `json:"hasSemiFinals" bson:"hasSemiFinals"`
	HasFinals     bool     `json:"hasFinals" bson:"hasFinals"`

	// Heat configuration (inherited by all rounds)
	EnableHeats      bool   `json:"enableHeats" bson:"enableHeats"`
	DefaultHeatMode  string `json:"defaultHeatMode,omitempty" bson:"defaultHeatMode,omitempty" validate:"omitempty,oneof=sequential simultaneous"`
	DefaultHeatSize  int    `json:"defaultHeatSize,omitempty" bson:"defaultHeatSize,omitempty"`

	// SECURITY: Heat Check-In Configuration (Ready Protocol)
	EnableHeatCheckIn       bool     `json:"enableHeatCheckIn" bson:"enableHeatCheckIn"`                                   // Enable check-in system for all heats
	DefaultRequiredRoles    []string `json:"defaultRequiredRoles,omitempty" bson:"defaultRequiredRoles,omitempty"`         // Default roles required: judge, speaker, marshall
	DefaultMinJudgesActive  int      `json:"defaultMinJudgesActive,omitempty" bson:"defaultMinJudgesActive,omitempty"`     // Minimum judges to start/continue (for bypass)
	ScoreGracePeriodMinutes int      `json:"scoreGracePeriodMinutes,omitempty" bson:"scoreGracePeriodMinutes,omitempty"`   // Period where judges can request score unlock (default: 15 minutes)

	// Status
	Status           string `json:"status" bson:"status" validate:"required,oneof=upcoming live completed cancelled postponed"`
	IsLive           bool   `json:"isLive" bson:"isLive"`
	AllowLiveScoring bool   `json:"allowLiveScoring" bson:"allowLiveScoring"`
	ShowLiveResults  bool   `json:"showLiveResults" bson:"showLiveResults"`

	// Results
	LeaderboardID      string     `json:"leaderboardId,omitempty" bson:"leaderboardId,omitempty"`
	IsResultsPublished bool       `json:"isResultsPublished" bson:"isResultsPublished"`
	ResultsPublishedAt *time.Time `json:"resultsPublishedAt,omitempty" bson:"resultsPublishedAt,omitempty"`

	// Rules & Media
	Rules      string   `json:"rules,omitempty" bson:"rules,omitempty"`
	BannerUrl  string   `json:"bannerUrl,omitempty" bson:"bannerUrl,omitempty"`
	ImageUrls  []string `json:"imageUrls,omitempty" bson:"imageUrls,omitempty"`
	Tags       []string `json:"tags,omitempty" bson:"tags,omitempty"`

	// Metadata
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" bson:"updatedAt"`
}

// NewCompetition creates a new Competition with defaults
func NewCompetition(title, description string, organizerID primitive.ObjectID, competitionType, format, discipline string) *Competition {
	now := time.Now()
	return &Competition{
		ID:              primitive.NewObjectID(),
		Title:           title,
		Description:     description,
		OrganizerID:     organizerID,
		CompetitionType: competitionType,
		Format:          format,
		Discipline:      discipline,
		Registration: Registration{
			MaxParticipants:   100,
			MinParticipants:   2,
			ParticipantStatus: ParticipantStatusOpen,
			Type:              RegistrationTypeInternal, // Default to internal registration
		},
		RequiredJudges:   3,
		TotalRounds:      1,
		CurrentRound:     0,
		Status:           StatusUpcoming,
		IsLive:           false,
		AllowLiveScoring: true,
		ShowLiveResults:  true,
		HasFinals:        true,
		CreatedAt:        now,
		UpdatedAt:        now,
	}
}

// CanRegister checks if registration is allowed
func (c *Competition) CanRegister() bool {
	// Check if registration is open
	if c.Registration.ParticipantStatus != ParticipantStatusOpen {
		return false
	}

	// Check if deadline has passed
	if c.Registration.RegistrationDeadline != nil && time.Now().After(*c.Registration.RegistrationDeadline) {
		return false
	}

	// Check if max participants reached
	if c.Registration.MaxParticipants > 0 && c.Registration.CurrentParticipants >= c.Registration.MaxParticipants {
		return false
	}

	// Check if competition has started
	if c.Status != StatusUpcoming {
		return false
	}

	return true
}

// IsRegistrationOpen checks if registration is currently open
func (c *Competition) IsRegistrationOpen() bool {
	return c.Registration.ParticipantStatus == ParticipantStatusOpen &&
		c.Status == StatusUpcoming &&
		(c.Registration.RegistrationDeadline == nil || time.Now().Before(*c.Registration.RegistrationDeadline))
}

// CanSubmitScores checks if scores can be submitted
func (c *Competition) CanSubmitScores() bool {
	return c.Status == StatusLive || c.AllowLiveScoring
}

// IsOwner checks if the given user ID is the organizer
func (c *Competition) IsOwner(userID primitive.ObjectID) bool {
	return c.OrganizerID == userID
}

// IsJudge checks if the given user ID is a judge
func (c *Competition) IsJudge(userID primitive.ObjectID) bool {
	for _, judgeID := range c.JudgeIDs {
		if judgeID == userID {
			return true
		}
	}
	return false
}

// IsHeadJudge checks if the given user ID is a head judge
func (c *Competition) IsHeadJudge(userID primitive.ObjectID) bool {
	for _, headJudgeID := range c.HeadJudgeIDs {
		if headJudgeID == userID {
			return true
		}
	}
	return false
}

// IsAthleteRegistered checks if athlete is registered
func (c *Competition) IsAthleteRegistered(athleteID primitive.ObjectID) bool {
	for _, id := range c.Registration.RegisteredAthleteIDs {
		if id == athleteID {
			return true
		}
	}
	return false
}

// AddAthlete adds an athlete to the competition
func (c *Competition) AddAthlete(athleteID primitive.ObjectID) error {
	// Check if already registered
	if c.IsAthleteRegistered(athleteID) {
		return ErrAlreadyRegistered
	}

	// Check if can register
	if !c.CanRegister() {
		return ErrRegistrationClosed
	}

	// Add to registered athletes
	c.Registration.RegisteredAthleteIDs = append(c.Registration.RegisteredAthleteIDs, athleteID)
	c.Registration.CurrentParticipants++

	// Update participant status if needed
	if c.Registration.MaxParticipants > 0 && c.Registration.CurrentParticipants >= c.Registration.MaxParticipants {
		c.Registration.ParticipantStatus = ParticipantStatusFull
	}

	c.UpdatedAt = time.Now()
	return nil
}

// RemoveAthlete removes an athlete from the competition
func (c *Competition) RemoveAthlete(athleteID primitive.ObjectID) error {
	// Find and remove athlete
	found := false
	for i, id := range c.Registration.RegisteredAthleteIDs {
		if id == athleteID {
			c.Registration.RegisteredAthleteIDs = append(
				c.Registration.RegisteredAthleteIDs[:i],
				c.Registration.RegisteredAthleteIDs[i+1:]...,
			)
			found = true
			break
		}
	}

	if !found {
		return ErrNotRegistered
	}

	c.Registration.CurrentParticipants--

	// Update participant status if was full
	if c.Registration.ParticipantStatus == ParticipantStatusFull {
		c.Registration.ParticipantStatus = ParticipantStatusOpen
	}

	c.UpdatedAt = time.Now()
	return nil
}

// AddJudge adds a judge to the competition
func (c *Competition) AddJudge(judgeID primitive.ObjectID) error {
	// Check if already a judge
	if c.IsJudge(judgeID) {
		return ErrAlreadyJudge
	}

	c.JudgeIDs = append(c.JudgeIDs, judgeID)
	c.UpdatedAt = time.Now()
	return nil
}

// AddHeadJudge adds a head judge to the competition
func (c *Competition) AddHeadJudge(judgeID primitive.ObjectID) error {
	// Check if already a head judge
	if c.IsHeadJudge(judgeID) {
		return ErrAlreadyHeadJudge
	}

	// Add to head judges
	c.HeadJudgeIDs = append(c.HeadJudgeIDs, judgeID)

	// Also add to regular judges if not already there
	if !c.IsJudge(judgeID) {
		c.JudgeIDs = append(c.JudgeIDs, judgeID)
	}

	c.UpdatedAt = time.Now()
	return nil
}

// CloseRegistration closes the registration for the competition
func (c *Competition) CloseRegistration() {
	c.Registration.ParticipantStatus = ParticipantStatusClosed
	c.UpdatedAt = time.Now()
}

// MarkAsLive marks the competition as live
func (c *Competition) MarkAsLive() {
	c.Status = StatusLive
	c.IsLive = true
	c.UpdatedAt = time.Now()
}

// MarkAsCompleted marks the competition as completed
func (c *Competition) MarkAsCompleted() {
	c.Status = StatusCompleted
	c.IsLive = false
	c.UpdatedAt = time.Now()
}

// MarkAsPostponed marks the competition as postponed
func (c *Competition) MarkAsPostponed() {
	c.Status = StatusPostponed
	c.IsLive = false
	c.UpdatedAt = time.Now()
}

// PublishResults publishes the competition results
func (c *Competition) PublishResults() error {
	if c.Status != StatusCompleted && c.Status != StatusLive {
		return ErrInvalidStatus
	}

	now := time.Now()
	c.IsResultsPublished = true
	c.ResultsPublishedAt = &now
	c.UpdatedAt = now
	return nil
}

// IsPartOfTournament checks if this competition is part of a tournament
func (c *Competition) IsPartOfTournament() bool {
	return !c.TournamentID.IsZero()
}

// SetTournament sets the tournament relationship
func (c *Competition) SetTournament(tournamentID primitive.ObjectID, tournamentName string, roundNumber int) {
	c.TournamentID = tournamentID
	c.TournamentName = tournamentName
	c.RoundNumber = &roundNumber
	c.UpdatedAt = time.Now()
}

// RemoveTournament removes the tournament relationship
func (c *Competition) RemoveTournament() {
	c.TournamentID = primitive.NilObjectID
	c.TournamentName = ""
	c.RoundNumber = nil
	c.UpdatedAt = time.Now()
}

// PrepareForUpdate updates the timestamp
func (c *Competition) PrepareForUpdate() {
	c.UpdatedAt = time.Now()
}

// Validate performs basic validation
func (c *Competition) Validate() error {
	if c.Title == "" {
		return ErrInvalidInput
	}
	if c.Description == "" {
		return ErrInvalidInput
	}
	if c.OrganizerID.IsZero() {
		return ErrInvalidInput
	}
	if c.Schedule.StartDate.After(c.Schedule.EndDate) {
		return ErrInvalidInput
	}
	// Validate registration configuration
	if err := c.ValidateRegistration(); err != nil {
		return err
	}
	return nil
}

// ValidateRegistration validates the registration configuration
// Ensures that external registrations have a valid URL
func (c *Competition) ValidateRegistration() error {
	// Check registration type is set
	if c.Registration.Type != RegistrationTypeInternal && c.Registration.Type != RegistrationTypeExternal {
		return ErrInvalidRegistrationType
	}

	// If external registration, URL must be provided
	if c.Registration.Type == RegistrationTypeExternal {
		if c.Registration.ExternalRegistrationURL == nil || *c.Registration.ExternalRegistrationURL == "" {
			return ErrExternalRegistrationURLRequired
		}
		if err := c.ValidateExternalURL(*c.Registration.ExternalRegistrationURL); err != nil {
			return err
		}
	}

	return nil
}

// ValidateExternalURL validates the external registration URL
func (c *Competition) ValidateExternalURL(url string) error {
	// URL must start with https
	if !isHTTPSURL(url) {
		return ErrInvalidExternalURL
	}

	// Check if URL belongs to whitelisted providers
	if !isWhitelistedDomain(url) {
		return ErrUnsupportedExternalProvider
	}

	return nil
}

// isHTTPSURL checks if a URL uses HTTPS protocol
func isHTTPSURL(url string) bool {
	return len(url) > 8 && url[:8] == "https://"
}

// isWhitelistedDomain checks if a URL belongs to a whitelisted external provider
func isWhitelistedDomain(url string) bool {
	whitelistedDomains := []string{
		"eventbrite.com",
		"ticketmaster.com",
		"ticketticket.com",
		"vivid-seats.com",
		"stub-hub.com", // StubHub
		"universe.com",
		"eventive.org",
		"lyte.com",
	}

	for _, domain := range whitelistedDomains {
		if len(url) > len(domain) && (url[8:len(domain)+8] == domain || url[8:] == domain) {
			return true
		}
	}

	return false
}

// Domain errors
var (
	ErrAlreadyRegistered         = newDomainError("athlete already registered")
	ErrNotRegistered             = newDomainError("athlete not registered")
	ErrRegistrationClosed        = newDomainError("registration is closed")
	ErrAlreadyJudge              = newDomainError("user is already a judge")
	ErrAlreadyHeadJudge          = newDomainError("user is already a head judge")
	ErrInvalidStatus             = newDomainError("invalid competition status")
	ErrInvalidInput              = newDomainError("invalid input data")
	ErrNoCategoriesConfigured    = newDomainError("no categories configured for this competition")
	ErrCategoriesWithoutCriteria = newDomainError("one or more categories have no scoring criteria configured")
	ErrInvalidRegistrationType   = newDomainError("registration type must be 'internal' or 'external'")
	ErrExternalRegistrationURLRequired = newDomainError("external registration URL is required when type is 'external'")
	ErrInvalidExternalURL        = newDomainError("external registration URL must use HTTPS protocol")
	ErrUnsupportedExternalProvider = newDomainError("external registration provider is not supported")
)

type domainError struct {
	message string
}

func newDomainError(message string) *domainError {
	return &domainError{message: message}
}
func (e *domainError) Error() string {
	return e.message
}

// FormatToHeatMode maps competition formats to default heat modes
var FormatToHeatMode = map[string]string{
	FormatSingleRound: "sequential",
	FormatMultiRound:  "sequential",
	FormatElimination: "sequential",
	FormatTimeTrial:   "simultaneous",
	FormatPointsRace:  "simultaneous",
}

// GetDefaultHeatMode returns the default heat mode for this competition
func (c *Competition) GetDefaultHeatMode() string {
	// If explicitly set, use that
	if c.DefaultHeatMode != "" {
		return c.DefaultHeatMode
	}

	// Otherwise infer from format
	if mode, ok := FormatToHeatMode[c.Format]; ok {
		return mode
	}

	// Default to sequential
	return "sequential"
}

// UsesHeats returns true if this competition uses heats
func (c *Competition) UsesHeats() bool {
	return c.EnableHeats
}
