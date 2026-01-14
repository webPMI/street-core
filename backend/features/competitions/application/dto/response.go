package dto

import (
	"time"

	"backend/features/competitions/domain/entities"
)

// CompetitionResponse represents the competition response
type CompetitionResponse struct {
	ID                 string                    `json:"id"`
	EventID            string                    `json:"eventId,omitempty"`
	Title              string                    `json:"title"`
	Description        string                    `json:"description"`
	OrganizerID        string                    `json:"organizerId"`
	OrganizerName      string                    `json:"organizerName"`
	ClubID             string                    `json:"clubId,omitempty"`
	ClubName           string                    `json:"clubName,omitempty"`
	CompetitionType    string                    `json:"competitionType"`
	Format             string                    `json:"format"`
	Discipline         string                    `json:"discipline"`
	Category           string                    `json:"category,omitempty"`
	Schedule           ScheduleDTO               `json:"schedule"`
	Registration       RegistrationResponseDTO   `json:"registration"`
	ScoringCriteria    ScoringCriteriaDTO        `json:"scoringCriteria"`
	JudgeIDs           []string                  `json:"judgeIds,omitempty"`
	RequiredJudges     int                       `json:"requiredJudges"`
	TotalRounds        int                       `json:"totalRounds"`
	CurrentRound       int                       `json:"currentRound"`
	RoundIDs           []string                  `json:"roundIds,omitempty"`
	HasQualifying      bool                      `json:"hasQualifying"`
	HasSemiFinals      bool                      `json:"hasSemiFinals"`
	HasFinals          bool                      `json:"hasFinals"`
	Status             string                    `json:"status"`
	IsLive             bool                      `json:"isLive"`
	AllowLiveScoring   bool                      `json:"allowLiveScoring"`
	ShowLiveResults    bool                      `json:"showLiveResults"`
	LeaderboardID      string                    `json:"leaderboardId,omitempty"`
	IsResultsPublished bool                      `json:"isResultsPublished"`
	ResultsPublishedAt *time.Time                `json:"resultsPublishedAt,omitempty"`
	Rules              string                    `json:"rules,omitempty"`
	BannerUrl          string                    `json:"bannerUrl,omitempty"`
	ImageUrls          []string                  `json:"imageUrls,omitempty"`
	Tags               []string                  `json:"tags,omitempty"`
	CreatedAt          time.Time                 `json:"createdAt"`
	UpdatedAt          time.Time                 `json:"updatedAt"`
}

// RegistrationResponseDTO includes additional info for responses
type RegistrationResponseDTO struct {
	MaxParticipants      int        `json:"maxParticipants"`
	MinParticipants      int        `json:"minParticipants"`
	CurrentParticipants  int        `json:"currentParticipants"`
	RegistrationDeadline *time.Time `json:"registrationDeadline,omitempty"`
	RequiresApproval     bool       `json:"requiresApproval"`
	EntryFee             *float64   `json:"entryFee,omitempty"`
	Currency             string     `json:"currency,omitempty"`
	ParticipantStatus    string     `json:"participantStatus"`
	RegisteredAthletes   int        `json:"registeredAthletes"`
	WaitlistCount        int        `json:"waitlistCount"`
}

// CompetitionListResponse represents a list of competitions
type CompetitionListResponse struct {
	Competitions []CompetitionResponse `json:"competitions"`
	Total        int64                 `json:"total"`
	Page         int                   `json:"page"`
	Limit        int                   `json:"limit"`
}

// LeaderboardResponse represents leaderboard response
type LeaderboardResponse struct {
	ID            string                 `json:"id"`
	CompetitionID string                 `json:"competitionId"`
	Entries       []LeaderboardEntryDTO  `json:"entries"`
	UpdatedAt     time.Time              `json:"updatedAt"`
}

// LeaderboardEntryDTO represents a leaderboard entry
type LeaderboardEntryDTO struct {
	AthleteID     string             `json:"athleteId"`
	AthleteName   string             `json:"athleteName"`
	AthleteNumber string             `json:"athleteNumber,omitempty"`
	ClubID        string             `json:"clubId,omitempty"`
	ClubName      string             `json:"clubName,omitempty"`
	Position      int                `json:"position"`
	TotalScore    float64            `json:"totalScore"`
	RoundScores   map[string]float64 `json:"roundScores"`
}

// ToCompetitionResponse converts a Competition entity to CompetitionResponse
func ToCompetitionResponse(comp *entities.Competition) CompetitionResponse {
	response := CompetitionResponse{
		ID:                 comp.ID.Hex(),
		Title:              comp.Title,
		Description:        comp.Description,
		OrganizerID:        comp.OrganizerID.Hex(),
		OrganizerName:      comp.OrganizerName,
		CompetitionType:    comp.CompetitionType,
		Format:             comp.Format,
		Discipline:         comp.Discipline,
		Category:           comp.Category,
		Schedule:           FromScheduleEntity(comp.Schedule),
		ScoringCriteria:    FromScoringCriteriaEntity(comp.ScoringCriteria),
		RequiredJudges:     comp.RequiredJudges,
		TotalRounds:        comp.TotalRounds,
		CurrentRound:       comp.CurrentRound,
		RoundIDs:           comp.RoundIDs,
		HasQualifying:      comp.HasQualifying,
		HasSemiFinals:      comp.HasSemiFinals,
		HasFinals:          comp.HasFinals,
		Status:             comp.Status,
		IsLive:             comp.IsLive,
		AllowLiveScoring:   comp.AllowLiveScoring,
		ShowLiveResults:    comp.ShowLiveResults,
		LeaderboardID:      comp.LeaderboardID,
		IsResultsPublished: comp.IsResultsPublished,
		ResultsPublishedAt: comp.ResultsPublishedAt,
		Rules:              comp.Rules,
		BannerUrl:          comp.BannerUrl,
		ImageUrls:          comp.ImageUrls,
		Tags:               comp.Tags,
		CreatedAt:          comp.CreatedAt,
		UpdatedAt:          comp.UpdatedAt,
	}

	// Optional fields
	if !comp.EventID.IsZero() {
		response.EventID = comp.EventID.Hex()
	}
	if !comp.ClubID.IsZero() {
		response.ClubID = comp.ClubID.Hex()
		response.ClubName = comp.ClubName
	}

	// Convert JudgeIDs
	if len(comp.JudgeIDs) > 0 {
		response.JudgeIDs = make([]string, len(comp.JudgeIDs))
		for i, id := range comp.JudgeIDs {
			response.JudgeIDs[i] = id.Hex()
		}
	}

	// Registration info
	response.Registration = RegistrationResponseDTO{
		MaxParticipants:      comp.Registration.MaxParticipants,
		MinParticipants:      comp.Registration.MinParticipants,
		CurrentParticipants:  comp.Registration.CurrentParticipants,
		RegistrationDeadline: comp.Registration.RegistrationDeadline,
		RequiresApproval:     comp.Registration.RequiresApproval,
		EntryFee:             comp.Registration.EntryFee,
		Currency:             comp.Registration.Currency,
		ParticipantStatus:    comp.Registration.ParticipantStatus,
		RegisteredAthletes:   len(comp.Registration.RegisteredAthleteIDs),
		WaitlistCount:        len(comp.Registration.WaitlistAthleteIDs),
	}

	return response
}

// FromScoringCriteriaEntity converts entities.ScoringCriteria to ScoringCriteriaDTO
func FromScoringCriteriaEntity(sc entities.ScoringCriteria) ScoringCriteriaDTO {
	criteria := make([]ScoreCriterionDTO, len(sc.Criteria))
	for i, c := range sc.Criteria {
		criteria[i] = ScoreCriterionDTO{
			Name:     c.Name,
			Weight:   c.Weight,
			MaxScore: c.MaxScore,
		}
	}

	return ScoringCriteriaDTO{
		Type:        sc.Type,
		MinScore:    sc.MinScore,
		MaxScore:    sc.MaxScore,
		Criteria:    criteria,
		DropHighest: sc.DropHighest,
		DropLowest:  sc.DropLowest,
	}
}

// ToLeaderboardResponse converts Leaderboard entity to LeaderboardResponse
func ToLeaderboardResponse(lb *entities.Leaderboard) LeaderboardResponse {
	entries := make([]LeaderboardEntryDTO, len(lb.Entries))
	for i, entry := range lb.Entries {
		entries[i] = LeaderboardEntryDTO{
			AthleteID:     entry.AthleteID.Hex(),
			AthleteName:   entry.AthleteName,
			AthleteNumber: entry.AthleteNumber,
			Position:      entry.Position,
			TotalScore:    entry.TotalScore,
			RoundScores:   entry.RoundScores,
		}
		if !entry.ClubID.IsZero() {
			entries[i].ClubID = entry.ClubID.Hex()
			entries[i].ClubName = entry.ClubName
		}
	}

	return LeaderboardResponse{
		ID:            lb.ID.Hex(),
		CompetitionID: lb.CompetitionID.Hex(),
		Entries:       entries,
		UpdatedAt:     lb.UpdatedAt,
	}
}
