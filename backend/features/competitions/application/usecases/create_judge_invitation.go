package usecases

import (
	"context"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"
	"backend/pkg/users"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// CreateJudgeInvitationUseCase handles creating a new judge invitation
type CreateJudgeInvitationUseCase struct {
	invitationRepo  repositories.JudgeInvitationRepository
	competitionRepo repositories.CompetitionRepository
	userClient      users.UserClient
}

// NewCreateJudgeInvitationUseCase creates a new CreateJudgeInvitationUseCase
func NewCreateJudgeInvitationUseCase(
	invitationRepo repositories.JudgeInvitationRepository,
	competitionRepo repositories.CompetitionRepository,
	userClient users.UserClient,
) *CreateJudgeInvitationUseCase {
	return &CreateJudgeInvitationUseCase{
		invitationRepo:  invitationRepo,
		competitionRepo: competitionRepo,
		userClient:      userClient,
	}
}

// Execute creates a new judge invitation
func (uc *CreateJudgeInvitationUseCase) Execute(
	ctx context.Context,
	competitionID string,
	req dto.CreateJudgeInvitationRequest,
	invitedByID primitive.ObjectID,
) (*entities.JudgeInvitation, error) {
	// Parse IDs
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, err
	}
	userObjID, err := primitive.ObjectIDFromHex(req.UserID)
	if err != nil {
		return nil, err
	}

	// Verify competition exists
	_, err = uc.competitionRepo.FindByID(ctx, compObjID)
	if err != nil {
		return nil, err
	}

	// Check if user already has a pending invitation
	existingInvitation, err := uc.invitationRepo.FindPendingByCompetitionAndUser(ctx, compObjID, userObjID)
	if err == nil && existingInvitation != nil {
		return nil, entities.ErrAlreadyInvited
	}

	// Get user info for invitedBy
	inviter, err := uc.userClient.GetUserBasicInfo(ctx, invitedByID)
	inviterName := "Unknown"
	if err == nil && inviter != nil {
		inviterName = inviter.FirstName + " " + inviter.LastName
	}

	// Get user info for invitedUser
	invitee, err := uc.userClient.GetUserBasicInfo(ctx, userObjID)
	inviteeName := "Unknown"
	if err == nil && invitee != nil {
		inviteeName = invitee.FirstName + " " + invitee.LastName
	}

	// Create invitation
	invitation := entities.NewJudgeInvitation(compObjID, userObjID, invitedByID, inviteeName, inviterName)
	invitation.Message = req.Message

	// Set custom expiry if provided
	if req.ExpiresAt != nil {
		invitation.ExpiresAt = req.ExpiresAt
	}

	// Set category if provided
	if req.CategoryID != "" {
		catObjID, err := primitive.ObjectIDFromHex(req.CategoryID)
		if err == nil {
			invitation.CategoryID = catObjID
		}
	}

	// Save invitation
	if err := uc.invitationRepo.Save(ctx, invitation); err != nil {
		return nil, err
	}

	return invitation, nil
}
