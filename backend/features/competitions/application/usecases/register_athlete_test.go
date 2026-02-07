package usecases

import (
	"context"
	"testing"
	"time"

	"backend/features/competitions/domain/entities"
	domainerrors "backend/features/competitions/domain/errors"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================================
// TEST FIXTURES
// ============================================================================

var (
	testAthleteID  = primitive.NewObjectID()
	testAthleteID2 = primitive.NewObjectID()
)

func createTestCompetition() *entities.Competition {
	startDate := time.Now().Add(24 * time.Hour)
	endDate := startDate.Add(5 * time.Hour)

	comp := entities.NewCompetition(
		"Test Competition",
		"A test competition for unit tests",
		testOrganizerID,
		"individual",
		"single_round",
		"skateboarding",
	)

	comp.Schedule = entities.Schedule{
		StartDate: startDate,
		EndDate:   endDate,
		Venue:     "Test Venue",
		City:      "Test City",
		Country:   "Test Country",
	}

	comp.Registration.ParticipantStatus = entities.ParticipantStatusOpen
	comp.Registration.MaxParticipants = 50
	comp.Registration.MinParticipants = 5
	comp.Registration.CurrentParticipants = 0
	comp.Registration.RegisteredAthleteIDs = []primitive.ObjectID{}

	comp.ScoringCriteria = entities.ScoringCriteria{
		Type:     "points",
		MinScore: 0,
		MaxScore: 100,
	}

	return comp
}

func createFullCompetition() *entities.Competition {
	comp := createTestCompetition()
	// Fill to capacity
	comp.Registration.MaxParticipants = 2
	comp.Registration.CurrentParticipants = 2
	comp.Registration.RegisteredAthleteIDs = []primitive.ObjectID{
		primitive.NewObjectID(),
		primitive.NewObjectID(),
	}
	return comp
}

func createClosedCompetition() *entities.Competition {
	comp := createTestCompetition()
	comp.Registration.ParticipantStatus = entities.ParticipantStatusClosed
	return comp
}

func createStartedCompetition() *entities.Competition {
	comp := createTestCompetition()
	comp.Status = entities.StatusLive
	return comp
}

// ============================================================================
// REGISTER ATHLETE TESTS
// ============================================================================

func TestRegisterAthlete(t *testing.T) {
	t.Run("success - register athlete", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createTestCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.NoError(t, err)
		assert.True(t, competition.IsAthleteRegistered(testAthleteID))
		assert.Equal(t, 1, competition.Registration.CurrentParticipants)

		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		// Execute with invalid ID
		err := useCase.Execute(context.Background(), "invalid-id", testAthleteID.Hex(), testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockRepo.AssertNotCalled(t, "FindByID")
	})

	t.Run("failure - invalid athlete ID", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competitionID := primitive.NewObjectID().Hex()

		// Execute with invalid athlete ID
		err := useCase.Execute(context.Background(), competitionID, "invalid-athlete", testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockRepo.AssertNotCalled(t, "FindByID")
	})

	t.Run("failure - competition not found", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competitionID := primitive.NewObjectID()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competitionID).
			Return(nil, domainerrors.ErrCompetitionNotFound)

		// Execute
		err := useCase.Execute(context.Background(), competitionID.Hex(), athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionNotFound)

		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - registration closed", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createClosedCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrRegistrationClosed)

		mockRepo.AssertExpectations(t)
		mockRepo.AssertNotCalled(t, "Update")
	})

	t.Run("failure - already registered", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createTestCompetition()
		competition.AddAthlete(testAthleteID) // Pre-register athlete

		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrAlreadyRegistered)

		mockRepo.AssertExpectations(t)
		mockRepo.AssertNotCalled(t, "Update")
	})

	t.Run("failure - max participants reached", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createFullCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrRegistrationClosed)

		mockRepo.AssertExpectations(t)
		mockRepo.AssertNotCalled(t, "Update")
	})

	t.Run("failure - competition already started", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createStartedCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrRegistrationClosed)

		mockRepo.AssertExpectations(t)
		mockRepo.AssertNotCalled(t, "Update")
	})

	t.Run("failure - database update error", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createTestCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(domainerrors.ErrDatabaseOperation)

		// Execute
		err := useCase.Execute(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)

		mockRepo.AssertExpectations(t)
	})

	t.Run("success - multiple athletes can register", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createTestCompetition()
		competitionID := competition.ID.Hex()

		// Mock expectations for first athlete
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil).Once()

		// Register first athlete
		err := useCase.Execute(context.Background(), competitionID, testAthleteID.Hex(), testOrganizerID, "user")
		assert.NoError(t, err)

		// Mock expectations for second athlete
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil).Once()
		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil).Once()

		// Register second athlete
		err = useCase.Execute(context.Background(), competitionID, testAthleteID2.Hex(), testOrganizerID, "user")
		assert.NoError(t, err)

		// Assert
		assert.Equal(t, 2, competition.Registration.CurrentParticipants)

		mockRepo.AssertExpectations(t)
	})
}

// ============================================================================
// UNREGISTER ATHLETE TESTS
// ============================================================================

func TestUnregisterAthlete(t *testing.T) {
	t.Run("success - unregister athlete", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createTestCompetition()
		competition.AddAthlete(testAthleteID) // Pre-register athlete

		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil)

		// Execute
		err := useCase.Unregister(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.NoError(t, err)
		assert.False(t, competition.IsAthleteRegistered(testAthleteID))

		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - athlete not registered", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		competition := createTestCompetition()
		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Unregister(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrNotRegistered)

		mockRepo.AssertExpectations(t)
		mockRepo.AssertNotCalled(t, "Update")
	})

	t.Run("failure - cannot unregister after competition started", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		// Create competition and register athlete BEFORE it starts
		competition := createTestCompetition()
		competition.AddAthlete(testAthleteID) // Register while still upcoming
		competition.Status = entities.StatusLive // Then start it

		competitionID := competition.ID.Hex()
		athleteID := testAthleteID.Hex()

		// Mock expectations
		mockRepo.On("FindByID", mock.Anything, competition.ID).
			Return(competition, nil)

		// Execute
		err := useCase.Unregister(context.Background(), competitionID, athleteID, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrCompetitionStarted)

		mockRepo.AssertExpectations(t)
		mockRepo.AssertNotCalled(t, "Update")
	})

	t.Run("failure - invalid competition ID", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewRegisterAthleteUseCase(mockRepo, nil)

		// Execute
		err := useCase.Unregister(context.Background(), "invalid-id", testAthleteID.Hex(), testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockRepo.AssertNotCalled(t, "FindByID")
	})
}

// ============================================================================
// BENCHMARK TESTS
// ============================================================================

func BenchmarkRegisterAthlete(b *testing.B) {
	mockRepo := new(MockCompetitionRepository)
	useCase := NewRegisterAthleteUseCase(mockRepo, nil)

	competition := createTestCompetition()
	competitionID := competition.ID.Hex()
	athleteID := testAthleteID.Hex()

	mockRepo.On("FindByID", mock.Anything, competition.ID).
		Return(competition, nil)
	mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*entities.Competition")).
		Return(nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Reset registration for benchmarking
		competition.Registration.RegisteredAthleteIDs = []primitive.ObjectID{}
		competition.Registration.CurrentParticipants = 0

		useCase.Execute(context.Background(), competitionID, athleteID, testOrganizerID, "user")
	}
}
