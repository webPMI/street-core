package usecases

import (
	"context"

	"backend/features/competitions/domain/entities"
	"backend/features/competitions/domain/repositories"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ListJudgeInvitationsUseCase handles listing judge invitations
type ListJudgeInvitationsUseCase struct {
	invitationRepo repositories.JudgeInvitationRepository
}

// NewListJudgeInvitationsUseCase creates a new ListJudgeInvitationsUseCase
func NewListJudgeInvitationsUseCase(invitationRepo repositories.JudgeInvitationRepository) *ListJudgeInvitationsUseCase {
	return &ListJudgeInvitationsUseCase{
		invitationRepo: invitationRepo,
	}
}

// ExecuteByCompetition lists invitations for a competition
func (uc *ListJudgeInvitationsUseCase) ExecuteByCompetition(ctx context.Context, competitionID string, status string, page, limit int) ([]*entities.JudgeInvitation, int64, error) {
	// Parse competition ID
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, 0, err
	}

	// Apply defaults
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}

	return uc.invitationRepo.FindByCompetitionID(ctx, compObjID, status, page, limit)
}

// ExecuteByUser lists invitations for a user (my invitations)
func (uc *ListJudgeInvitationsUseCase) ExecuteByUser(ctx context.Context, userID primitive.ObjectID, status string, page, limit int) ([]*entities.JudgeInvitation, int64, error) {
	// Apply defaults
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}

	return uc.invitationRepo.FindByUserID(ctx, userID, status, page, limit)
}
