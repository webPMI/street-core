package dto

import (
	"time"

	"backend/features/competitions/domain/entities"
)

// CreateCompetitionRequest represents the request to create a competition
type CreateCompetitionRequest struct {
	Title           string             `json:"title" binding:"required,min=3,max=255"`
	Description     string             `json:"description" binding:"required,min=10,max=2000"`
	EventID         string             `json:"eventId,omitempty"`
	ClubID          string             `json:"clubId,omitempty"`
	CompetitionType string             `json:"competitionType" binding:"required,oneof=individual team both"`
	Format          string             `json:"format" binding:"required,oneof=championship tournament single_race time_trial endurance knockout"`
	Discipline      string             `json:"discipline" binding:"required,max=50"`
	Category        string             `json:"category,omitempty" binding:"omitempty,max=50"`
	Schedule        ScheduleDTO        `json:"schedule" binding:"required"`
	Registration    RegistrationDTO    `json:"registration"`
	ScoringCriteria ScoringCriteriaDTO `json:"scoringCriteria" binding:"required"`
	RequiredJudges  int                `json:"requiredJudges" binding:"omitempty,gte=0,lte=20"`
	TotalRounds     int                `json:"totalRounds" binding:"omitempty,gte=1,lte=100"`
	Rules           string             `json:"rules,omitempty" binding:"omitempty,max=5000"`
	BannerUrl       string             `json:"bannerUrl,omitempty" binding:"omitempty,url|eq="`
	ImageUrls       []string           `json:"imageUrls,omitempty"`
	Tags            []string           `json:"tags,omitempty" binding:"omitempty,max=10,dive,max=30"`
}

// UpdateCompetitionRequest represents the request to update a competition
type UpdateCompetitionRequest struct {
	Title           string              `json:"title" binding:"omitempty,min=3,max=255"`
	Description     string              `json:"description" binding:"omitempty,min=10,max=2000"`
	CompetitionType string              `json:"competitionType" binding:"omitempty,oneof=individual team both"`
	Format          string              `json:"format,omitempty" binding:"omitempty,oneof=championship tournament single_race time_trial endurance knockout"`
	Discipline      string              `json:"discipline,omitempty" binding:"omitempty,max=50"`
	Category        string              `json:"category,omitempty" binding:"omitempty,max=50"`
	Schedule        *ScheduleDTO        `json:"schedule,omitempty"`
	Registration    *RegistrationDTO    `json:"registration,omitempty"`
	ScoringCriteria *ScoringCriteriaDTO `json:"scoringCriteria,omitempty"`
	RequiredJudges  *int                `json:"requiredJudges,omitempty" binding:"omitempty,gte=0,lte=20"`
	TotalRounds     *int                `json:"totalRounds,omitempty" binding:"omitempty,gte=1,lte=100"`
	Rules           *string             `json:"rules,omitempty" binding:"omitempty,max=5000"`
	BannerUrl       *string             `json:"bannerUrl,omitempty"`
	ImageUrls       []string            `json:"imageUrls,omitempty"`
	Tags            []string            `json:"tags,omitempty" binding:"omitempty,max=10,dive,max=30"`
}

// RegisterAthleteRequest represents the request to register an athlete
type RegisterAthleteRequest struct {
	AthleteID string `json:"athleteId" binding:"required"`
}

// SubmitScoreRequest represents the request to submit a score
type SubmitScoreRequest struct {
	AthleteID string  `json:"athleteId" binding:"required"`
	RoundID   string  `json:"roundId" binding:"required"`
	Score     float64 `json:"score" binding:"required,gte=0"`
}

// ScheduleDTO represents schedule data transfer object
type ScheduleDTO struct {
	StartDate time.Time `json:"startDate" binding:"required"`
	EndDate   time.Time `json:"endDate" binding:"required,gtfield=StartDate"`
	Venue     string    `json:"venue,omitempty" binding:"omitempty,max=200"`
	City      string    `json:"city,omitempty" binding:"omitempty,max=100"`
	Country   string    `json:"country,omitempty" binding:"omitempty,max=100"`
	Latitude  *float64  `json:"latitude,omitempty" binding:"omitempty,gte=-90,lte=90"`
	Longitude *float64  `json:"longitude,omitempty" binding:"omitempty,gte=-180,lte=180"`
	TimeZone  string    `json:"timeZone,omitempty" binding:"omitempty,max=50"`
}

// RegistrationDTO represents registration data transfer object
type RegistrationDTO struct {
	MaxParticipants      int        `json:"maxParticipants" binding:"omitempty,gte=1,lte=10000"`
	MinParticipants      int        `json:"minParticipants" binding:"omitempty,gte=1,ltefield=MaxParticipants"`
	RegistrationDeadline *time.Time `json:"registrationDeadline,omitempty"`
	RequiresApproval     bool       `json:"requiresApproval"`
	EntryFee             *float64   `json:"entryFee,omitempty" binding:"omitempty,gte=0"`
	Currency             string     `json:"currency,omitempty" binding:"omitempty,len=3"`
	// Registration type: "internal" or "external"
	Type string `json:"type" binding:"required,oneof=internal external"`
	// External registration URL (required when type is "external")
	ExternalRegistrationURL *string `json:"externalRegistrationUrl,omitempty" binding:"omitempty,url"`
	// External provider name (e.g., "eventbrite", "ticketmaster")
	ExternalProvider string `json:"externalProvider,omitempty" binding:"omitempty,max=100"`
}

// ScoringCriteriaDTO represents scoring criteria data transfer object
type ScoringCriteriaDTO struct {
	Type        string               `json:"type" binding:"required,oneof=points time average sum weighted_average"`
	MinScore    float64              `json:"minScore"`
	MaxScore    float64              `json:"maxScore" binding:"required,gt=0"`
	Criteria    []ScoreCriterionDTO  `json:"criteria,omitempty"`
	DropHighest bool                 `json:"dropHighest"`
	DropLowest  bool                 `json:"dropLowest"`
}

// ScoreCriterionDTO represents a single scoring criterion
type ScoreCriterionDTO struct {
	Name     string  `json:"name" binding:"required"`
	Weight   float64 `json:"weight" binding:"required,gte=0,lte=1"`
	MaxScore float64 `json:"maxScore" binding:"required,gt=0"`
}

// ToScheduleEntity converts ScheduleDTO to entities.Schedule
func (dto ScheduleDTO) ToScheduleEntity() entities.Schedule {
	return entities.Schedule{
		StartDate: dto.StartDate,
		EndDate:   dto.EndDate,
		Venue:     dto.Venue,
		City:      dto.City,
		Country:   dto.Country,
		Latitude:  dto.Latitude,
		Longitude: dto.Longitude,
		TimeZone:  dto.TimeZone,
	}
}

// ToRegistrationEntity converts RegistrationDTO to entities.Registration
func (dto RegistrationDTO) ToRegistrationEntity() entities.Registration {
	return entities.Registration{
		MaxParticipants:         dto.MaxParticipants,
		MinParticipants:         dto.MinParticipants,
		RegistrationDeadline:    dto.RegistrationDeadline,
		RequiresApproval:        dto.RequiresApproval,
		EntryFee:                dto.EntryFee,
		Currency:                dto.Currency,
		ParticipantStatus:       entities.ParticipantStatusOpen,
		Type:                    dto.Type,
		ExternalRegistrationURL: dto.ExternalRegistrationURL,
		ExternalProvider:        dto.ExternalProvider,
	}
}

// ToScoringCriteriaEntity converts ScoringCriteriaDTO to entities.ScoringCriteria
func (dto ScoringCriteriaDTO) ToScoringCriteriaEntity() entities.ScoringCriteria {
	criteria := make([]entities.ScoreCriterion, len(dto.Criteria))
	for i, c := range dto.Criteria {
		criteria[i] = entities.ScoreCriterion{
			Name:     c.Name,
			Weight:   c.Weight,
			MaxScore: c.MaxScore,
		}
	}

	return entities.ScoringCriteria{
		Type:        dto.Type,
		MinScore:    dto.MinScore,
		MaxScore:    dto.MaxScore,
		Criteria:    criteria,
		DropHighest: dto.DropHighest,
		DropLowest:  dto.DropLowest,
	}
}

// FromScheduleEntity converts entities.Schedule to ScheduleDTO
func FromScheduleEntity(schedule entities.Schedule) ScheduleDTO {
	return ScheduleDTO{
		StartDate: schedule.StartDate,
		EndDate:   schedule.EndDate,
		Venue:     schedule.Venue,
		City:      schedule.City,
		Country:   schedule.Country,
		Latitude:  schedule.Latitude,
		Longitude: schedule.Longitude,
		TimeZone:  schedule.TimeZone,
	}
}

// FromRegistrationEntity converts entities.Registration to RegistrationDTO
func FromRegistrationEntity(reg entities.Registration) RegistrationDTO {
	return RegistrationDTO{
		MaxParticipants:         reg.MaxParticipants,
		MinParticipants:         reg.MinParticipants,
		RegistrationDeadline:    reg.RegistrationDeadline,
		RequiresApproval:        reg.RequiresApproval,
		EntryFee:                reg.EntryFee,
		Currency:                reg.Currency,
		Type:                    reg.Type,
		ExternalRegistrationURL: reg.ExternalRegistrationURL,
		ExternalProvider:        reg.ExternalProvider,
	}
}
