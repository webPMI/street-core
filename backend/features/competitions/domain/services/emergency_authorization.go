package services

import (
	"errors"

	"backend/features/competitions/domain/entities"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// EmergencyAuthorizationService handles authorization checks for emergency actions
// SECURITY: All emergency actions MUST be authorized before execution
type EmergencyAuthorizationService interface {
	// CanPerformEmergencyAction checks if a user can perform a specific emergency action
	CanPerformEmergencyAction(
		competition *entities.Competition,
		userID primitive.ObjectID,
		actionType string,
	) error

	// CanSendBroadcast checks if a user can send emergency broadcasts
	CanSendBroadcast(
		competition *entities.Competition,
		userID primitive.ObjectID,
		priority string,
	) error

	// CanRevertAction checks if a user can revert an emergency action
	CanRevertAction(
		competition *entities.Competition,
		userID primitive.ObjectID,
		action *entities.EmergencyAction,
	) error
}

// emergencyAuthService implements EmergencyAuthorizationService
type emergencyAuthService struct{}

// NewEmergencyAuthorizationService creates a new emergency authorization service
func NewEmergencyAuthorizationService() EmergencyAuthorizationService {
	return &emergencyAuthService{}
}

// CanPerformEmergencyAction checks if a user can perform a specific emergency action
//
// AUTHORIZATION MATRIX:
// - ORGANIZER: Can perform ALL emergency actions
// - HEAD_JUDGE: Can perform score-related actions (override, reset, swap)
// - JUDGE: Cannot perform emergency actions (must request via Head Judge)
// - SPEAKER: Cannot perform emergency actions (can only send broadcasts)
func (s *emergencyAuthService) CanPerformEmergencyAction(
	competition *entities.Competition,
	userID primitive.ObjectID,
	actionType string,
) error {
	// SECURITY RULE 1: Organizer can do anything
	if competition.IsOwner(userID) {
		return nil
	}

	// SECURITY RULE 2: Head Judge can perform scoring emergency actions
	if competition.IsHeadJudge(userID) {
		switch actionType {
		case entities.ActionResetAthleteScore,
			entities.ActionAdminOverrideScore,
			entities.ActionSwapAthleteScores:
			return nil

		case entities.ActionUpdateHeatOrder,
			entities.ActionRemoveAthleteFromHeat:
			// Head Judge can also manage heat order during emergencies
			return nil

		case entities.ActionEmergencyBroadcast:
			// Head Judge can send broadcasts
			return nil

		default:
			return errors.New("head judge not authorized for this action type")
		}
	}

	// SECURITY RULE 3: Regular judges cannot perform emergency actions
	if competition.IsJudge(userID) {
		return errors.New("regular judges must request emergency actions through head judge")
	}

	// SECURITY RULE 4: Unauthorized user
	return errors.New("user not authorized to perform emergency actions")
}

// CanSendBroadcast checks if a user can send emergency broadcasts
//
// AUTHORIZATION MATRIX:
// - ORGANIZER: Can send ALL priority broadcasts
// - HEAD_JUDGE: Can send INFO, WARNING, CRITICAL broadcasts
// - JUDGE: Can send INFO, WARNING broadcasts
// - SPEAKER: Can send INFO, WARNING broadcasts (via heat-specific check)
func (s *emergencyAuthService) CanSendBroadcast(
	competition *entities.Competition,
	userID primitive.ObjectID,
	priority string,
) error {
	// SECURITY RULE 1: Organizer can send all broadcasts
	if competition.IsOwner(userID) {
		return nil
	}

	// SECURITY RULE 2: Head Judge can send up to CRITICAL
	if competition.IsHeadJudge(userID) {
		switch priority {
		case entities.BroadcastPriorityInfo,
			entities.BroadcastPriorityWarning,
			entities.BroadcastPriorityCritical:
			return nil
		case entities.BroadcastPriorityEmergency:
			return errors.New("only organizer can send EMERGENCY priority broadcasts")
		default:
			return errors.New("invalid broadcast priority")
		}
	}

	// SECURITY RULE 3: Regular judges can send INFO and WARNING
	if competition.IsJudge(userID) {
		switch priority {
		case entities.BroadcastPriorityInfo,
			entities.BroadcastPriorityWarning:
			return nil
		case entities.BroadcastPriorityCritical,
			entities.BroadcastPriorityEmergency:
			return errors.New("judges can only send INFO and WARNING broadcasts")
		default:
			return errors.New("invalid broadcast priority")
		}
	}

	// SECURITY RULE 4: Speaker role is heat-specific
	// This check should be done at the handler level with heat context
	// For competition-level broadcasts, Speaker is not authorized
	return errors.New("user not authorized to send broadcasts")
}

// CanRevertAction checks if a user can revert an emergency action
//
// AUTHORIZATION RULES:
// - ORGANIZER: Can revert ALL actions
// - HEAD_JUDGE: Can revert actions they initiated or scoring actions
// - OTHERS: Cannot revert actions
func (s *emergencyAuthService) CanRevertAction(
	competition *entities.Competition,
	userID primitive.ObjectID,
	action *entities.EmergencyAction,
) error {
	// SECURITY RULE 1: Organizer can revert anything
	if competition.IsOwner(userID) {
		return nil
	}

	// SECURITY RULE 2: Head Judge can revert their own actions or scoring actions
	if competition.IsHeadJudge(userID) {
		// Can revert if they initiated it
		if action.InitiatedBy == userID {
			return nil
		}

		// Can revert scoring-related actions
		switch action.ActionType {
		case entities.ActionResetAthleteScore,
			entities.ActionAdminOverrideScore,
			entities.ActionSwapAthleteScores:
			return nil
		default:
			return errors.New("head judge can only revert scoring actions or their own actions")
		}
	}

	// SECURITY RULE 3: No one else can revert
	return errors.New("user not authorized to revert emergency actions")
}

// CanRequestScoreUnlock checks if a user can request a score unlock
// This is used by judges who need to modify their locked scores
func (s *emergencyAuthService) CanRequestScoreUnlock(
	competition *entities.Competition,
	userID primitive.ObjectID,
) error {
	// Only judges can request score unlock
	if competition.IsJudge(userID) || competition.IsHeadJudge(userID) {
		return nil
	}

	return errors.New("only judges can request score unlock")
}

// CanAuthorizeScoreUnlock checks if a user can authorize a score unlock request
// This is used by organizers/head judges to approve unlock requests
func (s *emergencyAuthService) CanAuthorizeScoreUnlock(
	competition *entities.Competition,
	userID primitive.ObjectID,
) error {
	// Only organizer or head judge can authorize
	if competition.IsOwner(userID) || competition.IsHeadJudge(userID) {
		return nil
	}

	return errors.New("only organizer or head judge can authorize score unlock")
}

// IsOrganizerOrHeadJudge is a helper method for quick checks
func (s *emergencyAuthService) IsOrganizerOrHeadJudge(
	competition *entities.Competition,
	userID primitive.ObjectID,
) bool {
	return competition.IsOwner(userID) || competition.IsHeadJudge(userID)
}
