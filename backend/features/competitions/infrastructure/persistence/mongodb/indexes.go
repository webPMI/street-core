package mongodb

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CreateIndexes creates all necessary indexes for the competitions module
// This includes indexes for competitions, tournaments, standings, and registrations
func CreateIndexes(db *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Create indexes for each collection
	if err := createCompetitionIndexes(ctx, db); err != nil {
		return err
	}
	if err := createTournamentIndexes(ctx, db); err != nil {
		return err
	}
	if err := createTournamentStandingIndexes(ctx, db); err != nil {
		return err
	}
	if err := createTournamentRegistrationIndexes(ctx, db); err != nil {
		return err
	}
	if err := createEmergencyActionIndexes(ctx, db); err != nil {
		return err
	}
	if err := createEmergencyBroadcastIndexes(ctx, db); err != nil {
		return err
	}

	// 🚀 PERFORMANCE FIX: Add missing indexes for high-frequency queries
	if err := createParticipantIndexes(ctx, db); err != nil {
		return err
	}
	if err := createHeatIndexes(ctx, db); err != nil {
		return err
	}
	if err := createScoreIndexes(ctx, db); err != nil {
		return err
	}
	if err := createCategoryIndexes(ctx, db); err != nil {
		return err
	}
	if err := createJudgeInvitationIndexes(ctx, db); err != nil {
		return err
	}
	if err := createJudgeCheckinIndexes(ctx, db); err != nil {
		return err
	}
	if err := createLeaderboardIndexes(ctx, db); err != nil {
		return err
	}
	if err := createRoundIndexes(ctx, db); err != nil {
		return err
	}

	log.Println("✓ All competition module indexes created successfully")
	return nil
}

// createCompetitionIndexes creates indexes for competitions collection
func createCompetitionIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competitions")

	indexes := []mongo.IndexModel{
		// Single field indexes
		{
			Keys: bson.D{{Key: "organizerId", Value: 1}},
			Options: options.Index().SetName("idx_organizer"),
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}},
			Options: options.Index().SetName("idx_status"),
		},
		{
			Keys: bson.D{{Key: "discipline", Value: 1}},
			Options: options.Index().SetName("idx_discipline"),
		},
		{
			Keys: bson.D{{Key: "clubId", Value: 1}},
			Options: options.Index().SetName("idx_club").SetSparse(true),
		},
		{
			Keys: bson.D{{Key: "schedule.startDate", Value: 1}},
			Options: options.Index().SetName("idx_start_date"),
		},

		// Tournament relationship indexes
		{
			Keys: bson.D{{Key: "tournamentId", Value: 1}},
			Options: options.Index().SetName("idx_tournament").SetSparse(true),
		},
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "roundNumber", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_round").SetSparse(true),
		},

		// Compound indexes for common queries
		{
			Keys: bson.D{
				{Key: "organizerId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_organizer_status"),
		},
		{
			Keys: bson.D{
				{Key: "status", Value: 1},
				{Key: "schedule.startDate", Value: 1},
			},
			Options: options.Index().SetName("idx_status_date"),
		},
		{
			Keys: bson.D{
				{Key: "discipline", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_discipline_status"),
		},

		// Text search index
		{
			Keys: bson.D{
				{Key: "title", Value: "text"},
				{Key: "description", Value: "text"},
			},
			Options: options.Index().SetName("idx_search"),
		},

		// Registration indexes
		{
			Keys: bson.D{{Key: "registration.registeredAthleteIds", Value: 1}},
			Options: options.Index().SetName("idx_registered_athletes").SetSparse(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating competition indexes: %v", err)
		return err
	}

	log.Println("✓ Competition indexes created")
	return nil
}

// createTournamentIndexes creates indexes for tournaments collection
func createTournamentIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("tournaments")

	indexes := []mongo.IndexModel{
		// Single field indexes
		{
			Keys: bson.D{{Key: "organizerId", Value: 1}},
			Options: options.Index().SetName("idx_organizer"),
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}},
			Options: options.Index().SetName("idx_status"),
		},
		{
			Keys: bson.D{{Key: "sportType", Value: 1}},
			Options: options.Index().SetName("idx_sport_type"),
		},
		{
			Keys: bson.D{{Key: "discipline", Value: 1}},
			Options: options.Index().SetName("idx_discipline"),
		},
		{
			Keys: bson.D{{Key: "clubId", Value: 1}},
			Options: options.Index().SetName("idx_club").SetSparse(true),
		},
		{
			Keys: bson.D{{Key: "schedule.season", Value: 1}},
			Options: options.Index().SetName("idx_season").SetSparse(true),
		},
		{
			Keys: bson.D{{Key: "schedule.year", Value: 1}},
			Options: options.Index().SetName("idx_year"),
		},
		{
			Keys: bson.D{{Key: "schedule.startDate", Value: 1}},
			Options: options.Index().SetName("idx_start_date"),
		},
		{
			Keys: bson.D{{Key: "isFeatured", Value: 1}},
			Options: options.Index().SetName("idx_featured"),
		},

		// Compound indexes for common queries
		{
			Keys: bson.D{
				{Key: "organizerId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_organizer_status"),
		},
		{
			Keys: bson.D{
				{Key: "sportType", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_sport_status"),
		},
		{
			Keys: bson.D{
				{Key: "status", Value: 1},
				{Key: "schedule.startDate", Value: 1},
			},
			Options: options.Index().SetName("idx_status_date"),
		},
		{
			Keys: bson.D{
				{Key: "schedule.year", Value: 1},
				{Key: "sportType", Value: 1},
			},
			Options: options.Index().SetName("idx_year_sport"),
		},
		{
			Keys: bson.D{
				{Key: "isFeatured", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_featured_status"),
		},

		// Text search index
		{
			Keys: bson.D{
				{Key: "title", Value: "text"},
				{Key: "description", Value: "text"},
			},
			Options: options.Index().SetName("idx_search"),
		},

		// Registration indexes
		{
			Keys: bson.D{{Key: "registeredAthleteIds", Value: 1}},
			Options: options.Index().SetName("idx_registered_athletes").SetSparse(true),
		},
		{
			Keys: bson.D{{Key: "competitionIds", Value: 1}},
			Options: options.Index().SetName("idx_competitions").SetSparse(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating tournament indexes: %v", err)
		return err
	}

	log.Println("✓ Tournament indexes created")
	return nil
}

// createTournamentStandingIndexes creates indexes for tournament_standings collection
func createTournamentStandingIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("tournament_standings")

	indexes := []mongo.IndexModel{
		// Unique compound index: one standing per athlete per tournament
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "athleteId", Value: 1},
			},
			Options: options.Index().
				SetName("idx_tournament_athlete_unique").
				SetUnique(true),
		},

		// Compound index for getting standings by position
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "position", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_position"),
		},

		// Compound index for getting standings by points
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "countedPoints", Value: -1}, // Descending for top scores first
			},
			Options: options.Index().SetName("idx_tournament_points"),
		},

		// Single field indexes
		{
			Keys: bson.D{{Key: "tournamentId", Value: 1}},
			Options: options.Index().SetName("idx_tournament"),
		},
		{
			Keys: bson.D{{Key: "athleteId", Value: 1}},
			Options: options.Index().SetName("idx_athlete"),
		},

		// Indexes for filtering
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "isQualified", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_qualified"),
		},
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "isDisqualified", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_disqualified"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating tournament standing indexes: %v", err)
		return err
	}

	log.Println("✓ Tournament standing indexes created")
	return nil
}

// createTournamentRegistrationIndexes creates indexes for tournament_registrations collection
func createTournamentRegistrationIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("tournament_registrations")

	indexes := []mongo.IndexModel{
		// Unique compound index: one registration per athlete per tournament
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "athleteId", Value: 1},
			},
			Options: options.Index().
				SetName("idx_tournament_athlete_unique").
				SetUnique(true),
		},

		// Compound indexes for common queries
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_status"),
		},
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "registrationType", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_type"),
		},
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "approval.status", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_approval"),
		},
		{
			Keys: bson.D{
				{Key: "tournamentId", Value: 1},
				{Key: "payment.status", Value: 1},
			},
			Options: options.Index().SetName("idx_tournament_payment"),
		},

		// Single field indexes
		{
			Keys: bson.D{{Key: "tournamentId", Value: 1}},
			Options: options.Index().SetName("idx_tournament"),
		},
		{
			Keys: bson.D{{Key: "athleteId", Value: 1}},
			Options: options.Index().SetName("idx_athlete"),
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}},
			Options: options.Index().SetName("idx_status"),
		},
		{
			Keys: bson.D{{Key: "registrationDate", Value: -1}}, // Descending for recent first
			Options: options.Index().SetName("idx_registration_date"),
		},
		{
			Keys: bson.D{{Key: "raceNumber", Value: 1}},
			Options: options.Index().SetName("idx_race_number").SetSparse(true),
		},

		// Index for individual registrations
		{
			Keys: bson.D{{Key: "selectedCompetitionIds", Value: 1}},
			Options: options.Index().SetName("idx_selected_competitions").SetSparse(true),
		},

		// Email search (for admin)
		{
			Keys: bson.D{{Key: "athleteEmail", Value: 1}},
			Options: options.Index().SetName("idx_email"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating tournament registration indexes: %v", err)
		return err
	}

	log.Println("✓ Tournament registration indexes created")
	return nil
}

// DropAllIndexes drops all indexes (useful for development/testing)
// WARNING: This will drop ALL indexes including _id. Use with caution!
func DropAllIndexes(db *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	collections := []string{
		"competitions",
		"tournaments",
		"tournament_standings",
		"tournament_registrations",
		"emergency_actions",
		"emergency_broadcasts",
		// 🚀 PERFORMANCE FIX: New indexed collections
		"competition_participants",
		"competition_heats",
		"competition_scores",
		"competition_categories",
		"judge_invitations",
		"judge_checkins",
		"competition_leaderboards",
		"competition_rounds",
	}

	for _, collName := range collections {
		collection := db.Collection(collName)
		if _, err := collection.Indexes().DropAll(ctx); err != nil {
			log.Printf("Error dropping indexes for %s: %v", collName, err)
			return err
		}
		log.Printf("✓ Dropped all indexes for %s", collName)
	}

	return nil
}

// createEmergencyActionIndexes creates indexes for emergency_actions collection
// OPTIMIZATION: Indexes designed for fast writes and audit queries
func createEmergencyActionIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("emergency_actions")

	indexes := []mongo.IndexModel{
		// PRIMARY: Competition timeline (most common query)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
			Options: options.Index().SetName("idx_emergency_actions_competition_time"),
		},

		// Action type filtering
		{
			Keys: bson.D{
				{Key: "actionType", Value: 1},
				{Key: "competitionId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
			Options: options.Index().SetName("idx_emergency_actions_type"),
		},

		// Heat-specific actions
		{
			Keys:    bson.D{{Key: "heatId", Value: 1}},
			Options: options.Index().SetName("idx_emergency_actions_heat").SetSparse(true),
		},

		// Status filtering (for unresolved actions)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_emergency_actions_status"),
		},

		// Initiated by user (for audit trails)
		{
			Keys:    bson.D{{Key: "initiatedBy", Value: 1}},
			Options: options.Index().SetName("idx_emergency_actions_initiated_by"),
		},

		// Athlete-specific actions
		{
			Keys: bson.D{{Key: "athleteId", Value: 1}},
			Options: options.Index().SetName("idx_emergency_actions_athlete").SetSparse(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating emergency action indexes: %v", err)
		return err
	}

	log.Println("✓ Emergency action indexes created")
	return nil
}

// createEmergencyBroadcastIndexes creates indexes for emergency_broadcasts collection
// OPTIMIZATION: Includes TTL index for automatic cleanup
func createEmergencyBroadcastIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("emergency_broadcasts")

	indexes := []mongo.IndexModel{
		// PRIMARY: Competition broadcasts timeline
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "sentAt", Value: -1},
			},
			Options: options.Index().SetName("idx_emergency_broadcasts_competition"),
		},

		// TTL index for automatic cleanup of expired broadcasts
		{
			Keys: bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().
				SetName("idx_emergency_broadcasts_expiration").
				SetExpireAfterSeconds(0), // Expire at exact expiresAt time
		},

		// Priority filtering (critical alerts)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "priority", Value: 1},
			},
			Options: options.Index().SetName("idx_emergency_broadcasts_priority"),
		},

		// Link to triggering action
		{
			Keys:    bson.D{{Key: "actionId", Value: 1}},
			Options: options.Index().SetName("idx_emergency_broadcasts_action").SetSparse(true),
		},

		// Target role filtering
		{
			Keys:    bson.D{{Key: "targetRole", Value: 1}},
			Options: options.Index().SetName("idx_emergency_broadcasts_target"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating emergency broadcast indexes: %v", err)
		return err
	}

	log.Println("✓ Emergency broadcast indexes created")
	return nil
}

// ============================================================================
// 🚀 PERFORMANCE FIX: Missing indexes for high-frequency collections
// ============================================================================

// createParticipantIndexes creates indexes for competition_participants collection
func createParticipantIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competition_participants")

	indexes := []mongo.IndexModel{
		// CRITICAL: Unique constraint - one registration per athlete per competition
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "athleteId", Value: 1},
			},
			Options: options.Index().
				SetName("idx_participants_competition_athlete_unique").
				SetUnique(true),
		},

		// Query participants by competition (most common)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_participants_competition_status"),
		},

		// Query competitions by athlete
		{
			Keys:    bson.D{{Key: "athleteId", Value: 1}},
			Options: options.Index().SetName("idx_participants_athlete"),
		},

		// Filter by category
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "categoryId", Value: 1},
			},
			Options: options.Index().SetName("idx_participants_category").SetSparse(true),
		},

		// Registration date sorting
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "registeredAt", Value: -1},
			},
			Options: options.Index().SetName("idx_participants_registration_date"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating participant indexes: %v", err)
		return err
	}

	log.Println("✓ Participant indexes created")
	return nil
}

// createHeatIndexes creates indexes for competition_heats collection
func createHeatIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competition_heats")

	indexes := []mongo.IndexModel{
		// PRIMARY: Get heats by competition and round (most common query)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "roundId", Value: 1},
				{Key: "heatNumber", Value: 1},
			},
			Options: options.Index().SetName("idx_heats_competition_round_number"),
		},

		// Get heats by category (for multi-category competitions)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "categoryId", Value: 1},
			},
			Options: options.Index().SetName("idx_heats_category").SetSparse(true),
		},

		// Get heats by status (for "next heat" queries)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_heats_status"),
		},

		// Get heats with specific athletes
		{
			Keys:    bson.D{{Key: "athleteIds", Value: 1}},
			Options: options.Index().SetName("idx_heats_athletes"),
		},

		// Get heats assigned to specific judges
		{
			Keys:    bson.D{{Key: "assignedJudgeIds", Value: 1}},
			Options: options.Index().SetName("idx_heats_judges").SetSparse(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating heat indexes: %v", err)
		return err
	}

	log.Println("✓ Heat indexes created")
	return nil
}

// createScoreIndexes creates indexes for competition_scores collection
func createScoreIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competition_scores")

	indexes := []mongo.IndexModel{
		// CRITICAL: Unique constraint - one score per judge per athlete per heat
		{
			Keys: bson.D{
				{Key: "heatId", Value: 1},
				{Key: "judgeId", Value: 1},
				{Key: "athleteId", Value: 1},
			},
			Options: options.Index().
				SetName("idx_scores_heat_judge_athlete_unique").
				SetUnique(true),
		},

		// Get all scores for a heat (most common - for leaderboard calculation)
		{
			Keys: bson.D{
				{Key: "heatId", Value: 1},
				{Key: "athleteId", Value: 1},
			},
			Options: options.Index().SetName("idx_scores_heat_athlete"),
		},

		// Get scores by judge (for judge dashboard)
		{
			Keys: bson.D{
				{Key: "judgeId", Value: 1},
				{Key: "competitionId", Value: 1},
			},
			Options: options.Index().SetName("idx_scores_judge_competition"),
		},

		// Get athlete's scores across competition
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "athleteId", Value: 1},
			},
			Options: options.Index().SetName("idx_scores_competition_athlete"),
		},

		// Submission timestamp (for audit)
		{
			Keys: bson.D{
				{Key: "heatId", Value: 1},
				{Key: "submittedAt", Value: -1},
			},
			Options: options.Index().SetName("idx_scores_submission_time"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating score indexes: %v", err)
		return err
	}

	log.Println("✓ Score indexes created")
	return nil
}

// createCategoryIndexes creates indexes for competition_categories collection
func createCategoryIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competition_categories")

	indexes := []mongo.IndexModel{
		// Get categories by competition (most common)
		{
			Keys:    bson.D{{Key: "competitionId", Value: 1}},
			Options: options.Index().SetName("idx_categories_competition"),
		},

		// Unique category name per competition
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "name", Value: 1},
			},
			Options: options.Index().
				SetName("idx_categories_competition_name_unique").
				SetUnique(true),
		},

		// Filter by division/age group
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "division", Value: 1},
			},
			Options: options.Index().SetName("idx_categories_division").SetSparse(true),
		},

		// Get categories with specific judges
		{
			Keys:    bson.D{{Key: "judgeIds", Value: 1}},
			Options: options.Index().SetName("idx_categories_judges").SetSparse(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating category indexes: %v", err)
		return err
	}

	log.Println("✓ Category indexes created")
	return nil
}

// createJudgeInvitationIndexes creates indexes for judge_invitations collection
func createJudgeInvitationIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("judge_invitations")

	indexes := []mongo.IndexModel{
		// Get invitations by competition (organizer view)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_invitations_competition_status"),
		},

		// Get invitations by invitee (judge view - "my invitations")
		{
			Keys: bson.D{
				{Key: "inviteeId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_invitations_invitee_status"),
		},

		// Unique token for accepting invitations
		{
			Keys:    bson.D{{Key: "token", Value: 1}},
			Options: options.Index().SetName("idx_invitations_token_unique").SetUnique(true),
		},

		// Expiration index (for cleanup queries)
		{
			Keys:    bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().SetName("idx_invitations_expiration"),
		},

		// Category-specific invitations
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "categoryId", Value: 1},
			},
			Options: options.Index().SetName("idx_invitations_category").SetSparse(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating judge invitation indexes: %v", err)
		return err
	}

	log.Println("✓ Judge invitation indexes created")
	return nil
}

// createJudgeCheckinIndexes creates indexes for judge_checkins collection
func createJudgeCheckinIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("judge_checkins")

	indexes := []mongo.IndexModel{
		// PRIMARY: Check-ins by heat (most common - "who's checked in for this heat?")
		{
			Keys: bson.D{
				{Key: "heatId", Value: 1},
				{Key: "judgeId", Value: 1},
			},
			Options: options.Index().SetName("idx_checkins_heat_judge"),
		},

		// Get all check-ins for a competition (admin view)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "checkinTime", Value: -1},
			},
			Options: options.Index().SetName("idx_checkins_competition_time"),
		},

		// Judge's check-in history
		{
			Keys: bson.D{
				{Key: "judgeId", Value: 1},
				{Key: "checkinTime", Value: -1},
			},
			Options: options.Index().SetName("idx_checkins_judge_history"),
		},

		// Active check-ins (not yet checked out)
		{
			Keys: bson.D{
				{Key: "heatId", Value: 1},
				{Key: "isActive", Value: 1},
			},
			Options: options.Index().SetName("idx_checkins_active"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating judge checkin indexes: %v", err)
		return err
	}

	log.Println("✓ Judge checkin indexes created")
	return nil
}

// createLeaderboardIndexes creates indexes for competition_leaderboards collection
func createLeaderboardIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competition_leaderboards")

	indexes := []mongo.IndexModel{
		// Get leaderboard by competition (most common)
		{
			Keys:    bson.D{{Key: "competitionId", Value: 1}},
			Options: options.Index().SetName("idx_leaderboards_competition"),
		},

		// Get leaderboard by round
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "roundId", Value: 1},
			},
			Options: options.Index().SetName("idx_leaderboards_round").SetSparse(true),
		},

		// Get leaderboard by category
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "categoryId", Value: 1},
			},
			Options: options.Index().SetName("idx_leaderboards_category").SetSparse(true),
		},

		// Sort by position (for "top 10" queries)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "entries.position", Value: 1},
			},
			Options: options.Index().SetName("idx_leaderboards_positions"),
		},

		// Last update timestamp
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "lastUpdated", Value: -1},
			},
			Options: options.Index().SetName("idx_leaderboards_updated"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating leaderboard indexes: %v", err)
		return err
	}

	log.Println("✓ Leaderboard indexes created")
	return nil
}

// createRoundIndexes creates indexes for competition_rounds collection
func createRoundIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competition_rounds")

	indexes := []mongo.IndexModel{
		// Get rounds by competition (most common)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "roundNumber", Value: 1},
			},
			Options: options.Index().SetName("idx_rounds_competition_number"),
		},

		// Get rounds by type (qualifying, semi-final, final)
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "roundType", Value: 1},
			},
			Options: options.Index().SetName("idx_rounds_type"),
		},

		// Get rounds by status
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("idx_rounds_status"),
		},

		// Category-specific rounds
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "categoryId", Value: 1},
			},
			Options: options.Index().SetName("idx_rounds_category").SetSparse(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		log.Printf("Error creating round indexes: %v", err)
		return err
	}

	log.Println("✓ Round indexes created")
	return nil
}
