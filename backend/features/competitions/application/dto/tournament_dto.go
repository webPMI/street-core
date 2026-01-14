package dto

import (
	"time"

	"backend/features/competitions/domain/entities"
)

// ==================== REQUEST DTOs ====================

// CreateTournamentRequest represents a request to create a tournament
type CreateTournamentRequest struct {
	Title        string    `json:"title" validate:"required,min=3,max=255"`
	Description  string    `json:"description" validate:"required,min=10,max=2000"`
	SportType    string    `json:"sportType" validate:"required"`
	Discipline   string    `json:"discipline" validate:"required"`
	Category     string    `json:"category,omitempty"`
	Format       string    `json:"format" validate:"required"`
	StartDate    time.Time `json:"startDate" validate:"required"`
	EndDate      time.Time `json:"endDate" validate:"required"`
	Season       string    `json:"season,omitempty"`
	Year         int       `json:"year" validate:"required"`
	Country      string    `json:"country,omitempty"`
	Venue        string    `json:"venue,omitempty"`
	TimeZone     string    `json:"timeZone,omitempty"`
	ScoringSystem string   `json:"scoringSystem" validate:"required,oneof=points time elimination best_result custom"`
	ScoringConfig ScoringConfigDTO `json:"scoringConfig"`
	Registration  RegistrationConfigDTO `json:"registration"`
	Prizes        string    `json:"prizes,omitempty"`
	Rules         string    `json:"rules,omitempty"`
	BannerUrl     string    `json:"bannerUrl,omitempty"`
	PosterUrl     string    `json:"posterUrl,omitempty"`
	Tags          []string  `json:"tags,omitempty"`
	IsPublic      bool      `json:"isPublic"`
	IsFeatured    bool      `json:"isFeatured"`
}

// UpdateTournamentRequest represents a request to update a tournament
type UpdateTournamentRequest struct {
	Title        string    `json:"title,omitempty"`
	Description  string    `json:"description,omitempty"`
	SportType    string    `json:"sportType,omitempty"`
	Discipline   string    `json:"discipline,omitempty"`
	Category     string    `json:"category,omitempty"`
	Format       string    `json:"format,omitempty"`
	StartDate    *time.Time `json:"startDate,omitempty"`
	EndDate      *time.Time `json:"endDate,omitempty"`
	Season       string    `json:"season,omitempty"`
	Year         int       `json:"year,omitempty"`
	Country      string    `json:"country,omitempty"`
	Venue        string    `json:"venue,omitempty"`
	ScoringSystem string   `json:"scoringSystem,omitempty"`
	ScoringConfig *ScoringConfigDTO `json:"scoringConfig,omitempty"`
	Registration  *RegistrationConfigDTO `json:"registration,omitempty"`
	Prizes        string    `json:"prizes,omitempty"`
	Rules         string    `json:"rules,omitempty"`
	BannerUrl     string    `json:"bannerUrl,omitempty"`
	PosterUrl     string    `json:"posterUrl,omitempty"`
	Tags          []string  `json:"tags,omitempty"`
	IsPublic      *bool     `json:"isPublic,omitempty"`
	IsFeatured    *bool     `json:"isFeatured,omitempty"`
}

// ScoringConfigDTO represents tournament scoring configuration
type ScoringConfigDTO struct {
	PointsMap       map[int]int `json:"pointsMap,omitempty"`
	CountBestOf     int         `json:"countBestOf,omitempty"`
	CustomFormula   string      `json:"customFormula,omitempty"`
	TimeAggregation string      `json:"timeAggregation,omitempty"`
	TieBreaker      string      `json:"tieBreaker,omitempty"`
	MinimumRaces    int         `json:"minimumRaces,omitempty"`
	DropWorst       int         `json:"dropWorst,omitempty"`
	Multiplier      float64     `json:"multiplier,omitempty"`
}

// RegistrationConfigDTO represents tournament registration configuration
type RegistrationConfigDTO struct {
	MaxParticipants          int        `json:"maxParticipants"`
	RegistrationDeadline     *time.Time `json:"registrationDeadline,omitempty"`
	AllowLateRegistration    bool       `json:"allowLateRegistration"`
	RequiresApproval         bool       `json:"requiresApproval"`
	EntryFee                 *float64   `json:"entryFee,omitempty"`
	Currency                 string     `json:"currency,omitempty"`
	AllowIndividualRaceEntry bool       `json:"allowIndividualRaceEntry"`
}

// RegisterTournamentRequest represents a tournament registration request
type RegisterTournamentRequest struct {
	RegistrationType       string                `json:"registrationType" validate:"required,oneof=full individual"`
	SelectedCompetitionIDs []string              `json:"selectedCompetitionIds,omitempty"`
	RaceNumber             *int                  `json:"raceNumber,omitempty"`
	Team                   string                `json:"team,omitempty"`
	VehicleMake            string                `json:"vehicleMake,omitempty"`
	VehicleModel           string                `json:"vehicleModel,omitempty"`
	VehicleYear            *int                  `json:"vehicleYear,omitempty"`
	LicenseNumber          string                `json:"licenseNumber,omitempty"`
	LicenseFederation      string                `json:"licenseFederation,omitempty"`
	EmergencyContactName   string                `json:"emergencyContactName,omitempty"`
	EmergencyContactPhone  string                `json:"emergencyContactPhone,omitempty"`
	MedicalNotes           string                `json:"medicalNotes,omitempty"`
}

// AddCompetitionRequest represents a request to add a competition to a tournament
type AddCompetitionRequest struct {
	CompetitionID string `json:"competitionId" validate:"required"`
}

// UpdateStandingsRequest represents a request to update tournament standings
type UpdateStandingsRequest struct {
	TriggerRecalculation bool `json:"triggerRecalculation"`
}

// ApproveRegistrationRequest represents approval/rejection request
type ApproveRegistrationRequest struct {
	RegistrationIDs []string `json:"registrationIds" validate:"required,min=1"`
	Reason          string   `json:"reason,omitempty"` // For rejection
}

// ==================== RESPONSE DTOs ====================

// TournamentResponse represents a tournament response
type TournamentResponse struct {
	ID                    string                     `json:"id"`
	Title                 string                     `json:"title"`
	Description           string                     `json:"description"`
	OrganizerID           string                     `json:"organizerId"`
	OrganizerName         string                     `json:"organizerName"`
	ClubID                string                     `json:"clubId,omitempty"`
	ClubName              string                     `json:"clubName,omitempty"`
	SportType             string                     `json:"sportType"`
	Discipline            string                     `json:"discipline"`
	Category              string                     `json:"category,omitempty"`
	Format                string                     `json:"format"`
	Schedule              ScheduleResponse           `json:"schedule"`
	Registration          RegistrationResponse       `json:"registration"`
	ScoringSystem         string                     `json:"scoringSystem"`
	ScoringConfig         ScoringConfigDTO           `json:"scoringConfig"`
	CompetitionIDs        []string                   `json:"competitionIds"`
	TotalCompetitions     int                        `json:"totalCompetitions"`
	CompletedRounds       int                        `json:"completedRounds"`
	RegisteredAthleteIDs  []string                   `json:"registeredAthleteIds,omitempty"`
	Status                string                     `json:"status"`
	IsLive                bool                       `json:"isLive"`
	IsPublic              bool                       `json:"isPublic"`
	IsFeatured            bool                       `json:"isFeatured"`
	StandingsID           string                     `json:"standingsId,omitempty"`
	IsResultsPublished    bool                       `json:"isResultsPublished"`
	ResultsPublishedAt    *time.Time                 `json:"resultsPublishedAt,omitempty"`
	Prizes                string                     `json:"prizes,omitempty"`
	Rules                 string                     `json:"rules,omitempty"`
	BannerUrl             string                     `json:"bannerUrl,omitempty"`
	PosterUrl             string                     `json:"posterUrl,omitempty"`
	ImageUrls             []string                   `json:"imageUrls,omitempty"`
	Tags                  []string                   `json:"tags,omitempty"`
	CreatedAt             time.Time                  `json:"createdAt"`
	UpdatedAt             time.Time                  `json:"updatedAt"`
}

// ScheduleResponse represents tournament schedule
type ScheduleResponse struct {
	StartDate time.Time `json:"startDate"`
	EndDate   time.Time `json:"endDate"`
	Season    string    `json:"season,omitempty"`
	Year      int       `json:"year"`
	TimeZone  string    `json:"timeZone,omitempty"`
	Venue     string    `json:"venue,omitempty"`
	Country   string    `json:"country,omitempty"`
}

// RegistrationResponse represents tournament registration info
type RegistrationResponse struct {
	MaxParticipants          int        `json:"maxParticipants"`
	CurrentParticipants      int        `json:"currentParticipants"`
	RegistrationDeadline     *time.Time `json:"registrationDeadline,omitempty"`
	RegistrationStatus       string     `json:"registrationStatus"`
	AllowLateRegistration    bool       `json:"allowLateRegistration"`
	RequiresApproval         bool       `json:"requiresApproval"`
	EntryFee                 *float64   `json:"entryFee,omitempty"`
	Currency                 string     `json:"currency,omitempty"`
	AllowIndividualRaceEntry bool       `json:"allowIndividualRaceEntry"`
}

// TournamentStandingResponse represents a tournament standing
type TournamentStandingResponse struct {
	ID                    string                  `json:"id"`
	TournamentID          string                  `json:"tournamentId"`
	AthleteID             string                  `json:"athleteId"`
	AthleteName           string                  `json:"athleteName"`
	AthleteNumber         *int                    `json:"athleteNumber,omitempty"`
	Position              int                     `json:"position"`
	PreviousPosition      int                     `json:"previousPosition"`
	PositionChange        int                     `json:"positionChange"`
	TotalPoints           float64                 `json:"totalPoints"`
	CountedPoints         float64                 `json:"countedPoints"`
	DroppedPoints         float64                 `json:"droppedPoints"`
	CompetitionsEntered   int                     `json:"competitionsEntered"`
	CompetitionsCompleted int                     `json:"competitionsCompleted"`
	CompetitionsRequired  int                     `json:"competitionsRequired"`
	Results               []CompetitionResultDTO  `json:"results"`
	Statistics            StatisticsDTO           `json:"statistics"`
	TieBreakerValue       float64                 `json:"tieBreakerValue"`
	IsQualified           bool                    `json:"isQualified"`
	IsEligible            bool                    `json:"isEligible"`
	IsDisqualified        bool                    `json:"isDisqualified"`
	CreatedAt             time.Time               `json:"createdAt"`
	UpdatedAt             time.Time               `json:"updatedAt"`
}

// CompetitionResultDTO represents a single competition result
type CompetitionResultDTO struct {
	CompetitionID   string   `json:"competitionId"`
	CompetitionName string   `json:"competitionName"`
	Date            time.Time `json:"date"`
	Position        int      `json:"position"`
	Points          float64  `json:"points"`
	TimeResult      *float64 `json:"timeResult,omitempty"`
	Score           *float64 `json:"score,omitempty"`
	DidNotFinish    bool     `json:"didNotFinish"`
	DidNotStart     bool     `json:"didNotStart"`
	Disqualified    bool     `json:"disqualified"`
	Notes           string   `json:"notes,omitempty"`
	IsDropped       bool     `json:"isDropped"`
}

// StatisticsDTO represents tournament statistics
type StatisticsDTO struct {
	Wins               int     `json:"wins"`
	Podiums            int     `json:"podiums"`
	TopFive            int     `json:"topFive"`
	TopTen             int     `json:"topTen"`
	DNFs               int     `json:"dnfs"`
	DNSs               int     `json:"dnss"`
	Disqualifications  int     `json:"disqualifications"`
	BestPosition       int     `json:"bestPosition"`
	WorstPosition      int     `json:"worstPosition"`
	AveragePosition    float64 `json:"averagePosition"`
	ConsecutivePodiums int     `json:"consecutivePodiums"`
	ParticipationRate  float64 `json:"participationRate"`
}

// TournamentRegistrationResponse represents a tournament registration
type TournamentRegistrationResponse struct {
	ID                     string                `json:"id"`
	TournamentID           string                `json:"tournamentId"`
	AthleteID              string                `json:"athleteId"`
	AthleteName            string                `json:"athleteName"`
	AthleteEmail           string                `json:"athleteEmail"`
	AthletePhone           string                `json:"athletePhone,omitempty"`
	RegistrationType       string                `json:"registrationType"`
	RegistrationDate       time.Time             `json:"registrationDate"`
	Status                 string                `json:"status"`
	SelectedCompetitionIDs []string              `json:"selectedCompetitionIds,omitempty"`
	RaceNumber             *int                  `json:"raceNumber,omitempty"`
	Team                   string                `json:"team,omitempty"`
	VehicleMake            string                `json:"vehicleMake,omitempty"`
	VehicleModel           string                `json:"vehicleModel,omitempty"`
	VehicleYear            *int                  `json:"vehicleYear,omitempty"`
	LicenseNumber          string                `json:"licenseNumber,omitempty"`
	LicenseFederation      string                `json:"licenseFederation,omitempty"`
	EmergencyContactName   string                `json:"emergencyContactName,omitempty"`
	EmergencyContactPhone  string                `json:"emergencyContactPhone,omitempty"`
	MedicalNotes           string                `json:"medicalNotes,omitempty"`
	Payment                PaymentInfoDTO        `json:"payment"`
	Approval               ApprovalInfoDTO       `json:"approval"`
	DocumentUrls           map[string]string     `json:"documentUrls,omitempty"`
	CompetitionsCompleted  int                   `json:"competitionsCompleted"`
	CompetitionsMissed     int                   `json:"competitionsMissed"`
	LastParticipation      *time.Time            `json:"lastParticipation,omitempty"`
	WithdrawnAt            *time.Time            `json:"withdrawnAt,omitempty"`
	WithdrawalReason       string                `json:"withdrawalReason,omitempty"`
	AdminNotes             string                `json:"adminNotes,omitempty"`
	CreatedAt              time.Time             `json:"createdAt"`
	UpdatedAt              time.Time             `json:"updatedAt"`
}

// PaymentInfoDTO represents payment information
type PaymentInfoDTO struct {
	Amount        float64    `json:"amount"`
	Currency      string     `json:"currency"`
	Status        string     `json:"status"`
	PaymentMethod string     `json:"paymentMethod,omitempty"`
	TransactionID string     `json:"transactionId,omitempty"`
	PaymentDate   *time.Time `json:"paymentDate,omitempty"`
	RefundDate    *time.Time `json:"refundDate,omitempty"`
	RefundAmount  *float64   `json:"refundAmount,omitempty"`
	RefundReason  string     `json:"refundReason,omitempty"`
}

// ApprovalInfoDTO represents approval information
type ApprovalInfoDTO struct {
	IsRequired      bool       `json:"isRequired"`
	Status          string     `json:"status"`
	ApprovedBy      string     `json:"approvedBy,omitempty"`
	ApprovedByName  string     `json:"approvedByName,omitempty"`
	ApprovedAt      *time.Time `json:"approvedAt,omitempty"`
	RejectedBy      string     `json:"rejectedBy,omitempty"`
	RejectedByName  string     `json:"rejectedByName,omitempty"`
	RejectedAt      *time.Time `json:"rejectedAt,omitempty"`
	RejectionReason string     `json:"rejectionReason,omitempty"`
	Notes           string     `json:"notes,omitempty"`
}

// ==================== MAPPER FUNCTIONS ====================

// ToTournamentResponse converts a tournament entity to response DTO
func ToTournamentResponse(t *entities.Tournament) *TournamentResponse {
	competitionIDs := make([]string, len(t.CompetitionIDs))
	for i, id := range t.CompetitionIDs {
		competitionIDs[i] = id.Hex()
	}

	registeredAthleteIDs := make([]string, len(t.RegisteredAthleteIDs))
	for i, id := range t.RegisteredAthleteIDs {
		registeredAthleteIDs[i] = id.Hex()
	}

	return &TournamentResponse{
		ID:                   t.ID.Hex(),
		Title:                t.Title,
		Description:          t.Description,
		OrganizerID:          t.OrganizerID.Hex(),
		OrganizerName:        t.OrganizerName,
		ClubID:               t.ClubID.Hex(),
		ClubName:             t.ClubName,
		SportType:            t.SportType,
		Discipline:           t.Discipline,
		Category:             t.Category,
		Format:               t.Format,
		Schedule: ScheduleResponse{
			StartDate: t.Schedule.StartDate,
			EndDate:   t.Schedule.EndDate,
			Season:    t.Schedule.Season,
			Year:      t.Schedule.Year,
			TimeZone:  t.Schedule.TimeZone,
			Venue:     t.Schedule.Venue,
			Country:   t.Schedule.Country,
		},
		Registration: RegistrationResponse{
			MaxParticipants:          t.Registration.MaxParticipants,
			CurrentParticipants:      t.Registration.CurrentParticipants,
			RegistrationDeadline:     t.Registration.RegistrationDeadline,
			RegistrationStatus:       t.Registration.RegistrationStatus,
			AllowLateRegistration:    t.Registration.AllowLateRegistration,
			RequiresApproval:         t.Registration.RequiresApproval,
			EntryFee:                 t.Registration.EntryFee,
			Currency:                 t.Registration.Currency,
			AllowIndividualRaceEntry: t.Registration.AllowIndividualRaceEntry,
		},
		ScoringSystem: t.ScoringSystem,
		ScoringConfig: ScoringConfigDTO{
			PointsMap:       t.ScoringConfig.PointsMap,
			CountBestOf:     t.ScoringConfig.CountBestOf,
			CustomFormula:   t.ScoringConfig.CustomFormula,
			TimeAggregation: t.ScoringConfig.TimeAggregation,
			TieBreaker:      t.ScoringConfig.TieBreaker,
			MinimumRaces:    t.ScoringConfig.MinimumRaces,
			DropWorst:       t.ScoringConfig.DropWorst,
			Multiplier:      t.ScoringConfig.Multiplier,
		},
		CompetitionIDs:       competitionIDs,
		TotalCompetitions:    t.TotalCompetitions,
		CompletedRounds:      t.CompletedRounds,
		RegisteredAthleteIDs: registeredAthleteIDs,
		Status:               t.Status,
		IsLive:               t.IsLive,
		IsPublic:             t.IsPublic,
		IsFeatured:           t.IsFeatured,
		StandingsID:          t.StandingsID,
		IsResultsPublished:   t.IsResultsPublished,
		ResultsPublishedAt:   t.ResultsPublishedAt,
		Prizes:               t.Prizes,
		Rules:                t.Rules,
		BannerUrl:            t.BannerUrl,
		PosterUrl:            t.PosterUrl,
		ImageUrls:            t.ImageUrls,
		Tags:                 t.Tags,
		CreatedAt:            t.CreatedAt,
		UpdatedAt:            t.UpdatedAt,
	}
}

// ToTournamentResponses converts multiple tournament entities to response DTOs
func ToTournamentResponses(tournaments []*entities.Tournament) []*TournamentResponse {
	responses := make([]*TournamentResponse, len(tournaments))
	for i, t := range tournaments {
		responses[i] = ToTournamentResponse(t)
	}
	return responses
}

// ToTournamentStandingResponse converts a standing entity to response DTO
func ToTournamentStandingResponse(s *entities.TournamentStanding) *TournamentStandingResponse {
	results := make([]CompetitionResultDTO, len(s.Results))
	for i, r := range s.Results {
		results[i] = CompetitionResultDTO{
			CompetitionID:   r.CompetitionID.Hex(),
			CompetitionName: r.CompetitionName,
			Date:            r.Date,
			Position:        r.Position,
			Points:          r.Points,
			TimeResult:      r.TimeResult,
			Score:           r.Score,
			DidNotFinish:    r.DidNotFinish,
			DidNotStart:     r.DidNotStart,
			Disqualified:    r.Disqualified,
			Notes:           r.Notes,
			IsDropped:       r.IsDropped,
		}
	}

	return &TournamentStandingResponse{
		ID:                    s.ID.Hex(),
		TournamentID:          s.TournamentID.Hex(),
		AthleteID:             s.AthleteID.Hex(),
		AthleteName:           s.AthleteName,
		AthleteNumber:         s.AthleteNumber,
		Position:              s.Position,
		PreviousPosition:      s.PreviousPosition,
		PositionChange:        s.PositionChange,
		TotalPoints:           s.TotalPoints,
		CountedPoints:         s.CountedPoints,
		DroppedPoints:         s.DroppedPoints,
		CompetitionsEntered:   s.CompetitionsEntered,
		CompetitionsCompleted: s.CompetitionsCompleted,
		CompetitionsRequired:  s.CompetitionsRequired,
		Results:               results,
		Statistics: StatisticsDTO{
			Wins:               s.Statistics.Wins,
			Podiums:            s.Statistics.Podiums,
			TopFive:            s.Statistics.TopFive,
			TopTen:             s.Statistics.TopTen,
			DNFs:               s.Statistics.DNFs,
			DNSs:               s.Statistics.DNSs,
			Disqualifications:  s.Statistics.Disqualifications,
			BestPosition:       s.Statistics.BestPosition,
			WorstPosition:      s.Statistics.WorstPosition,
			AveragePosition:    s.Statistics.AveragePosition,
			ConsecutivePodiums: s.Statistics.ConsecutivePodiums,
			ParticipationRate:  s.Statistics.ParticipationRate,
		},
		TieBreakerValue: s.TieBreakerValue,
		IsQualified:     s.IsQualified,
		IsEligible:      s.IsEligible,
		IsDisqualified:  s.IsDisqualified,
		CreatedAt:       s.CreatedAt,
		UpdatedAt:       s.UpdatedAt,
	}
}

// ToTournamentStandingResponses converts multiple standing entities to response DTOs
func ToTournamentStandingResponses(standings []*entities.TournamentStanding) []*TournamentStandingResponse {
	responses := make([]*TournamentStandingResponse, len(standings))
	for i, s := range standings {
		responses[i] = ToTournamentStandingResponse(s)
	}
	return responses
}

// ToTournamentRegistrationResponse converts a registration entity to response DTO
func ToTournamentRegistrationResponse(r *entities.TournamentRegistration) *TournamentRegistrationResponse {
	selectedCompetitionIDs := make([]string, len(r.SelectedCompetitionIDs))
	for i, id := range r.SelectedCompetitionIDs {
		selectedCompetitionIDs[i] = id.Hex()
	}

	approvalInfoDTO := ApprovalInfoDTO{
		IsRequired:      r.Approval.IsRequired,
		Status:          r.Approval.Status,
		ApprovedByName:  r.Approval.ApprovedByName,
		ApprovedAt:      r.Approval.ApprovedAt,
		RejectedByName:  r.Approval.RejectedByName,
		RejectedAt:      r.Approval.RejectedAt,
		RejectionReason: r.Approval.RejectionReason,
		Notes:           r.Approval.Notes,
	}

	if r.Approval.ApprovedBy != nil {
		approvalInfoDTO.ApprovedBy = r.Approval.ApprovedBy.Hex()
	}
	if r.Approval.RejectedBy != nil {
		approvalInfoDTO.RejectedBy = r.Approval.RejectedBy.Hex()
	}

	return &TournamentRegistrationResponse{
		ID:                     r.ID.Hex(),
		TournamentID:           r.TournamentID.Hex(),
		AthleteID:              r.AthleteID.Hex(),
		AthleteName:            r.AthleteName,
		AthleteEmail:           r.AthleteEmail,
		AthletePhone:           r.AthletePhone,
		RegistrationType:       r.RegistrationType,
		RegistrationDate:       r.RegistrationDate,
		Status:                 r.Status,
		SelectedCompetitionIDs: selectedCompetitionIDs,
		RaceNumber:             r.RaceNumber,
		Team:                   r.Team,
		VehicleMake:            r.VehicleMake,
		VehicleModel:           r.VehicleModel,
		VehicleYear:            r.VehicleYear,
		LicenseNumber:          r.LicenseNumber,
		LicenseFederation:      r.LicenseFederation,
		EmergencyContactName:   r.EmergencyContactName,
		EmergencyContactPhone:  r.EmergencyContactPhone,
		MedicalNotes:           r.MedicalNotes,
		Payment: PaymentInfoDTO{
			Amount:        r.Payment.Amount,
			Currency:      r.Payment.Currency,
			Status:        r.Payment.Status,
			PaymentMethod: r.Payment.PaymentMethod,
			TransactionID: r.Payment.TransactionID,
			PaymentDate:   r.Payment.PaymentDate,
			RefundDate:    r.Payment.RefundDate,
			RefundAmount:  r.Payment.RefundAmount,
			RefundReason:  r.Payment.RefundReason,
		},
		Approval:              approvalInfoDTO,
		DocumentUrls:          r.DocumentUrls,
		CompetitionsCompleted: r.CompetitionsCompleted,
		CompetitionsMissed:    r.CompetitionsMissed,
		LastParticipation:     r.LastParticipation,
		WithdrawnAt:           r.WithdrawnAt,
		WithdrawalReason:      r.WithdrawalReason,
		AdminNotes:            r.AdminNotes,
		CreatedAt:             r.CreatedAt,
		UpdatedAt:             r.UpdatedAt,
	}
}

// ToTournamentRegistrationResponses converts multiple registration entities to response DTOs
func ToTournamentRegistrationResponses(registrations []*entities.TournamentRegistration) []*TournamentRegistrationResponse {
	responses := make([]*TournamentRegistrationResponse, len(registrations))
	for i, r := range registrations {
		responses[i] = ToTournamentRegistrationResponse(r)
	}
	return responses
}

// TournamentListResponse represents a paginated list of tournaments
type TournamentListResponse struct {
	Tournaments []*TournamentResponse `json:"tournaments"`
	Total       int64                 `json:"total"`
	Page        int                   `json:"page"`
	Limit       int                   `json:"limit"`
}
