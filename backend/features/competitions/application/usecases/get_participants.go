package usecases

import (
	"context"

	"backend/features/competitions/domain/repositories"
	"backend/pkg/users"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ParticipantInfo represents participant information with user details
type ParticipantInfo struct {
	ID         string `json:"id"`
	UserID     string `json:"userId"`
	UserName   string `json:"userName"`
	FirstName  string `json:"firstName,omitempty"`
	LastName   string `json:"lastName,omitempty"`
	AvatarURL  string `json:"avatarUrl,omitempty"`
	ClubID     string `json:"clubId,omitempty"`
	ClubName   string `json:"clubName,omitempty"`
	IsApproved bool   `json:"isApproved"`
}

// GetParticipantsUseCase handles retrieving participants for a competition
type GetParticipantsUseCase struct {
	competitionRepo repositories.CompetitionRepository
	userClient      users.UserClient
}

// NewGetParticipantsUseCase creates a new GetParticipantsUseCase
func NewGetParticipantsUseCase(competitionRepo repositories.CompetitionRepository, userClient users.UserClient) *GetParticipantsUseCase {
	return &GetParticipantsUseCase{
		competitionRepo: competitionRepo,
		userClient:      userClient,
	}
}

// Execute retrieves participants for a competition with user details
func (uc *GetParticipantsUseCase) Execute(ctx context.Context, competitionID string, page, limit int) ([]ParticipantInfo, int64, error) {
	// Parse competition ID
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, 0, err
	}

	// Get competition
	competition, err := uc.competitionRepo.FindByID(ctx, compObjID)
	if err != nil {
		return nil, 0, err
	}

	// Get registered athlete IDs
	athleteIDs := competition.Registration.RegisteredAthleteIDs
	total := int64(len(athleteIDs))

	// Apply pagination
	start := (page - 1) * limit
	end := start + limit
	if start > len(athleteIDs) {
		return []ParticipantInfo{}, total, nil
	}
	if end > len(athleteIDs) {
		end = len(athleteIDs)
	}
	pagedIDs := athleteIDs[start:end]

	// Get user details for each participant
	participants := make([]ParticipantInfo, 0, len(pagedIDs))
	for _, athleteID := range pagedIDs {
		user, err := uc.userClient.GetUserBasicInfo(ctx, athleteID)
		if err != nil || user == nil {
			// If user not found, add with minimal info
			participants = append(participants, ParticipantInfo{
				ID:         athleteID.Hex(),
				UserID:     athleteID.Hex(),
				UserName:   "Unknown",
				IsApproved: true, // Registered means approved unless requiresApproval is set
			})
			continue
		}

		participant := ParticipantInfo{
			ID:         athleteID.Hex(),
			UserID:     athleteID.Hex(),
			UserName:   user.UserName,
			FirstName:  user.FirstName,
			LastName:   user.LastName,
			AvatarURL:  user.AvatarURL,
			IsApproved: true,
		}

		participants = append(participants, participant)
	}

	return participants, total, nil
}

// ExecuteCount returns only the count of participants
func (uc *GetParticipantsUseCase) ExecuteCount(ctx context.Context, competitionID string) (int64, error) {
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return 0, err
	}

	competition, err := uc.competitionRepo.FindByID(ctx, compObjID)
	if err != nil {
		return 0, err
	}

	return int64(len(competition.Registration.RegisteredAthleteIDs)), nil
}

// ParticipantCounts represents counts of participants by status
type ParticipantCounts struct {
	Total    int64 `json:"total"`
	Approved int64 `json:"approved"`
	Pending  int64 `json:"pending"`
	Rejected int64 `json:"rejected"`
}

// ExecuteCounts returns counts of participants grouped by status
func (uc *GetParticipantsUseCase) ExecuteCounts(ctx context.Context, competitionID string) (*ParticipantCounts, error) {
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, err
	}

	competition, err := uc.competitionRepo.FindByID(ctx, compObjID)
	if err != nil {
		return nil, err
	}

	counts := &ParticipantCounts{
		Total:    int64(len(competition.Registration.RegisteredAthleteIDs)),
		Approved: int64(len(competition.Registration.RegisteredAthleteIDs)),
		Pending:  0,
		Rejected: 0,
	}

	// If competition requires approval, participants in waitlist are pending
	if competition.Registration.RequiresApproval {
		counts.Pending = int64(len(competition.Registration.WaitlistAthleteIDs))
		counts.Total = counts.Approved + counts.Pending
	}

	return counts, nil
}

// ExecutePending retrieves pending participants (waitlist) with user details
func (uc *GetParticipantsUseCase) ExecutePending(ctx context.Context, competitionID string, page, limit int) ([]ParticipantInfo, int64, error) {
	compObjID, err := primitive.ObjectIDFromHex(competitionID)
	if err != nil {
		return nil, 0, err
	}

	competition, err := uc.competitionRepo.FindByID(ctx, compObjID)
	if err != nil {
		return nil, 0, err
	}

	// Get waitlist athlete IDs (pending approval)
	athleteIDs := competition.Registration.WaitlistAthleteIDs
	total := int64(len(athleteIDs))

	// Apply pagination
	start := (page - 1) * limit
	end := start + limit
	if start > len(athleteIDs) {
		return []ParticipantInfo{}, total, nil
	}
	if end > len(athleteIDs) {
		end = len(athleteIDs)
	}
	pagedIDs := athleteIDs[start:end]

	// Get user details for each pending participant
	participants := make([]ParticipantInfo, 0, len(pagedIDs))
	for _, athleteID := range pagedIDs {
		user, err := uc.userClient.GetUserBasicInfo(ctx, athleteID)
		if err != nil || user == nil {
			// If user not found, add with minimal info
			participants = append(participants, ParticipantInfo{
				ID:         athleteID.Hex(),
				UserID:     athleteID.Hex(),
				UserName:   "Unknown",
				IsApproved: false,
			})
			continue
		}

		participant := ParticipantInfo{
			ID:         athleteID.Hex(),
			UserID:     athleteID.Hex(),
			UserName:   user.UserName,
			FirstName:  user.FirstName,
			LastName:   user.LastName,
			AvatarURL:  user.AvatarURL,
			IsApproved: false, // Waitlist = pending approval
		}

		participants = append(participants, participant)
	}

	return participants, total, nil
}
