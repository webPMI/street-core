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
// MOCK REPOSITORY
// ============================================================================

type MockCompetitionRepository struct {
	mock.Mock
}

func (m *MockCompetitionRepository) Save(ctx context.Context, competition *entities.Competition) error {
	args := m.Called(ctx, competition)
	return args.Error(0)
}

func (m *MockCompetitionRepository) Update(ctx context.Context, competition *entities.Competition) error {
	args := m.Called(ctx, competition)
	return args.Error(0)
}

func (m *MockCompetitionRepository) FindByID(ctx context.Context, id primitive.ObjectID) (*entities.Competition, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Competition), args.Error(1)
}

func (m *MockCompetitionRepository) FindAll(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error) {
	args := m.Called(ctx, page, limit, filters)
	return args.Get(0).([]*entities.Competition), args.Get(1).(int64), args.Error(2)
}

func (m *MockCompetitionRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockCompetitionRepository) FindByOrganizerID(ctx context.Context, organizerID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error) {
	args := m.Called(ctx, organizerID, page, limit)
	return args.Get(0).([]*entities.Competition), args.Get(1).(int64), args.Error(2)
}

func (m *MockCompetitionRepository) FindByStatus(ctx context.Context, status string, page, limit int) ([]*entities.Competition, int64, error) {
	args := m.Called(ctx, status, page, limit)
	return args.Get(0).([]*entities.Competition), args.Get(1).(int64), args.Error(2)
}

func (m *MockCompetitionRepository) FindUpcoming(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error) {
	args := m.Called(ctx, page, limit, filters)
	return args.Get(0).([]*entities.Competition), args.Get(1).(int64), args.Error(2)
}

func (m *MockCompetitionRepository) FindLive(ctx context.Context, page, limit int, filters map[string]interface{}) ([]*entities.Competition, int64, error) {
	args := m.Called(ctx, page, limit, filters)
	return args.Get(0).([]*entities.Competition), args.Get(1).(int64), args.Error(2)
}

func (m *MockCompetitionRepository) RegisterAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) error {
	args := m.Called(ctx, competitionID, athleteID)
	return args.Error(0)
}

func (m *MockCompetitionRepository) UnregisterAthlete(ctx context.Context, competitionID, athleteID primitive.ObjectID) error {
	args := m.Called(ctx, competitionID, athleteID)
	return args.Error(0)
}

func (m *MockCompetitionRepository) IsAthleteRegistered(ctx context.Context, competitionID, athleteID primitive.ObjectID) (bool, error) {
	args := m.Called(ctx, competitionID, athleteID)
	return args.Get(0).(bool), args.Error(1)
}

func (m *MockCompetitionRepository) AddJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) error {
	args := m.Called(ctx, competitionID, judgeID)
	return args.Error(0)
}

func (m *MockCompetitionRepository) RemoveJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) error {
	args := m.Called(ctx, competitionID, judgeID)
	return args.Error(0)
}

func (m *MockCompetitionRepository) IsJudge(ctx context.Context, competitionID, judgeID primitive.ObjectID) (bool, error) {
	args := m.Called(ctx, competitionID, judgeID)
	return args.Get(0).(bool), args.Error(1)
}

func (m *MockCompetitionRepository) FindByAthleteID(ctx context.Context, athleteID primitive.ObjectID, page, limit int) ([]*entities.Competition, int64, error) {
	args := m.Called(ctx, athleteID, page, limit)
	return args.Get(0).([]*entities.Competition), args.Get(1).(int64), args.Error(2)
}

// ============================================================================
// TEST FIXTURES
// ============================================================================

var (
	testOrganizerID = primitive.NewObjectID()
	testEventID     = primitive.NewObjectID()
	testClubID      = primitive.NewObjectID()
)

func createTestCompetitionRequest() dto.CreateCompetitionRequest {
	startDate := time.Now().Add(24 * time.Hour)
	endDate := startDate.Add(5 * time.Hour)

	return dto.CreateCompetitionRequest{
		Title:           "Test Street Competition",
		Description:     "A test competition for street sports enthusiasts",
		EventID:         testEventID.Hex(),
		ClubID:          testClubID.Hex(),
		CompetitionType: "individual",
		Format:          "single_round",
		Discipline:      "skateboarding",
		Category:        "amateur",
		Schedule: dto.ScheduleDTO{
			StartDate: startDate,
			EndDate:   endDate,
			Venue:     "Urban Skate Park",
			City:      "Barcelona",
			Country:   "Spain",
		},
		Registration: dto.RegistrationDTO{
			MaxParticipants: 50,
			MinParticipants: 5,
		},
		ScoringCriteria: dto.ScoringCriteriaDTO{
			Type:     "points",
			MinScore: 0,
			MaxScore: 100,
		},
		RequiredJudges: 3,
		TotalRounds:    1,
		Rules:          "Standard street competition rules apply",
		Tags:           []string{"street", "skateboarding", "amateur"},
	}
}

// ============================================================================
// CREATE COMPETITION TESTS
// ============================================================================

func TestCreateCompetition(t *testing.T) {
	t.Run("success - admin creates competition", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()

		// Mock expectations
		mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil)

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "admin")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, req.Title, result.Title)
		assert.Equal(t, req.Description, result.Description)
		assert.Equal(t, testOrganizerID.Hex(), result.OrganizerID)
		assert.Equal(t, "upcoming", result.Status)

		mockRepo.AssertExpectations(t)
	})

	t.Run("success - organizer creates competition", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()

		// Mock expectations
		mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil)

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "organizer")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockRepo.AssertExpectations(t)
	})

	t.Run("success - verified_special creates competition", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()

		// Mock expectations
		mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil)

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "verified_special")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockRepo.AssertExpectations(t)
	})

	t.Run("failure - unauthorized user role", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()

		// Execute with regular user role
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "user")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrUnauthorized)

		mockRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - invalid eventID format", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()
		req.EventID = "invalid-id-format"

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "admin")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - invalid clubID format", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()
		req.ClubID = "invalid-club-id"

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "admin")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrInvalidInput)

		mockRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - validation error (missing required fields)", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()
		req.Title = "" // Empty title should fail validation

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "admin")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)

		mockRepo.AssertNotCalled(t, "Save")
	})

	t.Run("failure - database error on save", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()

		// Mock expectations - simulate database error
		mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(errors.New("database connection error"))

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "admin")

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.ErrorIs(t, err, domainerrors.ErrDatabaseOperation)

		mockRepo.AssertExpectations(t)
	})

	t.Run("success - competition without optional IDs", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()
		req.EventID = ""
		req.ClubID = ""

		// Mock expectations
		mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil)

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "admin")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)

		mockRepo.AssertExpectations(t)
	})

	t.Run("success - competition with all optional fields", func(t *testing.T) {
		// Setup
		mockRepo := new(MockCompetitionRepository)
		useCase := NewCreateCompetitionUseCase(mockRepo)

		req := createTestCompetitionRequest()
		req.BannerUrl = "https://example.com/banner.jpg"
		req.ImageUrls = []string{"https://example.com/img1.jpg", "https://example.com/img2.jpg"}
		req.Rules = "Detailed competition rules here"

		// Mock expectations
		mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Competition")).
			Return(nil)

		// Execute
		result, err := useCase.Execute(context.Background(), req, testOrganizerID, "admin")

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, req.BannerUrl, result.BannerUrl)
		assert.Equal(t, req.ImageUrls, result.ImageUrls)

		mockRepo.AssertExpectations(t)
	})
}

// ============================================================================
// BENCHMARK TESTS
// ============================================================================

func BenchmarkCreateCompetition(b *testing.B) {
	mockRepo := new(MockCompetitionRepository)
	useCase := NewCreateCompetitionUseCase(mockRepo)

	req := createTestCompetitionRequest()

	mockRepo.On("Save", mock.Anything, mock.AnythingOfType("*entities.Competition")).
		Return(nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		useCase.Execute(context.Background(), req, testOrganizerID, "admin")
	}
}
