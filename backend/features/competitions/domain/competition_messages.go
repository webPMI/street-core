package domain

import "backend/models"

// ============================================================================
// COMPETITION MODULE MESSAGES
// ============================================================================
// Este archivo extiende models/messages.go con claves específicas del módulo

// Re-export de claves centrales para conveniencia
const (
	// Success messages
	CompetitionCreated      = models.CompetitionCreatedSuccessfully
	CompetitionUpdated      = models.CompetitionUpdatedSuccessfully
	CompetitionDeleted      = models.CompetitionDeletedSuccessfully
	CompetitionStarted      = models.CompetitionStartedSuccessfully
	CompetitionEnded        = models.CompetitionEndedSuccessfully
	CompetitionRegistered   = models.CompetitionRegisteredSuccessfully
	CompetitionUnregistered = models.CompetitionUnregisteredSuccessfully
	ScoreSubmitted          = models.ScoreSubmittedSuccessfully
	ScoreUpdated            = models.ScoreUpdatedSuccessfully
	ResultsPublished        = models.ResultsPublishedSuccessfully
	CategoryCreated         = models.CategoryCreatedSuccessfully
	CategoryUpdated         = models.CategoryUpdatedSuccessfully
	CategoryDeleted         = models.CategoryDeletedSuccessfully
	ParticipantAdded        = models.ParticipantAddedSuccessfully
	ParticipantRemoved      = models.ParticipantRemovedSuccessfully
	JudgeInvited            = models.JudgeInvitedSuccessfully
	InvitationAccepted      = models.InvitationAcceptedSuccessfully
	InvitationRejected      = models.InvitationRejectedSuccessfully
	InvitationCancelled     = models.InvitationCancelledSuccessfully

	// Error messages
	CompetitionNotFound    = models.CompetitionNotFound
	CategoryNotFound       = models.CategoryNotFound
	InvitationNotFound     = models.InvitationNotFound
	ScoreNotFound          = models.ScoreNotFound
	AlreadyRegistered      = models.AlreadyRegistered
	RegistrationClosed     = models.RegistrationClosed
	MaxParticipantsReached = models.MaxParticipantsReached
	MaxJudgesReached       = models.MaxJudgesReached
	InvalidStatus          = models.InvalidStatus
	InvitationExpired      = models.InvitationExpired
	AlreadyInvited         = models.AlreadyInvited
	AlreadyJudge           = models.AlreadyJudge
	DuplicateScore         = models.DuplicateScore
	NotAuthorizedJudge     = models.NotAuthorizedJudge

	// Emergency operations
	EmergencyScoreReset    = models.EmergencyScoreResetSuccessfully
	EmergencyScoreOverride = models.EmergencyScoreOverrideSuccessfully
	EmergencyScoresSwapped = models.EmergencyScoresSwappedSuccessfully
)

// Claves específicas del módulo Competition
const (
	// Heat management
	HeatStarted              = "competition.heat.started"
	HeatEnded                = "competition.heat.ended"
	HeatNotFound             = "competition.heat.not.found"
	HeatAlreadyStarted       = "competition.heat.already.started"
	HeatAlreadyEnded         = "competition.heat.already.ended"
	InvalidHeatConfiguration = "competition.heat.invalid.configuration"
	HeatOrderInvalid         = "competition.heat.order.invalid"

	// Scoring
	ScoreValidationFailed   = "competition.score.validation.failed"
	ScoreOutOfRange         = "competition.score.out.of.range"
	JudgeAlreadyScored      = "competition.judge.already.scored"
	ScoreBelowMinimum       = "competition.score.below.minimum"
	ScoreAboveMaximum       = "competition.score.above.maximum"
	InvalidCriteriaScore    = "competition.score.invalid.criteria"
	MissingRequiredCriteria = "competition.score.missing.criteria"
	ScoreSubmissionDeadline = "competition.score.submission.deadline"
	ScoreModificationDenied = "competition.score.modification.denied"
	ScoreDeleteDenied       = "competition.score.delete.denied"

	// Leaderboard
	LeaderboardUpdated          = "competition.leaderboard.updated"
	LeaderboardGenerationFailed = "competition.leaderboard.generation.failed"
	LeaderboardNotAvailable     = "competition.leaderboard.not.available"
	LeaderboardRecalculated     = "competition.leaderboard.recalculated"

	// Tournament
	TournamentCreated          = "competition.tournament.created"
	TournamentUpdated          = "competition.tournament.updated"
	TournamentDeleted          = "competition.tournament.deleted"
	TournamentNotFound         = "competition.tournament.not.found"
	TournamentBracketGenerated = "competition.tournament.bracket.generated"
	TournamentRoundAdvanced    = "competition.tournament.round.advanced"

	// Validation
	InvalidCompetitionDates  = "competition.validation.invalid.dates"
	InvalidRegistrationDates = "competition.validation.invalid.registration.dates"
	InvalidParticipantCount  = "competition.validation.invalid.participant.count"
	InvalidJudgeCount        = "competition.validation.invalid.judge.count"
	InvalidCategoryConfig    = "competition.validation.invalid.category.config"
	MissingRequiredFields    = "competition.validation.missing.fields"

	// Status transitions
	CannotStartCompetition    = "competition.status.cannot.start"
	CannotEndCompetition      = "competition.status.cannot.end"
	CannotCancelCompetition   = "competition.status.cannot.cancel"
	CannotPostponeCompetition = "competition.status.cannot.postpone"
	InvalidStatusTransition   = "competition.status.invalid.transition"
)
