package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CancelJudgeInvitationUseCase handles cancelling a judge invitation
type CancelJudgeInvitationUseCase struct {
	invitationRepo repositories.JudgeInvitationRepository
}

// NewCancelJudgeInvitationUseCase creates a new CancelJudgeInvitationUseCase
func NewCancelJudgeInvitationUseCase(invitationRepo repositories.JudgeInvitationRepository) *CancelJudgeInvitationUseCase {
	return &CancelJudgeInvitationUseCase{
		invitationRepo: invitationRepo,
	}
}

// Execute cancels (deletes) a pending invitation
func (uc *CancelJudgeInvitationUseCase) Execute(ctx context.Context, invitationID string, cancelledByID primitive.ObjectID) error {
	// Parse invitation ID
	invObjID, err := primitive.ObjectIDFromHex(invitationID)
	if err != nil {
		return err
	}

	// Get invitation
	invitation, err := uc.invitationRepo.FindByID(ctx, invObjID)
	if err != nil {
		return err
	}

	// Only pending invitations can be cancelled
	if invitation.Status != entities.InvitationStatusPending {
		return entities.ErrInvitationNotPending
	}

	// Delete the invitation
	return uc.invitationRepo.Delete(ctx, invObjID)
}
