package usecases

import (
	"context"
	"errors"
	"testing"
	"time"

	"backend/features/competitions/application/dto"
	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================================
// TEST HELPERS
// ============================================================================

func createTestCompetitionWithOrganizer(organizerID primitive.ObjectID) *entities.Competition {
	startDate := time.Now().Add(24 * time.Hour)
	endDate := startDate.Add(5 * time.Hour)

	return &entities.Competition{
		ID:              primitive.NewObjectID(),
		Title:           "Test Competition",
		Description:     "A test competition description",
		OrganizerID:     organizerID,
		CompetitionType: "individual",
		Format:          "single_round",
		Discipline:      "skateboarding",
		Category:        "amateur",
		Schedule: entities.Schedule{
			StartDate: startDate,
			EndDate:   endDate,
			Venue:     "Test Venue",
			City:      "Test City",
			Country:   "Spain",
		},
		Registration: entities.Registration{
			MaxParticipants:   50,
			MinParticipants:   5,
			ParticipantStatus: "open",
		},
		ScoringCriteria: entities.ScoringCriteria{
			Type:     "points",
			MinScore: 0,
			MaxScore: 100,
		},
		RequiredJudges: 3,
		TotalRounds:    1,
		Status:         "upcoming",
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}
}

// ============================================================================
// DELETE COMPETITION TESTS
// ============================================================================

func TestDeleteCompetition(t *testing.T) {
	t.Run("success - admin deletes competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		adminID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID
		competition.Status = "upcoming"

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Delete", mock.Anything, competitionID).Return(nil)

		err := useCase.Execute(context.Background(), competitionID.Hex(), adminID, "admin")

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - owner deletes upcoming competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID
		competition.Status = "upcoming"

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Delete", mock.Anything, competitionID).Return(nil)

		err := useCase.Execute(context.Background(), competitionID.Hex(), organizerID, "organizer")

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - admin deletes started competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		adminID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Delete", mock.Anything, competitionID).Return(nil)

		err := useCase.Execute(context.Background(), competitionID.Hex(), adminID, "admin")

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID format", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		userID := primitive.NewObjectID()

		err := useCase.Execute(context.Background(), "invalid-id", userID, "admin")

		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)
		mockRepo.AssertNotCalled(t, "FindByID")
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		userID := primitive.NewObjectID()

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(nil, errors.New("not found"))

		err := useCase.Execute(context.Background(), competitionID.Hex(), userID, "admin")

		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - not owner and not admin", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		otherUserID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)

		err := useCase.Execute(context.Background(), competitionID.Hex(), otherUserID, "user")

		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrNotOwner)
		mockRepo.AssertNotCalled(t, "Delete")
	})

	t.Run("failure - owner cannot delete started competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)

		err := useCase.Execute(context.Background(), competitionID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionStarted)
		mockRepo.AssertNotCalled(t, "Delete")
	})

	t.Run("failure - database error on delete", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewDeleteCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Delete", mock.Anything, competitionID).Return(errors.New("db error"))

		err := useCase.Execute(context.Background(), competitionID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
		mockRepo.AssertExpectations(t)
	})
}

// ============================================================================
// GET COMPETITION TESTS
// ============================================================================

func TestGetCompetition(t *testing.T) {
	t.Run("success - get competition by ID", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewGetCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competitionID.Hex())

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, competitionID.Hex(), result.ID)
		assert.Equal(t, competition.Title, result.Title)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid ID format", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewGetCompetitionUseCase(mockRepo)

		result, err := useCase.Execute(context.Background(), "invalid-id")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)
		mockRepo.AssertNotCalled(t, "FindByID")
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewGetCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(nil, errors.New("not found"))

		result, err := useCase.Execute(context.Background(), competitionID.Hex())

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)
		mockRepo.AssertExpectations(t)
	})
}

// ============================================================================
// UPDATE COMPETITION TESTS
// ============================================================================

func TestUpdateCompetition(t *testing.T) {
	t.Run("success - admin updates competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		adminID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID

		updateReq := dto.UpdateCompetitionRequest{
			Title:       "Updated Title",
			Description: "Updated description for the competition",
		}

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), updateReq, adminID, "admin")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, "Updated Title", result.Title)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - owner updates upcoming competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID
		competition.Status = "upcoming"

		updateReq := dto.UpdateCompetitionRequest{
			Title: "Owner Updated Title",
		}

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), updateReq, organizerID, "organizer")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - admin updates started competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		adminID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID
		competition.Status = "live"

		updateReq := dto.UpdateCompetitionRequest{
			Title: "Admin Updated Live Competition",
		}

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), updateReq, adminID, "admin")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		updateReq := dto.UpdateCompetitionRequest{
			Title: "Test",
		}

		result, err := useCase.Execute(context.Background(), "invalid-id", updateReq, primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(nil, errors.New("not found"))

		updateReq := dto.UpdateCompetitionRequest{
			Title: "Test",
		}

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), updateReq, primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)
	})

	t.Run("failure - not owner and not admin", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		otherUserID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)

		updateReq := dto.UpdateCompetitionRequest{
			Title: "Test",
		}

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), updateReq, otherUserID, "user")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrNotOwner)
	})

	t.Run("failure - owner cannot update started competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)

		updateReq := dto.UpdateCompetitionRequest{
			Title: "Test",
		}

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), updateReq, organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionStarted)
	})

	t.Run("failure - database error on update", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewUpdateCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()

		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.ID = competitionID

		mockRepo.On("FindByID", mock.Anything, competitionID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(errors.New("db error"))

		updateReq := dto.UpdateCompetitionRequest{
			Title: "Test Title",
		}

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), updateReq, organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
	})
}

// ============================================================================
// LIST COMPETITIONS TESTS
// ============================================================================

func TestListCompetitions(t *testing.T) {
	t.Run("success - list competitions with pagination", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competitions := []*entities.Competition{
			createTestCompetitionWithOrganizer(organizerID),
			createTestCompetitionWithOrganizer(organizerID),
		}

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return(competitions, int64(2), nil)

		results, total, err := useCase.Execute(context.Background(), 1, 20, nil)

		assert.NoError(t, err)
		assert.Len(t, results, 2)
		assert.Equal(t, int64(2), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - normalizes invalid page", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		// Negative page should be normalized to 1
		results, total, err := useCase.Execute(context.Background(), -5, 20, nil)

		assert.NoError(t, err)
		assert.Len(t, results, 0)
		assert.Equal(t, int64(0), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - normalizes invalid limit", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		// Limit 0 should be normalized to 20
		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		results, _, err := useCase.Execute(context.Background(), 1, 0, nil)

		assert.NoError(t, err)
		assert.Len(t, results, 0)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - caps limit at 100", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		// Limit > 100 should be capped to 100
		mockRepo.On("FindAll", mock.Anything, 1, 100, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		results, _, err := useCase.Execute(context.Background(), 1, 500, nil)

		assert.NoError(t, err)
		assert.Len(t, results, 0)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - database error", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), errors.New("db error"))

		results, total, err := useCase.Execute(context.Background(), 1, 20, nil)

		assert.Error(t, err)
		assert.Nil(t, results)
		assert.Equal(t, int64(0), total)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
	})
}

func TestListCompetitions_ExecuteUpcoming(t *testing.T) {
	t.Run("success - list upcoming competitions", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"

		mockRepo.On("FindUpcoming", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{competition}, int64(1), nil)

		results, total, err := useCase.ExecuteUpcoming(context.Background(), 1, 20, nil)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - normalizes pagination params", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		mockRepo.On("FindUpcoming", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		// Invalid params should be normalized
		_, _, err := useCase.ExecuteUpcoming(context.Background(), -1, -5, nil)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - database error", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		mockRepo.On("FindUpcoming", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), errors.New("db error"))

		results, total, err := useCase.ExecuteUpcoming(context.Background(), 1, 20, nil)

		assert.Error(t, err)
		assert.Nil(t, results)
		assert.Equal(t, int64(0), total)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
	})
}

func TestListCompetitions_ExecuteLive(t *testing.T) {
	t.Run("success - list live competitions", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "live"

		mockRepo.On("FindLive", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{competition}, int64(1), nil)

		results, total, err := useCase.ExecuteLive(context.Background(), 1, 20, nil)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - normalizes pagination params", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		mockRepo.On("FindLive", mock.Anything, 1, 100, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		// Limit > 100 should be capped
		_, _, err := useCase.ExecuteLive(context.Background(), 1, 200, nil)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - database error", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewListCompetitionsUseCase(mockRepo)

		mockRepo.On("FindLive", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), errors.New("db error"))

		results, total, err := useCase.ExecuteLive(context.Background(), 1, 20, nil)

		assert.Error(t, err)
		assert.Nil(t, results)
		assert.Equal(t, int64(0), total)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
	})
}

// ============================================================================
// GET MY COMPETITIONS TESTS
// ============================================================================

func TestGetMyCompetitions(t *testing.T) {
	t.Run("success - get competitions as athlete", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewGetMyCompetitionsUseCase(mockRepo)

		userID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)

		mockRepo.On("FindByAthleteID", mock.Anything, userID, 1, 10).
			Return([]*entities.Competition{competition}, int64(1), nil)

		results, total, err := useCase.Execute(context.Background(), userID, 1, 10)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - get competitions as organizer", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewGetMyCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)

		mockRepo.On("FindByOrganizerID", mock.Anything, organizerID, 1, 10).
			Return([]*entities.Competition{competition}, int64(1), nil)

		results, total, err := useCase.ExecuteAsOrganizer(context.Background(), organizerID, 1, 10)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - get competitions as judge", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewGetMyCompetitionsUseCase(mockRepo)

		userID := primitive.NewObjectID()
		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)

		mockRepo.On("FindAll", mock.Anything, 1, 10, mock.Anything).
			Return([]*entities.Competition{competition}, int64(1), nil)

		results, total, err := useCase.ExecuteAsJudge(context.Background(), userID, 1, 10)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})
}

// ============================================================================
// SEARCH COMPETITIONS TESTS
// ============================================================================

func TestSearchCompetitions(t *testing.T) {
	t.Run("success - search with filters", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{competition}, int64(1), nil)

		filters := SearchFilters{
			Query:      "skateboarding",
			Discipline: "skateboarding",
			Status:     "upcoming",
		}

		results, total, err := useCase.Execute(context.Background(), filters, 1, 20)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - normalizes pagination", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		filters := SearchFilters{}
		_, _, err := useCase.Execute(context.Background(), filters, -1, 0)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - caps limit at 100", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 100, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		filters := SearchFilters{}
		_, _, err := useCase.Execute(context.Background(), filters, 1, 500)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - search with date filters", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{competition}, int64(1), nil)

		now := time.Now()
		tomorrow := now.Add(24 * time.Hour)
		filters := SearchFilters{
			DateFrom: &now,
			DateTo:   &tomorrow,
		}

		results, total, err := useCase.Execute(context.Background(), filters, 1, 20)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - database error", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), errors.New("db error"))

		filters := SearchFilters{}
		results, total, err := useCase.Execute(context.Background(), filters, 1, 20)

		assert.Error(t, err)
		assert.Nil(t, results)
		assert.Equal(t, int64(0), total)
	})
}

func TestSearchCompetitions_ExecuteFeatured(t *testing.T) {
	t.Run("success - get featured competitions", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)

		mockRepo.On("FindAll", mock.Anything, 1, 10, mock.Anything).
			Return([]*entities.Competition{competition}, int64(1), nil)

		results, err := useCase.ExecuteFeatured(context.Background(), 10)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - normalizes limit", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 10, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		// Negative limit should be normalized to 10
		_, err := useCase.ExecuteFeatured(context.Background(), -5)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - caps limit at 50", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 50, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		_, err := useCase.ExecuteFeatured(context.Background(), 100)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - database error", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 10, mock.Anything).
			Return([]*entities.Competition{}, int64(0), errors.New("db error"))

		results, err := useCase.ExecuteFeatured(context.Background(), 10)

		assert.Error(t, err)
		assert.Nil(t, results)
	})
}

func TestSearchCompetitions_ExecuteNearby(t *testing.T) {
	t.Run("success - get nearby competitions", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{competition}, int64(1), nil)

		results, total, err := useCase.ExecuteNearby(context.Background(), "Spain", "Barcelona", 1, 20)

		assert.NoError(t, err)
		assert.Len(t, results, 1)
		assert.Equal(t, int64(1), total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - normalizes pagination", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), nil)

		_, _, err := useCase.ExecuteNearby(context.Background(), "Spain", "", -1, 0)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - database error", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewSearchCompetitionsUseCase(mockRepo)

		mockRepo.On("FindAll", mock.Anything, 1, 20, mock.Anything).
			Return([]*entities.Competition{}, int64(0), errors.New("db error"))

		results, total, err := useCase.ExecuteNearby(context.Background(), "Spain", "Barcelona", 1, 20)

		assert.Error(t, err)
		assert.Nil(t, results)
		assert.Equal(t, int64(0), total)
	})
}

// ============================================================================
// START COMPETITION TESTS
// ============================================================================

func TestStartCompetition(t *testing.T) {
	t.Run("success - owner starts competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"
		competition.Registration.MinParticipants = 5
		competition.Registration.CurrentParticipants = 10

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, "live", result.Status)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - admin starts competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		adminID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"
		competition.Registration.MinParticipants = 5
		competition.Registration.CurrentParticipants = 10

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), adminID, "admin")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		result, err := useCase.Execute(context.Background(), "invalid-id", primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		mockRepo.On("FindByID", mock.Anything, competitionID).Return(nil, errors.New("not found"))

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)
	})

	t.Run("failure - not owner and not admin", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		otherUserID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), otherUserID, "user")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrNotOwner)
	})

	t.Run("failure - competition not upcoming", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidStatus)
	})

	t.Run("failure - insufficient participants", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"
		competition.Registration.MinParticipants = 10
		competition.Registration.CurrentParticipants = 3

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInsufficientPermissions)
	})

	t.Run("failure - database error on update", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewStartCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"
		competition.Registration.MinParticipants = 0

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(errors.New("db error"))

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
	})
}

// ============================================================================
// END COMPETITION TESTS
// ============================================================================

func TestEndCompetition(t *testing.T) {
	t.Run("success - owner ends competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewEndCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, "completed", result.Status)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - admin ends competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewEndCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		adminID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), adminID, "admin")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewEndCompetitionUseCase(mockRepo)

		result, err := useCase.Execute(context.Background(), "invalid-id", primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewEndCompetitionUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		mockRepo.On("FindByID", mock.Anything, competitionID).Return(nil, errors.New("not found"))

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)
	})

	t.Run("failure - not owner and not admin", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewEndCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		otherUserID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), otherUserID, "user")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrNotOwner)
	})

	t.Run("failure - competition not live", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewEndCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidStatus)
	})

	t.Run("failure - database error on update", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewEndCompetitionUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "live"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(errors.New("db error"))

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
	})
}

// ============================================================================
// PUBLISH RESULTS TESTS
// ============================================================================

func TestPublishResults(t *testing.T) {
	t.Run("success - owner publishes results", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "completed"
		competition.IsResultsPublished = false

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.True(t, result.IsResultsPublished)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - admin publishes results", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		adminID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "completed"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), adminID, "admin")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		mockRepo.AssertExpectations(t)
	})

	t.Run("success - results already published", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "completed"
		competition.IsResultsPublished = true

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		// Should not call Update since already published
		mockRepo.AssertNotCalled(t, "Update")
	})

	t.Run("success - publish results for live competition", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "live"
		competition.IsResultsPublished = false

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		result, err := useCase.Execute(context.Background(), "invalid-id", primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		competitionID := primitive.NewObjectID()
		mockRepo.On("FindByID", mock.Anything, competitionID).Return(nil, errors.New("not found"))

		result, err := useCase.Execute(context.Background(), competitionID.Hex(), primitive.NewObjectID(), "admin")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)
	})

	t.Run("failure - not owner and not admin", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		otherUserID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "completed"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), otherUserID, "user")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrNotOwner)
	})

	t.Run("failure - competition not completed or live", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "upcoming"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidStatus)
	})

	t.Run("failure - database error on update", func(t *testing.T) {
		mockRepo := new(MockCompetitionRepository)
		useCase := NewPublishResultsUseCase(mockRepo)

		organizerID := primitive.NewObjectID()
		competition := createTestCompetitionWithOrganizer(organizerID)
		competition.Status = "completed"

		mockRepo.On("FindByID", mock.Anything, competition.ID).Return(competition, nil)
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).Return(errors.New("db error"))

		result, err := useCase.Execute(context.Background(), competition.ID.Hex(), organizerID, "organizer")

		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)
	})
}
