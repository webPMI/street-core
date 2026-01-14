package usecases

import (
	"context"
	"testing"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"
	"backend/features/competitions/domain/repositories"
	"backend/pkg/users"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================================
// MOCK SCORE REPOSITORY
// ============================================================================

type MockScoreRepository struct {
	mock.Mock
}

func (m *MockScoreRepository) Save(ctx context.Context, score *entities.Score) error {
	args := m.Called(ctx, score)
	return args.Error(0)
}

func (m *MockScoreRepository) Update(ctx context.Context, score *entities.Score) error {
	args := m.Called(ctx, score)
	return args.Error(0)
}

func (m *MockScoreRepository) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Score, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Score), args.Error(1)
}

func (m *MockScoreRepository) FindExistingScore(ctx context.Context, competitionID, athleteID, judgeID primitive.ObjectID, roundID string) (*entities.Score, error) {
	args := m.Called(ctx, competitionID, athleteID, judgeID, roundID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Score), args.Error(1)
}

func (m *MockScoreRepository) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) ([]*entities.Score, error) {
	args := m.Called(ctx, competitionID)
	return args.Get(0).([]*entities.Score), args.Error(1)
}

func (m *MockScoreRepository) FindByAthleteID(ctx context.Context, competitionID, athleteID primitive.ObjectID) ([]*entities.Score, error) {
	args := m.Called(ctx, competitionID, athleteID)
	return args.Get(0).([]*entities.Score), args.Error(1)
}

func (m *MockScoreRepository) FindByRoundID(ctx context.Context, competitionID primitive.ObjectID, roundID string) ([]*entities.Score, error) {
	args := m.Called(ctx, competitionID, roundID)
	return args.Get(0).([]*entities.Score), args.Error(1)
}

func (m *MockScoreRepository) CalculateAverageScore(ctx context.Context, competitionID, athleteID primitive.ObjectID, roundID string) (float64, error) {
	args := m.Called(ctx, competitionID, athleteID, roundID)
	return args.Get(0).(float64), args.Error(1)
}

func (m *MockScoreRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockScoreRepository) FindByCompetitionAndAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) ([]*entities.Score, error) {
	args := m.Called(ctx, competitionID, athleteID)
	return args.Get(0).([]*entities.Score), args.Error(1)
}

func (m *MockScoreRepository) FindByCompetitionAndRound(ctx context.Context, competitionID primitive.ObjectID, roundID string) ([]*entities.Score, error) {
	args := m.Called(ctx, competitionID, roundID)
	return args.Get(0).([]*entities.Score), args.Error(1)
}

func (m *MockScoreRepository) FindByJudgeAndCompetition(ctx context.Context, judgeID, competitionID primitive.ObjectID) ([]*entities.Score, error) {
	args := m.Called(ctx, judgeID, competitionID)
	return args.Get(0).([]*entities.Score), args.Error(1)
}

// ============================================================================
// MOCK LEADERBOARD REPOSITORY
// ============================================================================

type MockLeaderboardRepository struct {
	mock.Mock
}

func (m *MockLeaderboardRepository) Save(ctx context.Context, leaderboard *entities.Leaderboard) error {
	args := m.Called(ctx, leaderboard)
	return args.Error(0)
}

func (m *MockLeaderboardRepository) Update(ctx context.Context, leaderboard *entities.Leaderboard) error {
	args := m.Called(ctx, leaderboard)
	return args.Error(0)
}

func (m *MockLeaderboardRepository) FindByCompetitionID(ctx context.Context, competitionID primitive.ObjectID) (*entities.Leaderboard, error) {
	args := m.Called(ctx, competitionID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Leaderboard), args.Error(1)
}

func (m *MockLeaderboardRepository) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Leaderboard, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Leaderboard), args.Error(1)
}

func (m *MockLeaderboardRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

// ============================================================================
// MOCK USER CLIENT
// ============================================================================

type MockUserClient struct {
	mock.Mock
}

func (m *MockUserClient) GetUserBasicInfo(ctx context.Context, userID primitive.ObjectID) (*users.UserBasicInfo, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*users.UserBasicInfo), args.Error(1)
}

func (m *MockUserClient) GetUsersBasicInfo(ctx context.Context, userIDs []primitive.ObjectID) (map[string]*users.UserBasicInfo, error) {
	args := m.Called(ctx, userIDs)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(map[string]*users.UserBasicInfo), args.Error(1)
}

// ============================================================================
// TEST FIXTURES
// ============================================================================

var (
	testJudgeID  = primitive.NewObjectID()
	testJudgeID2 = primitive.NewObjectID()
	testRoundID  = "round-1"
)

func createLiveCompetition() *entities.Competition {
	comp := createTestCompetition()

	// Register athlete BEFORE changing status to live
	comp.AddAthlete(testAthleteID)

	// Now set to live status
	comp.Status = entities.StatusLive
	comp.AllowLiveScoring = true
	comp.JudgeIDs = []primitive.ObjectID{testJudgeID, testJudgeID2}

	return comp
}

func createUpdateLeaderboardUseCase(compRepo repositories.CompetitionRepository, scoreRepo repositories.ScoreRepository, leaderboardRepo repositories.LeaderboardRepository, userClient users.UserClient) *UpdateLeaderboardUseCase {
	return NewUpdateLeaderboardUseCase(leaderboardRepo, scoreRepo, compRepo, userClient)
}

// ============================================================================
// SUBMIT SCORES TESTS
// ============================================================================

func TestSubmitScores(t *testing.T) {
	t.Run("success - judge submits score", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()
		score := 85.5

		// Mock user info
		userInfoMap := map[string]*users.UserBasicInfo{
			testJudgeID.Hex(): {
				ID:        testJudgeID,
				FirstName: "John",
				LastName:  "Judge",
			},
			testAthleteID.Hex(): {
				ID:        testAthleteID,
				FirstName: "Jane",
				LastName:  "Athlete",
			},
		}

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()

		mockScoreRepo.On("FindExistingScore", mock.Anything, competition.ID, testAthleteID, testJudgeID, testRoundID).
			Return(nil, nil)

		mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
			Return(userInfoMap, nil)

		mockScoreRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Score")).
			Return(nil)

		// Mock for leaderboard update - returns nil so new leaderboard will be created
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()
		mockScoreRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return([]*entities.Score{}, nil)
		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(nil, nil)
		mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
			Return(map[string]*users.UserBasicInfo{}, nil)
		// NewLeaderboard sets CreatedAt, so Update will be called, not Save
		mockLeaderboardRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Leaderboard")).
			Return(nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, score, testJudgeID, "user")

		// Assert
		assert.NoError(t, err)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertExpectations(t)
		mockUserClient.AssertExpectations(t)
	})

	t.Run("success - admin submits score", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()
		adminID := primitive.NewObjectID()
		score := 90.0

		userInfoMap := map[string]*users.UserBasicInfo{
			adminID.Hex(): {
				ID:        adminID,
				FirstName: "Admin",
				LastName:  "User",
			},
			testAthleteID.Hex(): {
				ID:        testAthleteID,
				FirstName: "Jane",
				LastName:  "Athlete",
			},
		}

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()

		mockScoreRepo.On("FindExistingScore", mock.Anything, competition.ID, testAthleteID, adminID, testRoundID).
			Return(nil, nil)

		mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
			Return(userInfoMap, nil)

		mockScoreRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Score")).
			Return(nil)

		// Mock for leaderboard update - returns nil so new leaderboard will be created
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()
		mockScoreRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return([]*entities.Score{}, nil)
		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(nil, nil)
		mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
			Return(map[string]*users.UserBasicInfo{}, nil)
		// NewLeaderboard sets CreatedAt, so Update will be called, not Save
		mockLeaderboardRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Leaderboard")).
			Return(nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, score, adminID, "admin")

		// Assert
		assert.NoError(t, err)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertExpectations(t)
	})

	t.Run("success - update existing score", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()
		newScore := 92.0

		// Existing score
		existingScore := entities.NewScore(competition.ID, testAthleteID, testJudgeID, testRoundID, 80.0)

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()

		mockScoreRepo.On("FindExistingScore", mock.Anything, competition.ID, testAthleteID, testJudgeID, testRoundID).
			Return(existingScore, nil)

		mockScoreRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Score")).
			Return(nil)

		// Mock for leaderboard update - returns nil so new leaderboard will be created
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()
		mockScoreRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return([]*entities.Score{}, nil)
		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(nil, nil)
		mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
			Return(map[string]*users.UserBasicInfo{}, nil)
		// NewLeaderboard sets CreatedAt, so Update will be called, not Save
		mockLeaderboardRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Leaderboard")).
			Return(nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, newScore, testJudgeID, "user")

		// Assert
		assert.NoError(t, err)
		assert.Equal(t, newScore, existingScore.TotalScore)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertExpectations(t)
	})

	t.Run("failure - not a judge", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()
		unauthorizedUserID := primitive.NewObjectID() // Not in judge list

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, 85.0, unauthorizedUserID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrNotJudge)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - competition not live", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createTestCompetition()
		competition.Status = entities.StatusUpcoming
		competition.AllowLiveScoring = false
		competition.JudgeIDs = []primitive.ObjectID{testJudgeID}

		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, 85.0, testJudgeID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrCannotSubmitScore)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - invalid score (below min)", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute with score below minimum
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, -10.0, testJudgeID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - invalid score (above max)", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute with score above maximum
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, 150.0, testJudgeID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - athlete not registered", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		unregisteredAthleteID := primitive.NewObjectID()

		competitionID := competition.ID.Hex()
		athleteID := unregisteredAthleteID.Hex()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, 85.0, testJudgeID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrNotRegistered)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		// Execute with invalid ID
		err := useCase.Execute(context.Background(), "invalid-id", testAthleteID.Hex(), testRoundID, 85.0, testJudgeID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockCompRepo.AssertNotCalled(t, "FindByID")
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competitionID := primitive.NewObjectID()

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competitionID).
			Return(nil, domainerrors.ErrCompetitionNotFound)

		// Execute
		err := useCase.Execute(context.Background(), competitionID.Hex(), testAthleteID.Hex(), testRoundID, 85.0, testJudgeID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)

		mockCompRepo.AssertExpectations(t)
	})

	t.Run("success - user info fetch fails but score still submitted", func(t *testing.T) {
		// Setup
		mockCompRepo := new(MockCompetitionRepository)
		mockScoreRepo := new(MockScoreRepository)
		mockLeaderboardRepo := new(MockLeaderboardRepository)
		mockUserClient := new(MockUserClient)

		updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
		useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

		competition := createLiveCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()
		score := 85.5

		// Mock expectations
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()

		mockScoreRepo.On("FindExistingScore", mock.Anything, competition.ID, testAthleteID, testJudgeID, testRoundID).
			Return(nil, nil)

		// User info fetch fails
		mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
			Return(nil, assert.AnError)

		// Score should still be saved
		mockScoreRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Score")).
			Return(nil)

		// Mock for leaderboard update - returns nil so new leaderboard will be created
		mockCompRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()
		mockScoreRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return([]*entities.Score{}, nil)
		mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
			Return(nil, nil)
		mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
			Return(map[string]*users.UserBasicInfo{}, nil)
		// NewLeaderboard sets CreatedAt, so Update will be called, not Save
		mockLeaderboardRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Leaderboard")).
			Return(nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, score, testJudgeID, "user")

		// Assert - should succeed even though user info fetch failed
		assert.NoError(t, err)

		mockCompRepo.AssertExpectations(t)
		mockScoreRepo.AssertExpectations(t)
		mockUserClient.AssertExpectations(t)
	})
}

// ============================================================================
// BENCHMARK TESTS
// ============================================================================

func BenchmarkSubmitScores(b *testing.B) {
	mockCompRepo := new(MockCompetitionRepository)
	mockScoreRepo := new(MockScoreRepository)
	mockLeaderboardRepo := new(MockLeaderboardRepository)
	mockUserClient := new(MockUserClient)

	updateLeaderboardUC := createUpdateLeaderboardUseCase(mockCompRepo, mockScoreRepo, mockLeaderboardRepo, mockUserClient)
	useCase := NewSubmitScoresUseCase(mockCompRepo, mockScoreRepo, updateLeaderboardUC, mockUserClient)

	competition := createLiveCompetition()
	competitionID := competition.ID.Hex()
	athleteID := testAthleteID.Hex()

	userInfoMap := map[string]*users.UserBasicInfo{
		testJudgeID.Hex(): {
			ID:        testJudgeID,
			FirstName: "John",
			LastName:  "Judge",
		},
	}

	mockCompRepo.On("FindByID", mock.Anything, competition.ID).
		Return(competition, nil)
	mockScoreRepo.On("FindExistingScore", mock.Anything, competition.ID, testAthleteID, testJudgeID, testRoundID).
		Return(nil, nil)
	mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
		Return(userInfoMap, nil)
	mockScoreRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Score")).
		Return(nil)
	mockScoreRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
		Return([]*entities.Score{}, nil)
	mockLeaderboardRepo.On("FindByCompetitionID", mock.Anything, competition.ID).
		Return(nil, nil)
	mockUserClient.On("GetUsersBasicInfo", mock.Anything, mock.AnythingOfType("[]primitive.ObjectID")).
		Return(map[string]*users.UserBasicInfo{}, nil)
	mockLeaderboardRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Leaderboard")).
		Return(nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		useCase.Execute(context.Background(), competitionID, athleteID, testRoundID, 85.0, testJudgeID, "user")
	}
}
