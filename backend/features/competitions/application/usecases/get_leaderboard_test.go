package usecases

import (
	"context"
	"testing"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================================
// TEST FIXTURES
// ============================================================================

func createTestLeaderboard(competitionID primitive.ObjectID) *entities.Leaderboard {
	leaderboard := entities.NewLeaderboard(competitionID)

	// Add some entries
	leaderboard.Entries = []entities.LeaderboardEntry{
		{
			AthleteID:   testAthleteID,
			AthleteName: "Jane Athlete",
			TotalScore:  95.5,
			Position:    1,
		},
		{
			AthleteID:   testAthleteID2,
			AthleteName: "John Runner",
			TotalScore:  88.0,
			Position:    2,
		},
	}

	return leaderboard
}

func createPublishedCompetition() *entities.Competition {
	comp := createTestCompetition()
	comp.Status = entities.StatusCompleted
	comp.IsResultsPublished = true
	return comp
}

func createUnpublishedCompetition() *entities.Competition {
	comp := createTestCompetition()
	comp.Status = entities.StatusCompleted
	comp.IsResultsPublished = false
	comp.ShowLiveResults = false
	return comp
}

func createLiveResultsCompetition() *entities.Competition {
	comp := createLiveCompetition()
	comp.ShowLiveResults = true
	comp.IsResultsPublished = false
	return comp
}

// ============================================================================
// GET LEADERBOARD TESTS
// ============================================================================

func TestGetLeaderboard(t *testing.T) {
	t.Run("success - get existing leaderboard", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createTestCompetition()
		leaderboard := createTestLeaderboard(competition.ID)

		competitionID := competition.ID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute
		result, err := useCase.Execute(context.Background(), competitionID)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, competition.ID, result.CompetitionID)
		assert.Len(t, result.Entries, 2)
		assert.Equal(t, 1, result.Entries[0].Position)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("success - empty leaderboard when none exists", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createTestCompetition()
		competitionID := competition.ID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(nil, nil)

		// Execute
		result, err := useCase.Execute(context.Background(), competitionID)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, competition.ID, result.CompetitionID)
		assert.Empty(t, result.Entries)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		// Execute
		result, err := useCase.Execute(context.Background(), "invalid-id")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockCompRepo.AssertNotCalled(t, "FindByID")
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competitionID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competitionID).
			Return(nil, domainerrors.ErrCompetitionNotFound)

		// Execute
		result, err := useCase.Execute(context.Background(), competitionID.Hex())

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertNotCalled(t, "FindByCompetitionID")
	})
}

// ============================================================================
// GET LEADERBOARD WITH CHECK TESTS
// ============================================================================

func TestGetLeaderboardWithCheck(t *testing.T) {
	t.Run("success - admin can view unpublished results", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createUnpublishedCompetition()
		leaderboard := createTestLeaderboard(competition.ID)
		competitionID := competition.ID.Hex()

		adminID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID, adminID, "admin")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("success - organizer can view unpublished results", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createUnpublishedCompetition()
		leaderboard := createTestLeaderboard(competition.ID)
		competitionID := competition.ID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute with organizer ID
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID, testOrganizerID, "user")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("success - judge can view unpublished results", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createUnpublishedCompetition()
		competition.JudgeIDs = []primitive.ObjectID{testJudgeID}

		leaderboard := createTestLeaderboard(competition.ID)
		competitionID := competition.ID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute with judge ID
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID, testJudgeID, "user")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("success - public can view published results", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createPublishedCompetition()
		leaderboard := createTestLeaderboard(competition.ID)
		competitionID := competition.ID.Hex()

		publicUserID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute with public user
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID, publicUserID, "user")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("success - public can view live results", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createLiveResultsCompetition()
		leaderboard := createTestLeaderboard(competition.ID)
		competitionID := competition.ID.Hex()

		publicUserID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute with public user
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID, publicUserID, "user")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("failure - public cannot view unpublished results", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createUnpublishedCompetition()
		competitionID := competition.ID.Hex()

		publicUserID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute with public user
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID, publicUserID, "user")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrResultsNotPublished)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertNotCalled(t, "FindByCompetitionID")
	})

	t.Run("success - empty leaderboard for authorized user", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createPublishedCompetition()
		competitionID := competition.ID.Hex()

		adminID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(nil, nil)

		// Execute
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID, adminID, "admin")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Empty(t, result.Entries)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		userID := primitive.NewObjectID()

		// Execute
		result, err := useCase.ExecuteWithCheck(context.Background(), "invalid-id", userID, "user")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockCompRepo.AssertNotCalled(t, "FindByID")
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competitionID := primitive.NewObjectID()
		userID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competitionID).
			Return(nil, domainerrors.ErrCompetitionNotFound)

		// Execute
		result, err := useCase.ExecuteWithCheck(context.Background(), competitionID.Hex(), userID, "user")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)

		mockCompRepo.AssertExpectations(t)
	})
}

// ============================================================================
// EDGE CASE TESTS
// ============================================================================

func TestGetLeaderboardEdgeCases(t *testing.T) {
	t.Run("success - leaderboard with single athlete", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createPublishedCompetition()
		leaderboard := entities.NewLeaderboard(competition.ID)
		leaderboard.Entries = []entities.LeaderboardEntry{
			{
				AthleteID:   testAthleteID,
				AthleteName: "Jane Athlete",
				TotalScore:  95.5,
				Position:    1,
			},
		}

		competitionID := competition.ID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute
		result, err := useCase.Execute(context.Background(), competitionID)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Len(t, result.Entries, 1)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})

	t.Run("success - leaderboard with many athletes", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)

		useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

		competition := createPublishedCompetition()
		leaderboard := entities.NewLeaderboard(competition.ID)

		// Add 50 athletes
		for i := 0; i < 50; i++ {
			leaderboard.Entries = append(leaderboard.Entries, entities.LeaderboardEntry{
				AthleteID:   primitive.NewObjectID(),
				AthleteName: "Athlete",
				TotalScore:  float64(100 - i),
				Position:    i + 1,
			})
		}

		competitionID := competition.ID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(leaderboard, nil)

		// Execute
		result, err := useCase.Execute(context.Background(), competitionID)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Len(t, result.Entries, 50)
		assert.Equal(t, 1, result.Entries[0].Position)
		assert.Equal(t, 50, result.Entries[49].Position)

		mockCompRepo.AssertExpectations(t)
		mockLeaderboardRepo.AssertExpectations(t)
	})
}

// ============================================================================
// BENCHMARK TESTS
// ============================================================================

func BenchmarkGetLeaderboard(b *testing.B) {
	mockCompRepo := new(MockCompetitionRepository)
	mockLeaderboardRepo := new(MockLeaderboardRepository)

	useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

	competition := createTestCompetition()
	leaderboard := createTestLeaderboard(competition.ID)
	competitionID := competition.ID.Hex()

	mockCompRepo.On("FindByID", mock.Anything, competition.ID).
		Return(competition, nil)
	mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
		Return(leaderboard, nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		useCase.Execute(context.Background(), competitionID)
	}
}

func BenchmarkGetLeaderboardWithCheck(b *testing.B) {
	mockCompRepo := new(MockCompetitionRepository)
	mockLeaderboardRepo := new(MockLeaderboardRepository)

	useCase := NewGetLeaderboardUseCase(mockLeaderboardRepo, mockCompRepo)

	competition := createPublishedCompetition()
	leaderboard := createTestLeaderboard(competition.ID)
	competitionID := competition.ID.Hex()
	userID := primitive.NewObjectID()

	mockCompRepo.On("FindByID", mock.Anything, competition.ID).
		Return(competition, nil)
	mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
		Return(leaderboard, nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		useCase.ExecuteWithCheck(context.Background(), competitionID, userID, "user")
	}
}
