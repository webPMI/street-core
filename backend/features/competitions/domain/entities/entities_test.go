package entities

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================================
// LEADERBOARD TESTS
// ============================================================================

func TestNewLeaderboard(t *testing.T) {
	competitionID := primitive.NewObjectID()
	leaderboard := NewLeaderboard(competitionID)

	assert.NotEmpty(t, leaderboard.ID)
	assert.Equal(t, competitionID, leaderboard.CompetitionID)
	assert.Empty(t, leaderboard.Entries)
	assert.False(t, leaderboard.CreatedAt.IsZero())
	assert.False(t, leaderboard.UpdatedAt.IsZero())
}

func TestLeaderboard_AddEntry(t *testing.T) {
	t.Run("adds new entry", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())
		athleteID := primitive.NewObjectID()

		entry := LeaderboardEntry{
			AthleteID:   athleteID,
			AthleteName: "Test Athlete",
			TotalScore:  100.0,
		}

		leaderboard.AddEntry(entry)

		assert.Len(t, leaderboard.Entries, 1)
		assert.Equal(t, athleteID, leaderboard.Entries[0].AthleteID)
		assert.Equal(t, "Test Athlete", leaderboard.Entries[0].AthleteName)
	})

	t.Run("updates existing entry", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())
		athleteID := primitive.NewObjectID()

		entry1 := LeaderboardEntry{
			AthleteID:   athleteID,
			AthleteName: "Test Athlete",
			TotalScore:  100.0,
		}
		leaderboard.AddEntry(entry1)

		entry2 := LeaderboardEntry{
			AthleteID:   athleteID,
			AthleteName: "Updated Athlete",
			TotalScore:  150.0,
		}
		leaderboard.AddEntry(entry2)

		assert.Len(t, leaderboard.Entries, 1)
		assert.Equal(t, "Updated Athlete", leaderboard.Entries[0].AthleteName)
		assert.Equal(t, 150.0, leaderboard.Entries[0].TotalScore)
	})
}

func TestLeaderboard_UpdateScore(t *testing.T) {
	t.Run("updates score for existing athlete", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())
		athleteID := primitive.NewObjectID()

		entry := LeaderboardEntry{
			AthleteID:   athleteID,
			AthleteName: "Test Athlete",
		}
		leaderboard.AddEntry(entry)

		leaderboard.UpdateScore(athleteID, "round1", 50.0)
		leaderboard.UpdateScore(athleteID, "round2", 75.0)

		assert.Equal(t, 125.0, leaderboard.Entries[0].TotalScore)
		assert.Equal(t, 50.0, leaderboard.Entries[0].RoundScores["round1"])
		assert.Equal(t, 75.0, leaderboard.Entries[0].RoundScores["round2"])
	})

	t.Run("initializes round scores map if nil", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())
		athleteID := primitive.NewObjectID()

		entry := LeaderboardEntry{
			AthleteID:   athleteID,
			AthleteName: "Test Athlete",
		}
		leaderboard.AddEntry(entry)

		leaderboard.UpdateScore(athleteID, "round1", 100.0)

		assert.NotNil(t, leaderboard.Entries[0].RoundScores)
	})

	t.Run("does nothing for non-existent athlete", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())
		nonExistentID := primitive.NewObjectID()

		leaderboard.UpdateScore(nonExistentID, "round1", 100.0)

		assert.Empty(t, leaderboard.Entries)
	})
}

func TestLeaderboard_SortByScore(t *testing.T) {
	leaderboard := NewLeaderboard(primitive.NewObjectID())

	athletes := []LeaderboardEntry{
		{AthleteID: primitive.NewObjectID(), AthleteName: "Third", TotalScore: 50.0},
		{AthleteID: primitive.NewObjectID(), AthleteName: "First", TotalScore: 150.0},
		{AthleteID: primitive.NewObjectID(), AthleteName: "Second", TotalScore: 100.0},
	}

	for _, a := range athletes {
		leaderboard.AddEntry(a)
	}

	leaderboard.SortByScore()

	assert.Equal(t, "First", leaderboard.Entries[0].AthleteName)
	assert.Equal(t, 1, leaderboard.Entries[0].Position)
	assert.Equal(t, "Second", leaderboard.Entries[1].AthleteName)
	assert.Equal(t, 2, leaderboard.Entries[1].Position)
	assert.Equal(t, "Third", leaderboard.Entries[2].AthleteName)
	assert.Equal(t, 3, leaderboard.Entries[2].Position)
}

func TestLeaderboard_GetTopThree(t *testing.T) {
	t.Run("returns all three when available", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())

		for i := 0; i < 5; i++ {
			leaderboard.AddEntry(LeaderboardEntry{
				AthleteID:   primitive.NewObjectID(),
				AthleteName: "Athlete",
				TotalScore:  float64(100 - i*10),
			})
		}
		leaderboard.SortByScore()

		first, second, third := leaderboard.GetTopThree()

		assert.NotNil(t, first)
		assert.NotNil(t, second)
		assert.NotNil(t, third)
		assert.Equal(t, 100.0, first.TotalScore)
		assert.Equal(t, 90.0, second.TotalScore)
		assert.Equal(t, 80.0, third.TotalScore)
	})

	t.Run("returns nil for missing positions", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())

		leaderboard.AddEntry(LeaderboardEntry{
			AthleteID:   primitive.NewObjectID(),
			AthleteName: "Only One",
			TotalScore:  100.0,
		})

		first, second, third := leaderboard.GetTopThree()

		assert.NotNil(t, first)
		assert.Nil(t, second)
		assert.Nil(t, third)
	})

	t.Run("handles empty leaderboard", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())

		first, second, third := leaderboard.GetTopThree()

		assert.Nil(t, first)
		assert.Nil(t, second)
		assert.Nil(t, third)
	})
}

func TestLeaderboard_GetEntryByAthleteID(t *testing.T) {
	t.Run("returns entry for existing athlete", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())
		athleteID := primitive.NewObjectID()

		leaderboard.AddEntry(LeaderboardEntry{
			AthleteID:   athleteID,
			AthleteName: "Test Athlete",
			TotalScore:  100.0,
		})

		entry := leaderboard.GetEntryByAthleteID(athleteID)

		assert.NotNil(t, entry)
		assert.Equal(t, athleteID, entry.AthleteID)
	})

	t.Run("returns nil for non-existent athlete", func(t *testing.T) {
		leaderboard := NewLeaderboard(primitive.NewObjectID())

		entry := leaderboard.GetEntryByAthleteID(primitive.NewObjectID())

		assert.Nil(t, entry)
	})
}

func TestLeaderboard_PrepareForUpdate(t *testing.T) {
	leaderboard := NewLeaderboard(primitive.NewObjectID())
	oldTime := leaderboard.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	leaderboard.PrepareForUpdate()

	assert.True(t, leaderboard.UpdatedAt.After(oldTime))
}

// ============================================================================
// SCORE TESTS
// ============================================================================

func TestNewScore(t *testing.T) {
	competitionID := primitive.NewObjectID()
	athleteID := primitive.NewObjectID()
	judgeID := primitive.NewObjectID()
	roundID := "round1"
	scoreValue := 85.5

	score := NewScore(competitionID, athleteID, judgeID, roundID, scoreValue)

	assert.NotEmpty(t, score.ID)
	assert.Equal(t, competitionID, score.CompetitionID)
	assert.Equal(t, athleteID, score.AthleteID)
	assert.Equal(t, judgeID, score.JudgeID)
	assert.Equal(t, roundID, score.RoundID)
	assert.Equal(t, scoreValue, score.TotalScore)
	assert.NotNil(t, score.CriteriaScores)
	assert.False(t, score.CreatedAt.IsZero())
	assert.False(t, score.SubmittedAt.IsZero())
}

func TestScore_AddCriteriaScore(t *testing.T) {
	score := NewScore(primitive.NewObjectID(), primitive.NewObjectID(), primitive.NewObjectID(), "round1", 0)

	score.AddCriteriaScore("technique", 8.5)
	score.AddCriteriaScore("creativity", 9.0)

	assert.Equal(t, 8.5, score.CriteriaScores["technique"])
	assert.Equal(t, 9.0, score.CriteriaScores["creativity"])
}

func TestScore_AddCriteriaScore_InitializesMap(t *testing.T) {
	score := &Score{}

	score.AddCriteriaScore("technique", 8.5)

	assert.NotNil(t, score.CriteriaScores)
	assert.Equal(t, 8.5, score.CriteriaScores["technique"])
}

func TestScore_CalculateTotalFromCriteria(t *testing.T) {
	score := NewScore(primitive.NewObjectID(), primitive.NewObjectID(), primitive.NewObjectID(), "round1", 0)

	score.AddCriteriaScore("technique", 8.5)
	score.AddCriteriaScore("creativity", 9.0)
	score.AddCriteriaScore("execution", 7.5)

	total := score.CalculateTotalFromCriteria()

	assert.Equal(t, 25.0, total)
	assert.Equal(t, 25.0, score.TotalScore)
}

func TestScore_Validate(t *testing.T) {
	tests := []struct {
		name    string
		score   *Score
		wantErr bool
		errMsg  string
	}{
		{
			name: "valid score",
			score: NewScore(
				primitive.NewObjectID(),
				primitive.NewObjectID(),
				primitive.NewObjectID(),
				"round1",
				85.0,
			),
			wantErr: false,
		},
		{
			name: "missing competition ID",
			score: &Score{
				AthleteID:  primitive.NewObjectID(),
				JudgeID:    primitive.NewObjectID(),
				TotalScore: 85.0,
			},
			wantErr: true,
			errMsg:  "competition ID is required",
		},
		{
			name: "missing athlete ID",
			score: &Score{
				CompetitionID: primitive.NewObjectID(),
				JudgeID:       primitive.NewObjectID(),
				TotalScore:    85.0,
			},
			wantErr: true,
			errMsg:  "athlete ID is required",
		},
		{
			name: "missing judge ID",
			score: &Score{
				CompetitionID: primitive.NewObjectID(),
				AthleteID:     primitive.NewObjectID(),
				TotalScore:    85.0,
			},
			wantErr: true,
			errMsg:  "judge ID is required",
		},
		{
			name: "negative score",
			score: &Score{
				CompetitionID: primitive.NewObjectID(),
				AthleteID:     primitive.NewObjectID(),
				JudgeID:       primitive.NewObjectID(),
				TotalScore:    -10.0,
			},
			wantErr: true,
			errMsg:  "total score cannot be negative",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.score.Validate()
			if tt.wantErr {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestScore_PrepareForUpdate(t *testing.T) {
	score := NewScore(primitive.NewObjectID(), primitive.NewObjectID(), primitive.NewObjectID(), "round1", 85.0)
	oldTime := score.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	score.PrepareForUpdate()

	assert.True(t, score.UpdatedAt.After(oldTime))
}

func TestValidationError(t *testing.T) {
	err := &ValidationError{Message: "test error"}
	assert.Equal(t, "test error", err.Error())
}

// ============================================================================
// PARTICIPANT TESTS
// ============================================================================

func TestParticipant_StatusConstants(t *testing.T) {
	assert.Equal(t, "pending", ParticipantStatusPending)
	assert.Equal(t, "approved", ParticipantStatusApproved)
	assert.Equal(t, "rejected", ParticipantStatusRejected)
}

func TestNewParticipant(t *testing.T) {
	competitionID := primitive.NewObjectID()
	athleteID := primitive.NewObjectID()
	athleteName := "Test Athlete"

	participant := NewParticipant(competitionID, athleteID, athleteName)

	assert.NotEmpty(t, participant.ID)
	assert.Equal(t, competitionID, participant.CompetitionID)
	assert.Equal(t, athleteID, participant.AthleteID)
	assert.Equal(t, athleteName, participant.AthleteName)
	assert.Equal(t, ParticipantStatusPending, participant.Status)
	assert.False(t, participant.RegisteredAt.IsZero())
	assert.Nil(t, participant.ApprovedAt)
}

func TestParticipant_Approve(t *testing.T) {
	participant := NewParticipant(primitive.NewObjectID(), primitive.NewObjectID(), "Test Athlete")

	participant.Approve()

	assert.Equal(t, ParticipantStatusApproved, participant.Status)
	assert.NotNil(t, participant.ApprovedAt)
}

func TestParticipant_Reject(t *testing.T) {
	participant := NewParticipant(primitive.NewObjectID(), primitive.NewObjectID(), "Test Athlete")

	participant.Reject()

	assert.Equal(t, ParticipantStatusRejected, participant.Status)
}

func TestParticipant_IsApproved(t *testing.T) {
	participant := NewParticipant(primitive.NewObjectID(), primitive.NewObjectID(), "Test Athlete")

	assert.False(t, participant.IsApproved())

	participant.Approve()

	assert.True(t, participant.IsApproved())
}

func TestParticipant_IsPending(t *testing.T) {
	participant := NewParticipant(primitive.NewObjectID(), primitive.NewObjectID(), "Test Athlete")

	assert.True(t, participant.IsPending())

	participant.Approve()

	assert.False(t, participant.IsPending())
}

func TestParticipant_PrepareForUpdate(t *testing.T) {
	participant := NewParticipant(primitive.NewObjectID(), primitive.NewObjectID(), "Test Athlete")
	oldTime := participant.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	participant.PrepareForUpdate()

	assert.True(t, participant.UpdatedAt.After(oldTime))
}

// ============================================================================
// ROUND TESTS
// ============================================================================

func TestRoundStatus_Constants(t *testing.T) {
	assert.Equal(t, "pending", RoundStatusPending)
	assert.Equal(t, "active", RoundStatusActive)
	assert.Equal(t, "completed", RoundStatusCompleted)
}

func TestNewRound(t *testing.T) {
	competitionID := primitive.NewObjectID()
	name := "Semifinal"
	order := 2
	startTime := time.Now().Add(time.Hour)

	round := NewRound(competitionID, name, order, startTime)

	assert.NotEmpty(t, round.ID)
	assert.Equal(t, competitionID, round.CompetitionID)
	assert.Equal(t, name, round.Name)
	assert.Equal(t, order, round.Order)
	assert.Equal(t, startTime.Unix(), round.StartTime.Unix())
	assert.Equal(t, RoundStatusPending, round.Status)
	assert.Nil(t, round.EndTime)
}

func TestRound_CanStart(t *testing.T) {
	t.Run("returns true when pending and past start time", func(t *testing.T) {
		round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now().Add(-time.Hour))

		assert.True(t, round.CanStart())
	})

	t.Run("returns false when not pending", func(t *testing.T) {
		round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now().Add(-time.Hour))
		round.Status = RoundStatusActive

		assert.False(t, round.CanStart())
	})

	t.Run("returns false when start time is in future", func(t *testing.T) {
		round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now().Add(time.Hour))

		assert.False(t, round.CanStart())
	})
}

func TestRound_IsActive(t *testing.T) {
	round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now())

	assert.False(t, round.IsActive())

	round.Status = RoundStatusActive

	assert.True(t, round.IsActive())
}

func TestRound_IsCompleted(t *testing.T) {
	round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now())

	assert.False(t, round.IsCompleted())

	round.Status = RoundStatusCompleted

	assert.True(t, round.IsCompleted())
}

func TestRound_Start(t *testing.T) {
	t.Run("starts round when can start", func(t *testing.T) {
		round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now().Add(-time.Hour))

		err := round.Start()

		assert.NoError(t, err)
		assert.Equal(t, RoundStatusActive, round.Status)
	})

	t.Run("returns error when cannot start", func(t *testing.T) {
		round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now().Add(time.Hour))

		err := round.Start()

		assert.Error(t, err)
		assert.Equal(t, ErrInvalidStatus, err)
	})
}

func TestRound_Complete(t *testing.T) {
	t.Run("completes round when active", func(t *testing.T) {
		round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now().Add(-time.Hour))
		round.Status = RoundStatusActive

		err := round.Complete()

		assert.NoError(t, err)
		assert.Equal(t, RoundStatusCompleted, round.Status)
		assert.NotNil(t, round.EndTime)
	})

	t.Run("returns error when not active", func(t *testing.T) {
		round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now())

		err := round.Complete()

		assert.Error(t, err)
		assert.Equal(t, ErrInvalidStatus, err)
	})
}

func TestRound_PrepareForUpdate(t *testing.T) {
	round := NewRound(primitive.NewObjectID(), "Test", 1, time.Now())
	oldTime := round.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	round.PrepareForUpdate()

	assert.True(t, round.UpdatedAt.After(oldTime))
}

// ============================================================================
// TOURNAMENT TESTS
// ============================================================================

func TestTournamentScoring_Constants(t *testing.T) {
	assert.Equal(t, "points", TournamentScoringPoints)
	assert.Equal(t, "time", TournamentScoringTime)
	assert.Equal(t, "elimination", TournamentScoringElimination)
	assert.Equal(t, "best_result", TournamentScoringBestResult)
	assert.Equal(t, "custom", TournamentScoringCustom)
}

func TestTournamentStatus_Constants(t *testing.T) {
	assert.Equal(t, "upcoming", TournamentStatusUpcoming)
	assert.Equal(t, "live", TournamentStatusLive)
	assert.Equal(t, "completed", TournamentStatusCompleted)
	assert.Equal(t, "cancelled", TournamentStatusCancelled)
	assert.Equal(t, "postponed", TournamentStatusPostponed)
}

func TestTournamentRegistration_Constants(t *testing.T) {
	assert.Equal(t, "open", TournamentRegistrationOpen)
	assert.Equal(t, "closed", TournamentRegistrationClosed)
	assert.Equal(t, "full", TournamentRegistrationFull)
}

func TestNewTournament(t *testing.T) {
	organizerID := primitive.NewObjectID()

	tournament := NewTournament(
		"Championship 2025",
		"Annual championship event",
		organizerID,
		"motocross",
		"professional",
		"championship",
	)

	assert.NotEmpty(t, tournament.ID)
	assert.Equal(t, "Championship 2025", tournament.Title)
	assert.Equal(t, "Annual championship event", tournament.Description)
	assert.Equal(t, organizerID, tournament.OrganizerID)
	assert.Equal(t, "motocross", tournament.SportType)
	assert.Equal(t, "professional", tournament.Discipline)
	assert.Equal(t, "championship", tournament.Format)
	assert.Equal(t, TournamentScoringPoints, tournament.ScoringSystem)
	assert.Equal(t, TournamentStatusUpcoming, tournament.Status)
	assert.Equal(t, TournamentRegistrationOpen, tournament.Registration.RegistrationStatus)
	assert.Equal(t, 100, tournament.Registration.MaxParticipants)
	assert.False(t, tournament.IsLive)
	assert.True(t, tournament.IsPublic)

	// Check default points map
	assert.Equal(t, 25, tournament.ScoringConfig.PointsMap[1])
	assert.Equal(t, 18, tournament.ScoringConfig.PointsMap[2])
	assert.Equal(t, 15, tournament.ScoringConfig.PointsMap[3])
}

func TestTournament_CanRegister(t *testing.T) {
	t.Run("returns true when registration is open", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

		assert.True(t, tournament.CanRegister())
	})

	t.Run("returns false when registration is closed", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Registration.RegistrationStatus = TournamentRegistrationClosed

		assert.False(t, tournament.CanRegister())
	})

	t.Run("returns false when deadline has passed and no late registration", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		pastDeadline := time.Now().Add(-24 * time.Hour)
		tournament.Registration.RegistrationDeadline = &pastDeadline

		assert.False(t, tournament.CanRegister())
	})

	t.Run("returns true when deadline passed but late registration allowed", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		pastDeadline := time.Now().Add(-24 * time.Hour)
		tournament.Registration.RegistrationDeadline = &pastDeadline
		tournament.Registration.AllowLateRegistration = true

		assert.True(t, tournament.CanRegister())
	})

	t.Run("returns false when max participants reached", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Registration.MaxParticipants = 10
		tournament.Registration.CurrentParticipants = 10

		assert.False(t, tournament.CanRegister())
	})

	t.Run("returns false when tournament is live and no late registration", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Status = TournamentStatusLive

		assert.False(t, tournament.CanRegister())
	})
}

func TestTournament_IsRegistrationOpen(t *testing.T) {
	t.Run("returns true when open and upcoming", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

		assert.True(t, tournament.IsRegistrationOpen())
	})

	t.Run("returns false when status is closed", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Registration.RegistrationStatus = TournamentRegistrationClosed

		assert.False(t, tournament.IsRegistrationOpen())
	})
}

func TestTournament_IsAthleteRegistered(t *testing.T) {
	t.Run("returns true for registered athlete", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		athleteID := primitive.NewObjectID()
		tournament.RegisteredAthleteIDs = []primitive.ObjectID{athleteID}

		assert.True(t, tournament.IsAthleteRegistered(athleteID))
	})

	t.Run("returns false for unregistered athlete", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

		assert.False(t, tournament.IsAthleteRegistered(primitive.NewObjectID()))
	})
}

func TestTournament_AddAthlete(t *testing.T) {
	t.Run("successfully adds athlete", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		athleteID := primitive.NewObjectID()

		err := tournament.AddAthlete(athleteID)

		assert.NoError(t, err)
		assert.True(t, tournament.IsAthleteRegistered(athleteID))
		assert.Equal(t, 1, tournament.Registration.CurrentParticipants)
	})

	t.Run("returns error for already registered athlete", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		athleteID := primitive.NewObjectID()
		tournament.AddAthlete(athleteID)

		err := tournament.AddAthlete(athleteID)

		assert.Error(t, err)
		assert.Equal(t, ErrTournamentAlreadyRegistered, err)
	})

	t.Run("returns error when registration closed", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Registration.RegistrationStatus = TournamentRegistrationClosed

		err := tournament.AddAthlete(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrTournamentRegistrationClosed, err)
	})

	t.Run("marks as full when max participants reached", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Registration.MaxParticipants = 2

		tournament.AddAthlete(primitive.NewObjectID())
		tournament.AddAthlete(primitive.NewObjectID())

		assert.Equal(t, TournamentRegistrationFull, tournament.Registration.RegistrationStatus)
	})
}

func TestTournament_RemoveAthlete(t *testing.T) {
	t.Run("successfully removes athlete", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		athleteID := primitive.NewObjectID()
		tournament.AddAthlete(athleteID)

		err := tournament.RemoveAthlete(athleteID)

		assert.NoError(t, err)
		assert.False(t, tournament.IsAthleteRegistered(athleteID))
		assert.Equal(t, 0, tournament.Registration.CurrentParticipants)
	})

	t.Run("returns error for unregistered athlete", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

		err := tournament.RemoveAthlete(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrTournamentNotRegistered, err)
	})

	t.Run("reopens registration when was full", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Registration.MaxParticipants = 2
		athlete1 := primitive.NewObjectID()
		athlete2 := primitive.NewObjectID()
		tournament.AddAthlete(athlete1)
		tournament.AddAthlete(athlete2)

		tournament.RemoveAthlete(athlete1)

		assert.Equal(t, TournamentRegistrationOpen, tournament.Registration.RegistrationStatus)
	})
}

func TestTournament_AddCompetition(t *testing.T) {
	t.Run("successfully adds competition", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		competitionID := primitive.NewObjectID()

		err := tournament.AddCompetition(competitionID)

		assert.NoError(t, err)
		assert.Contains(t, tournament.CompetitionIDs, competitionID)
		assert.Equal(t, 1, tournament.TotalCompetitions)
	})

	t.Run("returns error for already added competition", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		competitionID := primitive.NewObjectID()
		tournament.AddCompetition(competitionID)

		err := tournament.AddCompetition(competitionID)

		assert.Error(t, err)
		assert.Equal(t, ErrTournamentCompetitionAlreadyAdded, err)
	})
}

func TestTournament_RemoveCompetition(t *testing.T) {
	t.Run("successfully removes competition", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		competitionID := primitive.NewObjectID()
		tournament.AddCompetition(competitionID)

		err := tournament.RemoveCompetition(competitionID)

		assert.NoError(t, err)
		assert.NotContains(t, tournament.CompetitionIDs, competitionID)
		assert.Equal(t, 0, tournament.TotalCompetitions)
	})

	t.Run("returns error for non-existent competition", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

		err := tournament.RemoveCompetition(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrTournamentCompetitionNotFound, err)
	})
}

func TestTournament_MarkAsLive(t *testing.T) {
	tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

	tournament.MarkAsLive()

	assert.Equal(t, TournamentStatusLive, tournament.Status)
	assert.True(t, tournament.IsLive)
}

func TestTournament_MarkAsCompleted(t *testing.T) {
	tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
	tournament.MarkAsLive()

	tournament.MarkAsCompleted()

	assert.Equal(t, TournamentStatusCompleted, tournament.Status)
	assert.False(t, tournament.IsLive)
}

func TestTournament_PublishResults(t *testing.T) {
	t.Run("successfully publishes when completed", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.MarkAsCompleted()

		err := tournament.PublishResults()

		assert.NoError(t, err)
		assert.True(t, tournament.IsResultsPublished)
		assert.NotNil(t, tournament.ResultsPublishedAt)
	})

	t.Run("successfully publishes when live", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.MarkAsLive()

		err := tournament.PublishResults()

		assert.NoError(t, err)
		assert.True(t, tournament.IsResultsPublished)
	})

	t.Run("returns error when upcoming", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

		err := tournament.PublishResults()

		assert.Error(t, err)
		assert.Equal(t, ErrTournamentInvalidStatus, err)
	})

	t.Run("returns error when cancelled", func(t *testing.T) {
		tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
		tournament.Status = TournamentStatusCancelled

		err := tournament.PublishResults()

		assert.Error(t, err)
		assert.Equal(t, ErrTournamentInvalidStatus, err)
	})
}

func TestTournament_IncrementCompletedRounds(t *testing.T) {
	tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")

	tournament.IncrementCompletedRounds()
	tournament.IncrementCompletedRounds()

	assert.Equal(t, 2, tournament.CompletedRounds)
}

func TestTournament_IsOwner(t *testing.T) {
	organizerID := primitive.NewObjectID()
	tournament := NewTournament("Test", "Description", organizerID, "sport", "discipline", "format")

	assert.True(t, tournament.IsOwner(organizerID))
	assert.False(t, tournament.IsOwner(primitive.NewObjectID()))
}

func TestTournament_Validate(t *testing.T) {
	tests := []struct {
		name       string
		tournament *Tournament
		wantErr    bool
	}{
		{
			name: "valid tournament",
			tournament: func() *Tournament {
				t := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
				t.Schedule = TournamentSchedule{
					StartDate: time.Now(),
					EndDate:   time.Now().Add(30 * 24 * time.Hour),
				}
				return t
			}(),
			wantErr: false,
		},
		{
			name: "empty title",
			tournament: func() *Tournament {
				t := NewTournament("", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
				return t
			}(),
			wantErr: true,
		},
		{
			name: "empty description",
			tournament: func() *Tournament {
				t := NewTournament("Test", "", primitive.NewObjectID(), "sport", "discipline", "format")
				return t
			}(),
			wantErr: true,
		},
		{
			name: "missing organizer ID",
			tournament: func() *Tournament {
				t := NewTournament("Test", "Description", primitive.ObjectID{}, "sport", "discipline", "format")
				return t
			}(),
			wantErr: true,
		},
		{
			name: "end date before start date",
			tournament: func() *Tournament {
				t := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
				t.Schedule = TournamentSchedule{
					StartDate: time.Now().Add(24 * time.Hour),
					EndDate:   time.Now(),
				}
				return t
			}(),
			wantErr: true,
		},
		{
			name: "missing scoring system",
			tournament: func() *Tournament {
				t := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
				t.ScoringSystem = ""
				return t
			}(),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.tournament.Validate()
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestTournament_PrepareForUpdate(t *testing.T) {
	tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
	oldTime := tournament.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	tournament.PrepareForUpdate()

	assert.True(t, tournament.UpdatedAt.After(oldTime))
}

func TestTournamentDomainErrors(t *testing.T) {
	errors := []struct {
		err     error
		message string
	}{
		{ErrTournamentAlreadyRegistered, "athlete already registered in tournament"},
		{ErrTournamentNotRegistered, "athlete not registered in tournament"},
		{ErrTournamentRegistrationClosed, "tournament registration is closed"},
		{ErrTournamentInvalidStatus, "invalid tournament status"},
		{ErrTournamentInvalidInput, "invalid tournament input data"},
		{ErrTournamentCompetitionAlreadyAdded, "competition already added to tournament"},
		{ErrTournamentCompetitionNotFound, "competition not found in tournament"},
	}

	for _, e := range errors {
		t.Run(e.message, func(t *testing.T) {
			assert.Equal(t, e.message, e.err.Error())
		})
	}
}

// ============================================================================
// BENCHMARKS
// ============================================================================

func BenchmarkLeaderboard_SortByScore(b *testing.B) {
	leaderboard := NewLeaderboard(primitive.NewObjectID())
	for i := 0; i < 100; i++ {
		leaderboard.AddEntry(LeaderboardEntry{
			AthleteID:   primitive.NewObjectID(),
			AthleteName: "Athlete",
			TotalScore:  float64(100 - i),
		})
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		leaderboard.SortByScore()
	}
}

func BenchmarkTournament_AddAthlete(b *testing.B) {
	tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
	tournament.Registration.MaxParticipants = b.N + 1

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		tournament.AddAthlete(primitive.NewObjectID())
	}
}

func BenchmarkTournament_IsAthleteRegistered(b *testing.B) {
	tournament := NewTournament("Test", "Description", primitive.NewObjectID(), "sport", "discipline", "format")
	tournament.Registration.MaxParticipants = 1000
	athletes := make([]primitive.ObjectID, 1000)
	for i := 0; i < 1000; i++ {
		athletes[i] = primitive.NewObjectID()
		tournament.AddAthlete(athletes[i])
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		tournament.IsAthleteRegistered(athletes[i%1000])
	}
}

// ============================================================================
// CATEGORY TESTS
// ============================================================================

func TestCategoryStatus_Constants(t *testing.T) {
	assert.Equal(t, "active", CategoryStatusActive)
	assert.Equal(t, "inactive", CategoryStatusInactive)
	assert.Equal(t, "closed", CategoryStatusClosed)
}

func TestNewCategory(t *testing.T) {
	competitionID := primitive.NewObjectID()
	name := "Men's Pro"

	category := NewCategory(competitionID, name)

	assert.NotEmpty(t, category.ID)
	assert.Equal(t, competitionID, category.CompetitionID)
	assert.Equal(t, name, category.Name)
	assert.Equal(t, 50, category.MaxParticipants)
	assert.Equal(t, 1, category.MinParticipants)
	assert.Equal(t, CategoryStatusActive, category.Status)
	assert.Equal(t, 0, category.Order)
	assert.False(t, category.CreatedAt.IsZero())
}

func TestCategory_AddParticipant(t *testing.T) {
	t.Run("successfully adds participant", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")
		participantID := primitive.NewObjectID()

		err := category.AddParticipant(participantID)

		assert.NoError(t, err)
		assert.Contains(t, category.ParticipantIDs, participantID)
		assert.Equal(t, 1, category.CurrentParticipants)
	})

	t.Run("returns error for already added participant", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")
		participantID := primitive.NewObjectID()
		category.AddParticipant(participantID)

		err := category.AddParticipant(participantID)

		assert.Error(t, err)
		assert.Equal(t, ErrAlreadyInCategory, err)
	})

	t.Run("returns error when category is full", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")
		category.MaxParticipants = 2
		category.AddParticipant(primitive.NewObjectID())
		category.AddParticipant(primitive.NewObjectID())

		err := category.AddParticipant(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrCategoryFull, err)
	})
}

func TestCategory_RemoveParticipant(t *testing.T) {
	t.Run("successfully removes participant", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")
		participantID := primitive.NewObjectID()
		category.AddParticipant(participantID)

		err := category.RemoveParticipant(participantID)

		assert.NoError(t, err)
		assert.NotContains(t, category.ParticipantIDs, participantID)
		assert.Equal(t, 0, category.CurrentParticipants)
	})

	t.Run("returns error for non-existent participant", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")

		err := category.RemoveParticipant(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrNotInCategory, err)
	})
}

func TestCategory_AddJudge(t *testing.T) {
	t.Run("successfully adds judge", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")
		judgeID := primitive.NewObjectID()

		err := category.AddJudge(judgeID)

		assert.NoError(t, err)
		assert.Contains(t, category.JudgeIDs, judgeID)
	})

	t.Run("returns error for already added judge", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")
		judgeID := primitive.NewObjectID()
		category.AddJudge(judgeID)

		err := category.AddJudge(judgeID)

		assert.Error(t, err)
		assert.Equal(t, ErrAlreadyJudge, err)
	})
}

func TestCategory_RemoveJudge(t *testing.T) {
	t.Run("successfully removes judge", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")
		judgeID := primitive.NewObjectID()
		category.AddJudge(judgeID)

		err := category.RemoveJudge(judgeID)

		assert.NoError(t, err)
		assert.NotContains(t, category.JudgeIDs, judgeID)
	})

	t.Run("returns error for non-existent judge", func(t *testing.T) {
		category := NewCategory(primitive.NewObjectID(), "Test")

		err := category.RemoveJudge(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrNotJudgeInCategory, err)
	})
}

func TestCategory_IsParticipant(t *testing.T) {
	category := NewCategory(primitive.NewObjectID(), "Test")
	participantID := primitive.NewObjectID()
	category.AddParticipant(participantID)

	assert.True(t, category.IsParticipant(participantID))
	assert.False(t, category.IsParticipant(primitive.NewObjectID()))
}

func TestCategory_IsJudge(t *testing.T) {
	category := NewCategory(primitive.NewObjectID(), "Test")
	judgeID := primitive.NewObjectID()
	category.AddJudge(judgeID)

	assert.True(t, category.IsJudge(judgeID))
	assert.False(t, category.IsJudge(primitive.NewObjectID()))
}

func TestCategory_PrepareForUpdate(t *testing.T) {
	category := NewCategory(primitive.NewObjectID(), "Test")
	oldTime := category.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	category.PrepareForUpdate()

	assert.True(t, category.UpdatedAt.After(oldTime))
}

func TestCategoryDomainErrors(t *testing.T) {
	errors := []struct {
		err     error
		message string
	}{
		{ErrCategoryNotFound, "category not found"},
		{ErrAlreadyInCategory, "participant already in category"},
		{ErrNotInCategory, "participant not in category"},
		{ErrCategoryFull, "category is full"},
		{ErrNotJudgeInCategory, "user is not a judge in this category"},
	}

	for _, e := range errors {
		t.Run(e.message, func(t *testing.T) {
			assert.Equal(t, e.message, e.err.Error())
		})
	}
}

// ============================================================================
// JUDGE INVITATION TESTS
// ============================================================================

func TestInvitationStatus_Constants(t *testing.T) {
	assert.Equal(t, "pending", InvitationStatusPending)
	assert.Equal(t, "accepted", InvitationStatusAccepted)
	assert.Equal(t, "declined", InvitationStatusDeclined)
	assert.Equal(t, "expired", InvitationStatusExpired)
}

func TestNewJudgeInvitation(t *testing.T) {
	competitionID := primitive.NewObjectID()
	invitedUserID := primitive.NewObjectID()
	invitedByID := primitive.NewObjectID()

	invitation := NewJudgeInvitation(
		competitionID,
		invitedUserID,
		invitedByID,
		"John Doe",
		"Admin User",
	)

	assert.NotEmpty(t, invitation.ID)
	assert.Equal(t, competitionID, invitation.CompetitionID)
	assert.Equal(t, invitedUserID, invitation.InvitedUserID)
	assert.Equal(t, invitedByID, invitation.InvitedByID)
	assert.Equal(t, "John Doe", invitation.InvitedUserName)
	assert.Equal(t, "Admin User", invitation.InvitedByName)
	assert.Equal(t, InvitationStatusPending, invitation.Status)
	assert.NotNil(t, invitation.ExpiresAt)
	assert.Nil(t, invitation.RespondedAt)
}

func TestJudgeInvitation_Accept(t *testing.T) {
	t.Run("successfully accepts invitation", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)

		err := invitation.Accept("Happy to help!")

		assert.NoError(t, err)
		assert.Equal(t, InvitationStatusAccepted, invitation.Status)
		assert.NotNil(t, invitation.RespondedAt)
		assert.Equal(t, "Happy to help!", invitation.Response)
	})

	t.Run("returns error when not pending", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)
		invitation.Status = InvitationStatusDeclined

		err := invitation.Accept("test")

		assert.Error(t, err)
		assert.Equal(t, ErrInvitationNotPending, err)
	})

	t.Run("returns error when expired", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)
		pastDate := time.Now().Add(-24 * time.Hour)
		invitation.ExpiresAt = &pastDate

		err := invitation.Accept("test")

		assert.Error(t, err)
		assert.Equal(t, ErrInvitationExpired, err)
	})
}

func TestJudgeInvitation_Decline(t *testing.T) {
	t.Run("successfully declines invitation", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)

		err := invitation.Decline("Not available that day")

		assert.NoError(t, err)
		assert.Equal(t, InvitationStatusDeclined, invitation.Status)
		assert.NotNil(t, invitation.RespondedAt)
		assert.Equal(t, "Not available that day", invitation.Response)
	})

	t.Run("returns error when not pending", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)
		invitation.Status = InvitationStatusAccepted

		err := invitation.Decline("test")

		assert.Error(t, err)
		assert.Equal(t, ErrInvitationNotPending, err)
	})
}

func TestJudgeInvitation_IsExpired(t *testing.T) {
	t.Run("returns true when past expiry date", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)
		pastDate := time.Now().Add(-24 * time.Hour)
		invitation.ExpiresAt = &pastDate

		assert.True(t, invitation.IsExpired())
	})

	t.Run("returns false when before expiry date", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)

		assert.False(t, invitation.IsExpired())
	})

	t.Run("returns false when no expiry date", func(t *testing.T) {
		invitation := NewJudgeInvitation(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"User",
			"Admin",
		)
		invitation.ExpiresAt = nil

		assert.False(t, invitation.IsExpired())
	})
}

func TestJudgeInvitation_MarkExpired(t *testing.T) {
	invitation := NewJudgeInvitation(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"User",
		"Admin",
	)

	invitation.MarkExpired()

	assert.Equal(t, InvitationStatusExpired, invitation.Status)
}

func TestJudgeInvitation_PrepareForUpdate(t *testing.T) {
	invitation := NewJudgeInvitation(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"User",
		"Admin",
	)
	oldTime := invitation.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	invitation.PrepareForUpdate()

	assert.True(t, invitation.UpdatedAt.After(oldTime))
}

func TestJudgeInvitationDomainErrors(t *testing.T) {
	errors := []struct {
		err     error
		message string
	}{
		{ErrInvitationNotFound, "judge invitation not found"},
		{ErrInvitationNotPending, "invitation is not pending"},
		{ErrInvitationExpired, "invitation has expired"},
		{ErrAlreadyInvited, "user already has pending invitation"},
	}

	for _, e := range errors {
		t.Run(e.message, func(t *testing.T) {
			assert.Equal(t, e.message, e.err.Error())
		})
	}
}

// ============================================================================
// TOURNAMENT REGISTRATION TESTS
// ============================================================================

func TestRegistrationType_Constants(t *testing.T) {
	assert.Equal(t, "full", RegistrationTypeFull)
	assert.Equal(t, "individual", RegistrationTypeIndividual)
}

func TestRegistrationStatus_Constants(t *testing.T) {
	assert.Equal(t, "pending", RegistrationStatusPending)
	assert.Equal(t, "approved", RegistrationStatusApproved)
	assert.Equal(t, "rejected", RegistrationStatusRejected)
	assert.Equal(t, "cancelled", RegistrationStatusCancelled)
	assert.Equal(t, "withdrawn", RegistrationStatusWithdrawn)
}

func TestPaymentStatus_Constants(t *testing.T) {
	assert.Equal(t, "pending", PaymentStatusPending)
	assert.Equal(t, "completed", PaymentStatusCompleted)
	assert.Equal(t, "failed", PaymentStatusFailed)
	assert.Equal(t, "refunded", PaymentStatusRefunded)
	assert.Equal(t, "waived", PaymentStatusWaived)
}

func TestNewTournamentRegistration(t *testing.T) {
	tournamentID := primitive.NewObjectID()
	athleteID := primitive.NewObjectID()

	registration := NewTournamentRegistration(
		tournamentID,
		athleteID,
		"John Athlete",
		"john@example.com",
		RegistrationTypeFull,
	)

	assert.NotEmpty(t, registration.ID)
	assert.Equal(t, tournamentID, registration.TournamentID)
	assert.Equal(t, athleteID, registration.AthleteID)
	assert.Equal(t, "John Athlete", registration.AthleteName)
	assert.Equal(t, "john@example.com", registration.AthleteEmail)
	assert.Equal(t, RegistrationTypeFull, registration.RegistrationType)
	assert.Equal(t, RegistrationStatusPending, registration.Status)
	assert.Equal(t, PaymentStatusPending, registration.Payment.Status)
}

func TestTournamentRegistration_IsFullRegistration(t *testing.T) {
	fullReg := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)
	individualReg := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeIndividual,
	)

	assert.True(t, fullReg.IsFullRegistration())
	assert.False(t, individualReg.IsFullRegistration())
}

func TestTournamentRegistration_IsIndividualRegistration(t *testing.T) {
	individualReg := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeIndividual,
	)
	fullReg := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)

	assert.True(t, individualReg.IsIndividualRegistration())
	assert.False(t, fullReg.IsIndividualRegistration())
}

func TestTournamentRegistration_StatusChecks(t *testing.T) {
	registration := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)

	// Test pending
	assert.True(t, registration.IsPending())
	assert.False(t, registration.IsActive())

	// Test approved
	registration.Status = RegistrationStatusApproved
	assert.True(t, registration.IsActive())
	assert.False(t, registration.IsPending())

	// Test rejected
	registration.Status = RegistrationStatusRejected
	assert.True(t, registration.IsRejected())

	// Test withdrawn
	registration.Status = RegistrationStatusWithdrawn
	assert.True(t, registration.IsWithdrawn())

	// Test cancelled
	registration.Status = RegistrationStatusCancelled
	assert.True(t, registration.IsCancelled())
}

func TestTournamentRegistration_RequiresApproval(t *testing.T) {
	registration := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)

	registration.RequiresApproval()

	assert.True(t, registration.Approval.IsRequired)
	assert.Equal(t, RegistrationStatusPending, registration.Approval.Status)
	assert.Equal(t, RegistrationStatusPending, registration.Status)
}

func TestTournamentRegistration_Approve(t *testing.T) {
	t.Run("successfully approves registration", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)
		registration.RequiresApproval()
		adminID := primitive.NewObjectID()

		err := registration.Approve(adminID, "Admin User")

		assert.NoError(t, err)
		assert.Equal(t, RegistrationStatusApproved, registration.Status)
		assert.NotNil(t, registration.Approval.ApprovedAt)
	})

	t.Run("returns error when no approval required", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		err := registration.Approve(primitive.NewObjectID(), "Admin")

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationNoApprovalRequired, err)
	})

	t.Run("returns error when not pending", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)
		registration.RequiresApproval()
		registration.Status = RegistrationStatusApproved

		err := registration.Approve(primitive.NewObjectID(), "Admin")

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationInvalidStatus, err)
	})
}

func TestTournamentRegistration_Reject(t *testing.T) {
	t.Run("successfully rejects registration", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)
		registration.RequiresApproval()
		adminID := primitive.NewObjectID()

		err := registration.Reject(adminID, "Admin User", "Missing documents")

		assert.NoError(t, err)
		assert.Equal(t, RegistrationStatusRejected, registration.Status)
		assert.Equal(t, "Missing documents", registration.Approval.RejectionReason)
		assert.NotNil(t, registration.Approval.RejectedAt)
	})

	t.Run("returns error when no approval required", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		err := registration.Reject(primitive.NewObjectID(), "Admin", "reason")

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationNoApprovalRequired, err)
	})

	t.Run("returns error when status is not pending", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)
		registration.RequiresApproval()
		// First approve, then try to reject
		registration.Approve(primitive.NewObjectID(), "Admin")

		err := registration.Reject(primitive.NewObjectID(), "Admin", "reason")

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationInvalidStatus, err)
	})
}

func TestTournamentRegistration_AddSelectedCompetition(t *testing.T) {
	t.Run("successfully adds competition to individual registration", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeIndividual,
		)
		competitionID := primitive.NewObjectID()

		err := registration.AddSelectedCompetition(competitionID)

		assert.NoError(t, err)
		assert.Contains(t, registration.SelectedCompetitionIDs, competitionID)
	})

	t.Run("returns error for full registration", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		err := registration.AddSelectedCompetition(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationNotIndividual, err)
	})

	t.Run("returns error for already selected competition", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeIndividual,
		)
		competitionID := primitive.NewObjectID()
		registration.AddSelectedCompetition(competitionID)

		err := registration.AddSelectedCompetition(competitionID)

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationCompetitionAlreadySelected, err)
	})
}

func TestTournamentRegistration_RemoveSelectedCompetition(t *testing.T) {
	t.Run("successfully removes competition", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeIndividual,
		)
		competitionID := primitive.NewObjectID()
		registration.AddSelectedCompetition(competitionID)

		err := registration.RemoveSelectedCompetition(competitionID)

		assert.NoError(t, err)
		assert.NotContains(t, registration.SelectedCompetitionIDs, competitionID)
	})

	t.Run("returns error for non-existent competition", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeIndividual,
		)

		err := registration.RemoveSelectedCompetition(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationCompetitionNotFound, err)
	})

	t.Run("returns error for full registration type", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		err := registration.RemoveSelectedCompetition(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationNotIndividual, err)
	})
}

func TestTournamentRegistration_PaymentMethods(t *testing.T) {
	t.Run("marks payment completed", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		registration.MarkPaymentCompleted("TXN123", "credit_card")

		assert.Equal(t, PaymentStatusCompleted, registration.Payment.Status)
		assert.Equal(t, "TXN123", registration.Payment.TransactionID)
		assert.Equal(t, "credit_card", registration.Payment.PaymentMethod)
		assert.NotNil(t, registration.Payment.PaymentDate)
	})

	t.Run("marks payment failed", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		registration.MarkPaymentFailed()

		assert.Equal(t, PaymentStatusFailed, registration.Payment.Status)
	})

	t.Run("refunds payment", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)
		registration.MarkPaymentCompleted("TXN123", "credit_card")

		registration.RefundPayment(50.0, "Cancelled event")

		assert.Equal(t, PaymentStatusRefunded, registration.Payment.Status)
		assert.Equal(t, 50.0, *registration.Payment.RefundAmount)
		assert.Equal(t, "Cancelled event", registration.Payment.RefundReason)
	})

	t.Run("waives payment", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		registration.WaivePayment()

		assert.Equal(t, PaymentStatusWaived, registration.Payment.Status)
	})
}

func TestTournamentRegistration_Withdraw(t *testing.T) {
	t.Run("successfully withdraws", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)
		registration.Status = RegistrationStatusApproved

		err := registration.Withdraw("Personal reasons")

		assert.NoError(t, err)
		assert.Equal(t, RegistrationStatusWithdrawn, registration.Status)
		assert.Equal(t, "Personal reasons", registration.WithdrawalReason)
		assert.NotNil(t, registration.WithdrawnAt)
	})

	t.Run("returns error when not active", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		err := registration.Withdraw("reason")

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationNotActive, err)
	})
}

func TestTournamentRegistration_Cancel(t *testing.T) {
	t.Run("successfully cancels pending registration", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		err := registration.Cancel()

		assert.NoError(t, err)
		assert.Equal(t, RegistrationStatusCancelled, registration.Status)
	})

	t.Run("returns error when already active", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)
		registration.Status = RegistrationStatusApproved

		err := registration.Cancel()

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationAlreadyActive, err)
	})
}

func TestTournamentRegistration_RecordParticipation(t *testing.T) {
	registration := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)

	registration.RecordParticipation()
	registration.RecordParticipation()

	assert.Equal(t, 2, registration.CompetitionsCompleted)
	assert.NotNil(t, registration.LastParticipation)
}

func TestTournamentRegistration_RecordMissedCompetition(t *testing.T) {
	registration := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)

	registration.RecordMissedCompetition()
	registration.RecordMissedCompetition()

	assert.Equal(t, 2, registration.CompetitionsMissed)
}

func TestTournamentRegistration_SetRaceNumber(t *testing.T) {
	registration := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)

	registration.SetRaceNumber(42)

	assert.NotNil(t, registration.RaceNumber)
	assert.Equal(t, 42, *registration.RaceNumber)
}

func TestTournamentRegistration_AddDocument(t *testing.T) {
	t.Run("adds document", func(t *testing.T) {
		registration := NewTournamentRegistration(
			primitive.NewObjectID(),
			primitive.NewObjectID(),
			"Athlete",
			"athlete@test.com",
			RegistrationTypeFull,
		)

		registration.AddDocument("license", "https://example.com/license.pdf")

		assert.Equal(t, "https://example.com/license.pdf", registration.DocumentUrls["license"])
	})

	t.Run("initializes map if nil", func(t *testing.T) {
		registration := &TournamentRegistration{}

		registration.AddDocument("insurance", "https://example.com/insurance.pdf")

		assert.NotNil(t, registration.DocumentUrls)
		assert.Equal(t, "https://example.com/insurance.pdf", registration.DocumentUrls["insurance"])
	})
}

func TestTournamentRegistration_Validate(t *testing.T) {
	tests := []struct {
		name    string
		reg     *TournamentRegistration
		wantErr bool
		errType error
	}{
		{
			name: "valid full registration",
			reg: NewTournamentRegistration(
				primitive.NewObjectID(),
				primitive.NewObjectID(),
				"Athlete",
				"athlete@test.com",
				RegistrationTypeFull,
			),
			wantErr: false,
		},
		{
			name: "valid individual registration with competition",
			reg: func() *TournamentRegistration {
				r := NewTournamentRegistration(
					primitive.NewObjectID(),
					primitive.NewObjectID(),
					"Athlete",
					"athlete@test.com",
					RegistrationTypeIndividual,
				)
				r.AddSelectedCompetition(primitive.NewObjectID())
				return r
			}(),
			wantErr: false,
		},
		{
			name: "missing tournament ID",
			reg: &TournamentRegistration{
				AthleteID:        primitive.NewObjectID(),
				RegistrationType: RegistrationTypeFull,
			},
			wantErr: true,
			errType: ErrRegistrationInvalidInput,
		},
		{
			name: "missing athlete ID",
			reg: &TournamentRegistration{
				TournamentID:     primitive.NewObjectID(),
				RegistrationType: RegistrationTypeFull,
			},
			wantErr: true,
			errType: ErrRegistrationInvalidInput,
		},
		{
			name: "invalid registration type",
			reg: &TournamentRegistration{
				TournamentID:     primitive.NewObjectID(),
				AthleteID:        primitive.NewObjectID(),
				RegistrationType: "invalid",
			},
			wantErr: true,
			errType: ErrRegistrationInvalidInput,
		},
		{
			name: "individual registration without competitions",
			reg: NewTournamentRegistration(
				primitive.NewObjectID(),
				primitive.NewObjectID(),
				"Athlete",
				"athlete@test.com",
				RegistrationTypeIndividual,
			),
			wantErr: true,
			errType: ErrRegistrationNoCompetitionsSelected,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.reg.Validate()
			if tt.wantErr {
				assert.Error(t, err)
				if tt.errType != nil {
					assert.Equal(t, tt.errType, err)
				}
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestTournamentRegistration_PrepareForUpdate(t *testing.T) {
	registration := NewTournamentRegistration(
		primitive.NewObjectID(),
		primitive.NewObjectID(),
		"Athlete",
		"athlete@test.com",
		RegistrationTypeFull,
	)
	oldTime := registration.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	registration.PrepareForUpdate()

	assert.True(t, registration.UpdatedAt.After(oldTime))
}

func TestTournamentRegistrationDomainErrors(t *testing.T) {
	errors := []struct {
		err     error
		message string
	}{
		{ErrRegistrationInvalidInput, "invalid registration input data"},
		{ErrRegistrationInvalidStatus, "invalid registration status"},
		{ErrRegistrationNoApprovalRequired, "registration does not require approval"},
		{ErrRegistrationNotIndividual, "registration is not individual type"},
		{ErrRegistrationCompetitionAlreadySelected, "competition already selected"},
		{ErrRegistrationCompetitionNotFound, "competition not found in selection"},
		{ErrRegistrationNotActive, "registration is not active"},
		{ErrRegistrationAlreadyActive, "registration is already active"},
		{ErrRegistrationNoCompetitionsSelected, "no competitions selected for individual registration"},
	}

	for _, e := range errors {
		t.Run(e.message, func(t *testing.T) {
			assert.Equal(t, e.message, e.err.Error())
		})
	}
}

// ============================================================================
// TOURNAMENT STANDING TESTS
// ============================================================================

func TestNewTournamentStanding(t *testing.T) {
	tournamentID := primitive.NewObjectID()
	athleteID := primitive.NewObjectID()
	athleteName := "John Racer"

	standing := NewTournamentStanding(tournamentID, athleteID, athleteName)

	assert.NotEmpty(t, standing.ID)
	assert.Equal(t, tournamentID, standing.TournamentID)
	assert.Equal(t, athleteID, standing.AthleteID)
	assert.Equal(t, athleteName, standing.AthleteName)
	assert.Equal(t, 0, standing.Position)
	assert.Equal(t, 0, standing.PreviousPosition)
	assert.Equal(t, 0, standing.PositionChange)
	assert.Equal(t, 0.0, standing.TotalPoints)
	assert.Equal(t, 0, standing.CompetitionsEntered)
	assert.Equal(t, 0, standing.CompetitionsCompleted)
	assert.Empty(t, standing.Results)
	assert.Equal(t, 999999, standing.Statistics.BestPosition)
	assert.Equal(t, 0, standing.Statistics.WorstPosition)
	assert.False(t, standing.IsQualified)
	assert.True(t, standing.IsEligible)
	assert.False(t, standing.IsDisqualified)
	assert.False(t, standing.CreatedAt.IsZero())
}

func TestTournamentStanding_AddResult(t *testing.T) {
	t.Run("adds new result successfully", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		result := CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 1",
			Date:            time.Now(),
			Position:        3,
			Points:          15.0,
		}

		standing.AddResult(result)

		assert.Len(t, standing.Results, 1)
		assert.Equal(t, 1, standing.CompetitionsEntered)
		assert.Equal(t, 1, standing.CompetitionsCompleted)
		assert.Equal(t, 15.0, standing.TotalPoints)
	})

	t.Run("updates existing result", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
		competitionID := primitive.NewObjectID()

		result1 := CompetitionResult{
			CompetitionID:   competitionID,
			CompetitionName: "Race 1",
			Date:            time.Now(),
			Position:        3,
			Points:          15.0,
		}
		standing.AddResult(result1)

		result2 := CompetitionResult{
			CompetitionID:   competitionID,
			CompetitionName: "Race 1 Updated",
			Date:            time.Now(),
			Position:        1,
			Points:          25.0,
		}
		standing.AddResult(result2)

		assert.Len(t, standing.Results, 1)
		assert.Equal(t, 1, standing.CompetitionsEntered)
		assert.Equal(t, "Race 1 Updated", standing.Results[0].CompetitionName)
		assert.Equal(t, 25.0, standing.TotalPoints)
	})

	t.Run("handles DNF result", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		result := CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 1",
			Date:            time.Now(),
			Position:        0,
			Points:          0,
			DidNotFinish:    true,
		}

		standing.AddResult(result)

		assert.Equal(t, 1, standing.CompetitionsEntered)
		assert.Equal(t, 0, standing.CompetitionsCompleted)
		assert.Equal(t, 1, standing.Statistics.DNFs)
	})

	t.Run("handles DNS result", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		result := CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 1",
			Date:            time.Now(),
			DidNotStart:     true,
		}

		standing.AddResult(result)

		assert.Equal(t, 1, standing.CompetitionsEntered)
		assert.Equal(t, 0, standing.CompetitionsCompleted)
		assert.Equal(t, 1, standing.Statistics.DNSs)
	})

	t.Run("handles DQ result", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		result := CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 1",
			Date:            time.Now(),
			Disqualified:    true,
		}

		standing.AddResult(result)

		assert.Equal(t, 1, standing.CompetitionsEntered)
		assert.Equal(t, 0, standing.CompetitionsCompleted)
		assert.Equal(t, 1, standing.Statistics.Disqualifications)
	})
}

func TestTournamentStanding_RecalculateStanding(t *testing.T) {
	t.Run("calculates statistics correctly", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		// Add a win
		standing.AddResult(CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 1",
			Date:            time.Now(),
			Position:        1,
			Points:          25.0,
		})

		// Add a podium
		standing.AddResult(CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 2",
			Date:            time.Now(),
			Position:        2,
			Points:          18.0,
		})

		// Add another podium
		standing.AddResult(CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 3",
			Date:            time.Now(),
			Position:        3,
			Points:          15.0,
		})

		// Add a top 5
		standing.AddResult(CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 4",
			Date:            time.Now(),
			Position:        5,
			Points:          10.0,
		})

		// Add a top 10
		standing.AddResult(CompetitionResult{
			CompetitionID:   primitive.NewObjectID(),
			CompetitionName: "Race 5",
			Date:            time.Now(),
			Position:        8,
			Points:          4.0,
		})

		assert.Equal(t, 72.0, standing.TotalPoints)
		assert.Equal(t, 1, standing.Statistics.Wins)
		assert.Equal(t, 3, standing.Statistics.Podiums)
		assert.Equal(t, 4, standing.Statistics.TopFive)
		assert.Equal(t, 5, standing.Statistics.TopTen)
		assert.Equal(t, 1, standing.Statistics.BestPosition)
		assert.Equal(t, 8, standing.Statistics.WorstPosition)
		assert.InDelta(t, 3.8, standing.Statistics.AveragePosition, 0.01) // (1+2+3+5+8)/5
	})

	t.Run("calculates consecutive podiums", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		// Add 3 consecutive podiums
		for i := 1; i <= 3; i++ {
			standing.AddResult(CompetitionResult{
				CompetitionID:   primitive.NewObjectID(),
				CompetitionName: "Race",
				Date:            time.Now(),
				Position:        i,
				Points:          float64(25 - i*3),
			})
		}

		assert.Equal(t, 3, standing.Statistics.ConsecutivePodiums)
	})

	t.Run("resets consecutive podiums on non-podium", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		// Add 2 podiums
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      1,
			Points:        25.0,
		})
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      2,
			Points:        18.0,
		})

		// Add non-podium
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      5,
			Points:        10.0,
		})

		// Add another podium
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      3,
			Points:        15.0,
		})

		assert.Equal(t, 0, standing.Statistics.ConsecutivePodiums) // Reset by the 5th place
	})

	t.Run("calculates participation rate", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		// 3 finished, 1 DNF
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      1,
			Points:        25.0,
		})
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      2,
			Points:        18.0,
		})
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      3,
			Points:        15.0,
		})
		standing.AddResult(CompetitionResult{
			CompetitionID:  primitive.NewObjectID(),
			DidNotFinish:   true,
		})

		assert.Equal(t, 4, standing.CompetitionsEntered)
		assert.Equal(t, 3, standing.CompetitionsCompleted)
		assert.InDelta(t, 75.0, standing.Statistics.ParticipationRate, 0.01) // 3/4 = 75%
	})

	t.Run("handles qualification requirements", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
		standing.CompetitionsRequired = 3

		// Add 2 results - not qualified
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      1,
			Points:        25.0,
		})
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      2,
			Points:        18.0,
		})

		assert.False(t, standing.IsQualified)

		// Add 3rd result - now qualified
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      3,
			Points:        15.0,
		})

		assert.True(t, standing.IsQualified)
	})

	t.Run("auto-qualifies when no requirement", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
		standing.CompetitionsRequired = 0

		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      1,
			Points:        25.0,
		})

		assert.True(t, standing.IsQualified)
	})

	t.Run("handles dropped results", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      1,
			Points:        25.0,
			IsDropped:     false,
		})
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      10,
			Points:        1.0,
			IsDropped:     true, // This will be dropped
		})

		assert.Equal(t, 25.0, standing.TotalPoints) // Only counts non-dropped
		assert.Equal(t, 1.0, standing.DroppedPoints)
	})
}

func TestTournamentStanding_UpdatePosition(t *testing.T) {
	standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
	standing.Position = 5

	standing.UpdatePosition(3)

	assert.Equal(t, 3, standing.Position)
	assert.Equal(t, 5, standing.PreviousPosition)
	assert.Equal(t, 2, standing.PositionChange) // Moved up 2 places (5-3)
}

func TestTournamentStanding_UpdatePosition_MovedDown(t *testing.T) {
	standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
	standing.Position = 3

	standing.UpdatePosition(5)

	assert.Equal(t, 5, standing.Position)
	assert.Equal(t, 3, standing.PreviousPosition)
	assert.Equal(t, -2, standing.PositionChange) // Moved down 2 places (3-5)
}

func TestTournamentStanding_MarkWorstResults(t *testing.T) {
	t.Run("marks worst results as dropped", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		// Add 5 results with different positions
		positions := []int{1, 5, 3, 10, 2}
		for _, pos := range positions {
			standing.AddResult(CompetitionResult{
				CompetitionID: primitive.NewObjectID(),
				Position:      pos,
				Points:        float64(25 - pos),
			})
		}

		// Drop worst 2 (positions 10 and 5)
		standing.MarkWorstResults(2)

		droppedCount := 0
		for _, r := range standing.Results {
			if r.IsDropped {
				droppedCount++
				assert.True(t, r.Position == 10 || r.Position == 5)
			}
		}
		assert.Equal(t, 2, droppedCount)
	})

	t.Run("does nothing with zero drop count", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      5,
			Points:        10.0,
		})

		standing.MarkWorstResults(0)

		assert.False(t, standing.Results[0].IsDropped)
	})

	t.Run("does nothing when drop count exceeds results", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      5,
			Points:        10.0,
		})

		standing.MarkWorstResults(5) // Drop 5 when only 1 result

		// No results should be dropped
		droppedCount := 0
		for _, r := range standing.Results {
			if r.IsDropped {
				droppedCount++
			}
		}
		assert.Equal(t, 0, droppedCount)
	})

	t.Run("excludes DNF/DNS/DQ from dropping", func(t *testing.T) {
		standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")

		// Add normal results
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      1,
			Points:        25.0,
		})
		standing.AddResult(CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      5,
			Points:        10.0,
		})
		// Add DNF - should not be considered for dropping
		standing.AddResult(CompetitionResult{
			CompetitionID:  primitive.NewObjectID(),
			Position:       0,
			Points:         0,
			DidNotFinish:   true,
		})

		standing.MarkWorstResults(1)

		// Only position 5 should be dropped (worst valid result)
		for _, r := range standing.Results {
			if r.Position == 5 {
				assert.True(t, r.IsDropped)
			} else {
				assert.False(t, r.IsDropped)
			}
		}
	})
}

func TestTournamentStanding_Disqualify(t *testing.T) {
	standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
	standing.IsQualified = true
	standing.IsEligible = true

	standing.Disqualify()

	assert.True(t, standing.IsDisqualified)
	assert.False(t, standing.IsQualified)
	assert.False(t, standing.IsEligible)
}

func TestTournamentStanding_Reinstate(t *testing.T) {
	standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
	standing.Disqualify()

	// Add a result so recalculation has something to work with
	standing.Results = append(standing.Results, CompetitionResult{
		CompetitionID: primitive.NewObjectID(),
		Position:      1,
		Points:        25.0,
	})

	standing.Reinstate()

	assert.False(t, standing.IsDisqualified)
	assert.True(t, standing.IsEligible)
}

func TestTournamentStanding_PrepareForUpdate(t *testing.T) {
	standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
	oldTime := standing.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	standing.PrepareForUpdate()

	assert.True(t, standing.UpdatedAt.After(oldTime))
}

func TestTournamentStanding_Validate(t *testing.T) {
	tests := []struct {
		name    string
		standing *TournamentStanding
		wantErr bool
	}{
		{
			name:    "valid standing",
			standing: NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete"),
			wantErr: false,
		},
		{
			name: "missing tournament ID",
			standing: &TournamentStanding{
				AthleteID: primitive.NewObjectID(),
			},
			wantErr: true,
		},
		{
			name: "missing athlete ID",
			standing: &TournamentStanding{
				TournamentID: primitive.NewObjectID(),
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.standing.Validate()
			if tt.wantErr {
				assert.Error(t, err)
				assert.Equal(t, ErrStandingInvalidInput, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestTournamentStandingDomainErrors(t *testing.T) {
	errors := []struct {
		err     error
		message string
	}{
		{ErrStandingInvalidInput, "invalid standing input data"},
		{ErrStandingNotFound, "standing not found"},
	}

	for _, e := range errors {
		t.Run(e.message, func(t *testing.T) {
			assert.Equal(t, e.message, e.err.Error())
		})
	}
}

func TestCompetitionResult_Struct(t *testing.T) {
	now := time.Now()
	timeResult := 125.5
	score := 95.0

	result := CompetitionResult{
		CompetitionID:   primitive.NewObjectID(),
		CompetitionName: "Grand Prix",
		Date:            now,
		Position:        1,
		Points:          25.0,
		TimeResult:      &timeResult,
		Score:           &score,
		DidNotFinish:    false,
		DidNotStart:     false,
		Disqualified:    false,
		Notes:           "Great performance",
		IsDropped:       false,
	}

	assert.Equal(t, "Grand Prix", result.CompetitionName)
	assert.Equal(t, 1, result.Position)
	assert.Equal(t, 25.0, result.Points)
	assert.Equal(t, 125.5, *result.TimeResult)
	assert.Equal(t, 95.0, *result.Score)
	assert.Equal(t, "Great performance", result.Notes)
}

func TestTournamentStatistics_Struct(t *testing.T) {
	stats := TournamentStatistics{
		Wins:               5,
		Podiums:            10,
		TopFive:            12,
		TopTen:             15,
		DNFs:               2,
		DNSs:               1,
		Disqualifications:  0,
		BestPosition:       1,
		WorstPosition:      8,
		AveragePosition:    3.5,
		ConsecutivePodiums: 3,
		ParticipationRate:  90.0,
	}

	assert.Equal(t, 5, stats.Wins)
	assert.Equal(t, 10, stats.Podiums)
	assert.Equal(t, 12, stats.TopFive)
	assert.Equal(t, 15, stats.TopTen)
	assert.Equal(t, 2, stats.DNFs)
	assert.Equal(t, 1, stats.DNSs)
	assert.Equal(t, 0, stats.Disqualifications)
	assert.Equal(t, 1, stats.BestPosition)
	assert.Equal(t, 8, stats.WorstPosition)
	assert.InDelta(t, 3.5, stats.AveragePosition, 0.01)
	assert.Equal(t, 3, stats.ConsecutivePodiums)
	assert.InDelta(t, 90.0, stats.ParticipationRate, 0.01)
}

// ============================================================================
// BENCHMARKS FOR TOURNAMENT STANDING
// ============================================================================

func BenchmarkTournamentStanding_RecalculateStanding(b *testing.B) {
	standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
	for i := 0; i < 20; i++ {
		standing.Results = append(standing.Results, CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      i + 1,
			Points:        float64(25 - i),
		})
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		standing.RecalculateStanding()
	}
}

func BenchmarkTournamentStanding_MarkWorstResults(b *testing.B) {
	standing := NewTournamentStanding(primitive.NewObjectID(), primitive.NewObjectID(), "Athlete")
	for i := 0; i < 20; i++ {
		standing.Results = append(standing.Results, CompetitionResult{
			CompetitionID: primitive.NewObjectID(),
			Position:      i + 1,
			Points:        float64(25 - i),
		})
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		standing.MarkWorstResults(3)
	}
}
