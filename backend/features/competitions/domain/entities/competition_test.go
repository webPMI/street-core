package entities

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ============================================================================
// CONSTANT TESTS
// ============================================================================

func TestCompetitionType_Constants(t *testing.T) {
	assert.Equal(t, "individual", CompetitionTypeIndividual)
	assert.Equal(t, "team", CompetitionTypeTeam)
	assert.Equal(t, "both", CompetitionTypeBoth)
}

func TestFormat_Constants(t *testing.T) {
	assert.Equal(t, "single_round", FormatSingleRound)
	assert.Equal(t, "multi_round", FormatMultiRound)
	assert.Equal(t, "elimination", FormatElimination)
	assert.Equal(t, "time_trial", FormatTimeTrial)
	assert.Equal(t, "points_race", FormatPointsRace)
}

func TestScoringType_Constants(t *testing.T) {
	assert.Equal(t, "points", ScoringTypePoints)
	assert.Equal(t, "time", ScoringTypeTime)
	assert.Equal(t, "average", ScoringTypeAverage)
	assert.Equal(t, "sum", ScoringTypeSum)
	assert.Equal(t, "weighted_average", ScoringTypeWeightedAverage)
}

func TestStatus_Constants(t *testing.T) {
	assert.Equal(t, "upcoming", StatusUpcoming)
	assert.Equal(t, "live", StatusLive)
	assert.Equal(t, "completed", StatusCompleted)
	assert.Equal(t, "cancelled", StatusCancelled)
}

func TestParticipantStatus_Constants(t *testing.T) {
	assert.Equal(t, "open", ParticipantStatusOpen)
	assert.Equal(t, "closed", ParticipantStatusClosed)
	assert.Equal(t, "full", ParticipantStatusFull)
}

// ============================================================================
// NEW COMPETITION TESTS
// ============================================================================

func TestNewCompetition(t *testing.T) {
	t.Run("creates competition with defaults", func(t *testing.T) {
		organizerID := primitive.NewObjectID()

		comp := NewCompetition(
			"Test Competition",
			"Test Description",
			organizerID,
			CompetitionTypeIndividual,
			FormatSingleRound,
			"skating",
		)

		assert.NotEmpty(t, comp.ID)
		assert.Equal(t, "Test Competition", comp.Title)
		assert.Equal(t, "Test Description", comp.Description)
		assert.Equal(t, organizerID, comp.OrganizerID)
		assert.Equal(t, CompetitionTypeIndividual, comp.CompetitionType)
		assert.Equal(t, FormatSingleRound, comp.Format)
		assert.Equal(t, "skating", comp.Discipline)

		// Check defaults
		assert.Equal(t, 100, comp.Registration.MaxParticipants)
		assert.Equal(t, 2, comp.Registration.MinParticipants)
		assert.Equal(t, ParticipantStatusOpen, comp.Registration.ParticipantStatus)
		assert.Equal(t, 3, comp.RequiredJudges)
		assert.Equal(t, 1, comp.TotalRounds)
		assert.Equal(t, 0, comp.CurrentRound)
		assert.Equal(t, StatusUpcoming, comp.Status)
		assert.False(t, comp.IsLive)
		assert.True(t, comp.AllowLiveScoring)
		assert.True(t, comp.ShowLiveResults)
		assert.True(t, comp.HasFinals)
		assert.False(t, comp.CreatedAt.IsZero())
		assert.False(t, comp.UpdatedAt.IsZero())
	})
}

// ============================================================================
// CAN REGISTER TESTS
// ============================================================================

func TestCompetition_CanRegister(t *testing.T) {
	t.Run("returns true when registration is open", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:   ParticipantStatusOpen,
				MaxParticipants:     100,
				CurrentParticipants: 50,
			},
		}

		assert.True(t, comp.CanRegister())
	})

	t.Run("returns false when registration is closed", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus: ParticipantStatusClosed,
			},
		}

		assert.False(t, comp.CanRegister())
	})

	t.Run("returns false when deadline has passed", func(t *testing.T) {
		pastDeadline := time.Now().Add(-24 * time.Hour)
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusOpen,
				RegistrationDeadline: &pastDeadline,
			},
		}

		assert.False(t, comp.CanRegister())
	})

	t.Run("returns false when max participants reached", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:   ParticipantStatusOpen,
				MaxParticipants:     50,
				CurrentParticipants: 50,
			},
		}

		assert.False(t, comp.CanRegister())
	})

	t.Run("returns false when competition is live", func(t *testing.T) {
		comp := &Competition{
			Status: StatusLive,
			Registration: Registration{
				ParticipantStatus: ParticipantStatusOpen,
			},
		}

		assert.False(t, comp.CanRegister())
	})

	t.Run("returns false when competition is completed", func(t *testing.T) {
		comp := &Competition{
			Status: StatusCompleted,
			Registration: Registration{
				ParticipantStatus: ParticipantStatusOpen,
			},
		}

		assert.False(t, comp.CanRegister())
	})

	t.Run("returns true when deadline is in future", func(t *testing.T) {
		futureDeadline := time.Now().Add(24 * time.Hour)
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusOpen,
				MaxParticipants:      100,
				CurrentParticipants:  10,
				RegistrationDeadline: &futureDeadline,
			},
		}

		assert.True(t, comp.CanRegister())
	})
}

// ============================================================================
// IS REGISTRATION OPEN TESTS
// ============================================================================

func TestCompetition_IsRegistrationOpen(t *testing.T) {
	t.Run("returns true when open and upcoming", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus: ParticipantStatusOpen,
			},
		}

		assert.True(t, comp.IsRegistrationOpen())
	})

	t.Run("returns false when status is closed", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus: ParticipantStatusClosed,
			},
		}

		assert.False(t, comp.IsRegistrationOpen())
	})

	t.Run("returns false when not upcoming", func(t *testing.T) {
		comp := &Competition{
			Status: StatusLive,
			Registration: Registration{
				ParticipantStatus: ParticipantStatusOpen,
			},
		}

		assert.False(t, comp.IsRegistrationOpen())
	})
}

// ============================================================================
// CAN SUBMIT SCORES TESTS
// ============================================================================

func TestCompetition_CanSubmitScores(t *testing.T) {
	t.Run("returns true when live", func(t *testing.T) {
		comp := &Competition{
			Status:           StatusLive,
			AllowLiveScoring: false,
		}

		assert.True(t, comp.CanSubmitScores())
	})

	t.Run("returns true when live scoring allowed", func(t *testing.T) {
		comp := &Competition{
			Status:           StatusUpcoming,
			AllowLiveScoring: true,
		}

		assert.True(t, comp.CanSubmitScores())
	})

	t.Run("returns false when not live and no live scoring", func(t *testing.T) {
		comp := &Competition{
			Status:           StatusUpcoming,
			AllowLiveScoring: false,
		}

		assert.False(t, comp.CanSubmitScores())
	})
}

// ============================================================================
// IS OWNER TESTS
// ============================================================================

func TestCompetition_IsOwner(t *testing.T) {
	t.Run("returns true for organizer", func(t *testing.T) {
		organizerID := primitive.NewObjectID()
		comp := &Competition{
			OrganizerID: organizerID,
		}

		assert.True(t, comp.IsOwner(organizerID))
	})

	t.Run("returns false for non-organizer", func(t *testing.T) {
		comp := &Competition{
			OrganizerID: primitive.NewObjectID(),
		}

		assert.False(t, comp.IsOwner(primitive.NewObjectID()))
	})
}

// ============================================================================
// IS JUDGE TESTS
// ============================================================================

func TestCompetition_IsJudge(t *testing.T) {
	t.Run("returns true for registered judge", func(t *testing.T) {
		judgeID := primitive.NewObjectID()
		comp := &Competition{
			JudgeIDs: []primitive.ObjectID{
				primitive.NewObjectID(),
				judgeID,
				primitive.NewObjectID(),
			},
		}

		assert.True(t, comp.IsJudge(judgeID))
	})

	t.Run("returns false for non-judge", func(t *testing.T) {
		comp := &Competition{
			JudgeIDs: []primitive.ObjectID{
				primitive.NewObjectID(),
			},
		}

		assert.False(t, comp.IsJudge(primitive.NewObjectID()))
	})

	t.Run("returns false for empty judges list", func(t *testing.T) {
		comp := &Competition{
			JudgeIDs: []primitive.ObjectID{},
		}

		assert.False(t, comp.IsJudge(primitive.NewObjectID()))
	})
}

// ============================================================================
// IS ATHLETE REGISTERED TESTS
// ============================================================================

func TestCompetition_IsAthleteRegistered(t *testing.T) {
	t.Run("returns true for registered athlete", func(t *testing.T) {
		athleteID := primitive.NewObjectID()
		comp := &Competition{
			Registration: Registration{
				RegisteredAthleteIDs: []primitive.ObjectID{
					primitive.NewObjectID(),
					athleteID,
				},
			},
		}

		assert.True(t, comp.IsAthleteRegistered(athleteID))
	})

	t.Run("returns false for unregistered athlete", func(t *testing.T) {
		comp := &Competition{
			Registration: Registration{
				RegisteredAthleteIDs: []primitive.ObjectID{
					primitive.NewObjectID(),
				},
			},
		}

		assert.False(t, comp.IsAthleteRegistered(primitive.NewObjectID()))
	})
}

// ============================================================================
// ADD ATHLETE TESTS
// ============================================================================

func TestCompetition_AddAthlete(t *testing.T) {
	t.Run("successfully adds athlete", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusOpen,
				MaxParticipants:      100,
				CurrentParticipants:  10,
				RegisteredAthleteIDs: []primitive.ObjectID{},
			},
		}

		athleteID := primitive.NewObjectID()
		err := comp.AddAthlete(athleteID)

		assert.NoError(t, err)
		assert.Equal(t, 11, comp.Registration.CurrentParticipants)
		assert.True(t, comp.IsAthleteRegistered(athleteID))
	})

	t.Run("returns error for already registered athlete", func(t *testing.T) {
		athleteID := primitive.NewObjectID()
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusOpen,
				MaxParticipants:      100,
				CurrentParticipants:  1,
				RegisteredAthleteIDs: []primitive.ObjectID{athleteID},
			},
		}

		err := comp.AddAthlete(athleteID)

		assert.Error(t, err)
		assert.Equal(t, ErrAlreadyRegistered, err)
	})

	t.Run("returns error when registration closed", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusClosed,
				RegisteredAthleteIDs: []primitive.ObjectID{},
			},
		}

		err := comp.AddAthlete(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrRegistrationClosed, err)
	})

	t.Run("marks as full when max participants reached", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusOpen,
				MaxParticipants:      2,
				CurrentParticipants:  1,
				RegisteredAthleteIDs: []primitive.ObjectID{primitive.NewObjectID()},
			},
		}

		err := comp.AddAthlete(primitive.NewObjectID())

		assert.NoError(t, err)
		assert.Equal(t, ParticipantStatusFull, comp.Registration.ParticipantStatus)
	})
}

// ============================================================================
// REMOVE ATHLETE TESTS
// ============================================================================

func TestCompetition_RemoveAthlete(t *testing.T) {
	t.Run("successfully removes athlete", func(t *testing.T) {
		athleteID := primitive.NewObjectID()
		comp := &Competition{
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusOpen,
				CurrentParticipants:  2,
				RegisteredAthleteIDs: []primitive.ObjectID{primitive.NewObjectID(), athleteID},
			},
		}

		err := comp.RemoveAthlete(athleteID)

		assert.NoError(t, err)
		assert.Equal(t, 1, comp.Registration.CurrentParticipants)
		assert.False(t, comp.IsAthleteRegistered(athleteID))
	})

	t.Run("returns error for unregistered athlete", func(t *testing.T) {
		comp := &Competition{
			Registration: Registration{
				CurrentParticipants:  1,
				RegisteredAthleteIDs: []primitive.ObjectID{primitive.NewObjectID()},
			},
		}

		err := comp.RemoveAthlete(primitive.NewObjectID())

		assert.Error(t, err)
		assert.Equal(t, ErrNotRegistered, err)
	})

	t.Run("reopens registration when was full", func(t *testing.T) {
		athleteID := primitive.NewObjectID()
		comp := &Competition{
			Registration: Registration{
				ParticipantStatus:    ParticipantStatusFull,
				MaxParticipants:      2,
				CurrentParticipants:  2,
				RegisteredAthleteIDs: []primitive.ObjectID{primitive.NewObjectID(), athleteID},
			},
		}

		err := comp.RemoveAthlete(athleteID)

		assert.NoError(t, err)
		assert.Equal(t, ParticipantStatusOpen, comp.Registration.ParticipantStatus)
	})
}

// ============================================================================
// ADD JUDGE TESTS
// ============================================================================

func TestCompetition_AddJudge(t *testing.T) {
	t.Run("successfully adds judge", func(t *testing.T) {
		comp := &Competition{
			JudgeIDs: []primitive.ObjectID{},
		}

		judgeID := primitive.NewObjectID()
		err := comp.AddJudge(judgeID)

		assert.NoError(t, err)
		assert.True(t, comp.IsJudge(judgeID))
	})

	t.Run("returns error for existing judge", func(t *testing.T) {
		judgeID := primitive.NewObjectID()
		comp := &Competition{
			JudgeIDs: []primitive.ObjectID{judgeID},
		}

		err := comp.AddJudge(judgeID)

		assert.Error(t, err)
		assert.Equal(t, ErrAlreadyJudge, err)
	})
}

// ============================================================================
// STATUS TRANSITION TESTS
// ============================================================================

func TestCompetition_MarkAsLive(t *testing.T) {
	comp := &Competition{
		Status: StatusUpcoming,
		IsLive: false,
	}

	comp.MarkAsLive()

	assert.Equal(t, StatusLive, comp.Status)
	assert.True(t, comp.IsLive)
	assert.False(t, comp.UpdatedAt.IsZero())
}

func TestCompetition_MarkAsCompleted(t *testing.T) {
	comp := &Competition{
		Status: StatusLive,
		IsLive: true,
	}

	comp.MarkAsCompleted()

	assert.Equal(t, StatusCompleted, comp.Status)
	assert.False(t, comp.IsLive)
	assert.False(t, comp.UpdatedAt.IsZero())
}

// ============================================================================
// PUBLISH RESULTS TESTS
// ============================================================================

func TestCompetition_PublishResults(t *testing.T) {
	t.Run("successfully publishes when completed", func(t *testing.T) {
		comp := &Competition{
			Status:             StatusCompleted,
			IsResultsPublished: false,
		}

		err := comp.PublishResults()

		assert.NoError(t, err)
		assert.True(t, comp.IsResultsPublished)
		assert.NotNil(t, comp.ResultsPublishedAt)
	})

	t.Run("successfully publishes when live", func(t *testing.T) {
		comp := &Competition{
			Status:             StatusLive,
			IsResultsPublished: false,
		}

		err := comp.PublishResults()

		assert.NoError(t, err)
		assert.True(t, comp.IsResultsPublished)
	})

	t.Run("returns error when upcoming", func(t *testing.T) {
		comp := &Competition{
			Status: StatusUpcoming,
		}

		err := comp.PublishResults()

		assert.Error(t, err)
		assert.Equal(t, ErrInvalidStatus, err)
	})

	t.Run("returns error when cancelled", func(t *testing.T) {
		comp := &Competition{
			Status: StatusCancelled,
		}

		err := comp.PublishResults()

		assert.Error(t, err)
		assert.Equal(t, ErrInvalidStatus, err)
	})
}

// ============================================================================
// TOURNAMENT RELATIONSHIP TESTS
// ============================================================================

func TestCompetition_IsPartOfTournament(t *testing.T) {
	t.Run("returns true when part of tournament", func(t *testing.T) {
		comp := &Competition{
			TournamentID: primitive.NewObjectID(),
		}

		assert.True(t, comp.IsPartOfTournament())
	})

	t.Run("returns false when not part of tournament", func(t *testing.T) {
		comp := &Competition{
			TournamentID: primitive.NilObjectID,
		}

		assert.False(t, comp.IsPartOfTournament())
	})
}

func TestCompetition_SetTournament(t *testing.T) {
	comp := &Competition{}
	tournamentID := primitive.NewObjectID()

	comp.SetTournament(tournamentID, "Summer Championship", 1)

	assert.Equal(t, tournamentID, comp.TournamentID)
	assert.Equal(t, "Summer Championship", comp.TournamentName)
	assert.NotNil(t, comp.RoundNumber)
	assert.Equal(t, 1, *comp.RoundNumber)
}

func TestCompetition_RemoveTournament(t *testing.T) {
	roundNum := 2
	comp := &Competition{
		TournamentID:   primitive.NewObjectID(),
		TournamentName: "Tournament",
		RoundNumber:    &roundNum,
	}

	comp.RemoveTournament()

	assert.True(t, comp.TournamentID.IsZero())
	assert.Empty(t, comp.TournamentName)
	assert.Nil(t, comp.RoundNumber)
}

// ============================================================================
// VALIDATE TESTS
// ============================================================================

func TestCompetition_Validate(t *testing.T) {
	t.Run("valid competition", func(t *testing.T) {
		now := time.Now()
		comp := &Competition{
			Title:       "Valid Competition",
			Description: "Valid description",
			OrganizerID: primitive.NewObjectID(),
			Schedule: Schedule{
				StartDate: now,
				EndDate:   now.Add(2 * time.Hour),
			},
		}

		err := comp.Validate()

		assert.NoError(t, err)
	})

	t.Run("empty title", func(t *testing.T) {
		comp := &Competition{
			Title:       "",
			Description: "Description",
			OrganizerID: primitive.NewObjectID(),
		}

		err := comp.Validate()

		assert.Error(t, err)
		assert.Equal(t, ErrInvalidInput, err)
	})

	t.Run("empty description", func(t *testing.T) {
		comp := &Competition{
			Title:       "Title",
			Description: "",
			OrganizerID: primitive.NewObjectID(),
		}

		err := comp.Validate()

		assert.Error(t, err)
	})

	t.Run("missing organizer", func(t *testing.T) {
		comp := &Competition{
			Title:       "Title",
			Description: "Description",
			OrganizerID: primitive.NilObjectID,
		}

		err := comp.Validate()

		assert.Error(t, err)
	})

	t.Run("end date before start date", func(t *testing.T) {
		now := time.Now()
		comp := &Competition{
			Title:       "Title",
			Description: "Description",
			OrganizerID: primitive.NewObjectID(),
			Schedule: Schedule{
				StartDate: now,
				EndDate:   now.Add(-time.Hour),
			},
		}

		err := comp.Validate()

		assert.Error(t, err)
	})
}

// ============================================================================
// DOMAIN ERROR TESTS
// ============================================================================

func TestDomainErrors(t *testing.T) {
	assert.Equal(t, "athlete already registered", ErrAlreadyRegistered.Error())
	assert.Equal(t, "athlete not registered", ErrNotRegistered.Error())
	assert.Equal(t, "registration is closed", ErrRegistrationClosed.Error())
	assert.Equal(t, "user is already a judge", ErrAlreadyJudge.Error())
	assert.Equal(t, "invalid competition status", ErrInvalidStatus.Error())
	assert.Equal(t, "invalid input data", ErrInvalidInput.Error())
}

// ============================================================================
// VALUE OBJECT TESTS
// ============================================================================

func TestSchedule(t *testing.T) {
	lat := 40.4168
	lon := -3.7038

	schedule := Schedule{
		StartDate: time.Now(),
		EndDate:   time.Now().Add(2 * time.Hour),
		Venue:     "Olympic Stadium",
		City:      "Madrid",
		Country:   "Spain",
		Latitude:  &lat,
		Longitude: &lon,
		TimeZone:  "Europe/Madrid",
	}

	assert.NotEmpty(t, schedule.Venue)
	assert.Equal(t, "Madrid", schedule.City)
	assert.NotNil(t, schedule.Latitude)
}

func TestRegistration(t *testing.T) {
	deadline := time.Now().Add(7 * 24 * time.Hour)
	entryFee := 25.0

	reg := Registration{
		MaxParticipants:      50,
		MinParticipants:      5,
		CurrentParticipants:  20,
		RegistrationDeadline: &deadline,
		RequiresApproval:     true,
		EntryFee:             &entryFee,
		Currency:             "EUR",
		ParticipantStatus:    ParticipantStatusOpen,
	}

	assert.Equal(t, 50, reg.MaxParticipants)
	assert.Equal(t, 25.0, *reg.EntryFee)
	assert.True(t, reg.RequiresApproval)
}

func TestScoreCriterion(t *testing.T) {
	criterion := ScoreCriterion{
		Name:     "Technique",
		Weight:   0.4,
		MaxScore: 10.0,
	}

	assert.Equal(t, "Technique", criterion.Name)
	assert.Equal(t, 0.4, criterion.Weight)
	assert.Equal(t, 10.0, criterion.MaxScore)
}

func TestScoringCriteria(t *testing.T) {
	criteria := ScoringCriteria{
		Type:     ScoringTypeWeightedAverage,
		MinScore: 0,
		MaxScore: 100,
		Criteria: []ScoreCriterion{
			{Name: "Technique", Weight: 0.4, MaxScore: 10},
			{Name: "Style", Weight: 0.3, MaxScore: 10},
			{Name: "Difficulty", Weight: 0.3, MaxScore: 10},
		},
		DropHighest: true,
		DropLowest:  true,
	}

	assert.Equal(t, ScoringTypeWeightedAverage, criteria.Type)
	assert.Len(t, criteria.Criteria, 3)
	assert.True(t, criteria.DropHighest)
	assert.True(t, criteria.DropLowest)
}

// ============================================================================
// BENCHMARKS
// ============================================================================

func BenchmarkNewCompetition(b *testing.B) {
	organizerID := primitive.NewObjectID()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = NewCompetition(
			"Test Competition",
			"Test Description",
			organizerID,
			CompetitionTypeIndividual,
			FormatSingleRound,
			"skating",
		)
	}
}

func TestCompetition_PrepareForUpdate(t *testing.T) {
	comp := NewCompetition("Test", "Description", primitive.NewObjectID(), CompetitionTypeIndividual, FormatSingleRound, "freestyle")
	oldTime := comp.UpdatedAt

	time.Sleep(1 * time.Millisecond)
	comp.PrepareForUpdate()

	assert.True(t, comp.UpdatedAt.After(oldTime))
}

func BenchmarkCompetition_CanRegister(b *testing.B) {
	comp := &Competition{
		Status: StatusUpcoming,
		Registration: Registration{
			ParticipantStatus:   ParticipantStatusOpen,
			MaxParticipants:     100,
			CurrentParticipants: 50,
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = comp.CanRegister()
	}
}

func BenchmarkCompetition_IsAthleteRegistered(b *testing.B) {
	athleteIDs := make([]primitive.ObjectID, 100)
	for i := range athleteIDs {
		athleteIDs[i] = primitive.NewObjectID()
	}

	comp := &Competition{
		Registration: Registration{
			RegisteredAthleteIDs: athleteIDs,
		},
	}

	searchID := athleteIDs[50]

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = comp.IsAthleteRegistered(searchID)
	}
}

func BenchmarkCompetition_Validate(b *testing.B) {
	now := time.Now()
	comp := &Competition{
		Title:       "Valid Competition",
		Description: "Valid description",
		OrganizerID: primitive.NewObjectID(),
		Schedule: Schedule{
			StartDate: now,
			EndDate:   now.Add(2 * time.Hour),
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = comp.Validate()
	}
}
