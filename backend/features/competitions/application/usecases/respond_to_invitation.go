package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// RespondToInvitationUseCase handles responding to a judge invitation
type RespondToInvitationUseCase struct {
	invitationRepo  repositories.JudgeInvitationRepository
	competitionRepo repositories.CompetitionRepository
}

// NewRespondToInvitationUseCase creates a new RespondToInvitationUseCase
func NewRespondToInvitationUseCase(
	invitationRepo repositories.JudgeInvitationRepository,
	competitionRepo repositories.CompetitionRepository,
) *RespondToInvitationUseCase {
	return &RespondToInvitationUseCase{
		invitationRepo:  invitationRepo,
		competitionRepo: competitionRepo,
	}
}

// Execute responds to an invitation (accept or decline)
func (uc *RespondToInvitationUseCase) Execute(
	ctx context.Context,
	invitationID string,
	userID primitive.ObjectID,
	accept bool,
	response string,
) (*entities.JudgeInvitation, error) {
	// Parse invitation ID
	invObjID, err := primitive.ObjectIDFromHex(invitationID)
	if err != nil {
		return nil, err
	}

	// Get invitation
	invitation, err := uc.invitationRepo.FindByID(ctx, invObjID)
	if err != nil {
		return nil, err
	}

	// Verify the user is the invited user
	if invitation.InvitedUserID != userID {
		return nil, entities.ErrInvitationNotFound
	}

	// Accept or decline
	if accept {
		if err := invitation.Accept(response); err != nil {
			return nil, err
		}

		// Add user as judge to competition
		if err := uc.competitionRepo.AddJudge(ctx, invitation.CompetitionID, userID); err != nil {
			return nil, err
		}
	} else {
		if err := invitation.Decline(response); err != nil {
			return nil, err
		}
	}

	// Save updated invitation
	if err := uc.invitationRepo.Update(ctx, invitation); err != nil {
		return nil, err
	}

	return invitation, nil
}
