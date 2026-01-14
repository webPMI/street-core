package errors

import "errors"

// Domain errors for competitions
var (
	// Not Found Errors
	ErrCompetitionNotFound = errors.New("competition not found")
	ErrRoundNotFound       = errors.New("round not found")
	ErrParticipantNotFound = errors.New("participant not found")
	ErrLeaderboardNotFound = errors.New("leaderboard not found")

	// Registration Errors
	ErrRegistrationClosed    = errors.New("registration is closed")
	ErrAlreadyRegistered     = errors.New("athlete already registered")
	ErrNotRegistered         = errors.New("athlete not registered")
	ErrMaxParticipantsReached = errors.New("maximum participants reached")
	ErrRegistrationNotOpen   = errors.New("registration is not open")

	// Authorization Errors
	ErrUnauthorized        = errors.New("unauthorized access")
	ErrNotOwner            = errors.New("only competition owner can perform this action")
	ErrNotJudge            = errors.New("only assigned judges can perform this action")
	ErrInsufficientPermissions = errors.New("insufficient permissions")

	// Business Logic Errors
	ErrInvalidInput        = errors.New("invalid input data")
	ErrInvalidStatus       = errors.New("invalid competition status for this operation")
	ErrAlreadyJudge        = errors.New("user is already assigned as judge")
	ErrCannotSubmitScore   = errors.New("cannot submit scores at this time")
	ErrCompetitionStarted  = errors.New("cannot modify competition after it has started")
	ErrResultsNotPublished = errors.New("results are not published yet")

	// Concurrency Errors (HTTP 409 Conflict)
	ErrHeatAlreadyClosed       = errors.New("heat is already closed for scoring")
	ErrHeatNotActive           = errors.New("heat is not active for scoring")
	ErrScoreAlreadyReset       = errors.New("score was already reset by organizer")
	ErrScoreAlreadySubmitted   = errors.New("score was already submitted")
	ErrConcurrentModification  = errors.New("resource was modified by another user")
	ErrHeatModified            = errors.New("heat was modified during operation")
	ErrAthleteNotInHeat        = errors.New("athlete is not assigned to this heat")

	// Resource Gone Errors (HTTP 410 Gone)
	ErrHeatDeleted   = errors.New("heat has been deleted")
	ErrScoreDeleted  = errors.New("score has been deleted")

	// Database Errors
	ErrDatabaseOperation = errors.New("database operation failed")
	ErrDuplicateEntry    = errors.New("duplicate entry")

	// Registration Type Errors
	ErrInvalidRegistrationType   = errors.New("registration type must be 'internal' or 'external'")
	ErrExternalRegistrationURLRequired = errors.New("external registration URL is required when type is 'external'")
	ErrInvalidExternalURL        = errors.New("external registration URL must use HTTPS protocol")
	ErrUnsupportedExternalProvider = errors.New("external registration provider is not supported")
)
