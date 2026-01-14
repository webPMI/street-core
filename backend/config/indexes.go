package config

import (
	"context"
	"time"

	"backend/features/competitions/infrastructure/persistence/mongodb"
	"backend/utils"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CreateIndexes creates all necessary database indexes for optimal performance
func CreateIndexes(db *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	utils.Info("Creando índices de base de datos", nil)

	// Users collection indexes
	if err := createUsersIndexes(ctx, db); err != nil {
		return err
	}

	// Refresh tokens collection indexes
	if err := createRefreshTokensIndexes(ctx, db); err != nil {
		return err
	}

	// Failed login attempts collection indexes
	if err := createFailedLoginAttemptsIndexes(ctx, db); err != nil {
		return err
	}

	// Password reset tokens collection indexes
	if err := createPasswordResetTokensIndexes(ctx, db); err != nil {
		return err
	}

	// Products collection indexes
	if err := createProductsIndexes(ctx, db); err != nil {
		return err
	}

	// Clubs collection indexes
	if err := createClubsIndexes(ctx, db); err != nil {
		return err
	}

	// Club members collection indexes
	if err := createClubMembersIndexes(ctx, db); err != nil {
		return err
	}

	// Athletes collection indexes
	if err := createAthletesIndexes(ctx, db); err != nil {
		return err
	}

	// Competitions collection indexes (DEPRECATED - basic indexes only)
	if err := createCompetitionsIndexes(ctx, db); err != nil {
		return err
	}

	// 🚀 PERFORMANCE FIX: Competition module comprehensive indexes
	// This calls the competition module's CreateIndexes which includes all 14 collections
	competitionsModule := mongodb.CreateIndexes
	if err := competitionsModule(db); err != nil {
		utils.Warn("Error creando índices del módulo competitions", map[string]interface{}{"error": err.Error()})
		// Don't return error - just log warning
	}

	// Events collection indexes
	if err := createEventsIndexes(ctx, db); err != nil {
		return err
	}

	// Chat collections indexes
	if err := createConversationsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createMessagesIndexes(ctx, db); err != nil {
		return err
	}

	if err := createConversationParticipantsIndexes(ctx, db); err != nil {
		return err
	}

	// Post system collections indexes
	if err := createPostsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createLikesIndexes(ctx, db); err != nil {
		return err
	}

	if err := createSavedPostsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createCommentsIndexes(ctx, db); err != nil {
		return err
	}

	// Follow system collections indexes
	if err := createFollowsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createBlocksIndexes(ctx, db); err != nil {
		return err
	}

	// Story system collections indexes
	if err := createStoriesIndexes(ctx, db); err != nil {
		return err
	}

	if err := createStoryViewsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createHighlightsIndexes(ctx, db); err != nil {
		return err
	}

	// Notification system collections indexes
	if err := createNotificationsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createNotificationSettingsIndexes(ctx, db); err != nil {
		return err
	}

	// OAuth system collections indexes
	if err := createOAuthAccountsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createOAuthStateIndexes(ctx, db); err != nil {
		return err
	}

	// School and course collections indexes
	if err := createSchoolsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createCoursesIndexes(ctx, db); err != nil {
		return err
	}

	// Competition category, judge invitation, and judge score collections indexes
	if err := createCompetitionCategoriesIndexes(ctx, db); err != nil {
		return err
	}

	if err := createJudgeInvitationsIndexes(ctx, db); err != nil {
		return err
	}

	if err := createJudgeScoresIndexes(ctx, db); err != nil {
		return err
	}

	utils.Info("Índices de base de datos creados exitosamente", nil)
	return nil
}

// CreateChatIndexes creates all indexes for chat collections
// This is a standalone function that can be called independently
func CreateChatIndexes(db *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	utils.Info("Creando índices de chat", nil)

	// Messages collection indexes
	if err := createMessagesIndexes(ctx, db); err != nil {
		return err
	}

	// Conversations collection indexes
	if err := createConversationsIndexes(ctx, db); err != nil {
		return err
	}

	// Conversation participants collection indexes
	if err := createConversationParticipantsIndexes(ctx, db); err != nil {
		return err
	}

	utils.Info("Índices de chat creados exitosamente", nil)
	return nil
}

func createUsersIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("users")

	indexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "email", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "role", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de usuarios", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de usuarios creados", nil)
	return nil
}

func createRefreshTokensIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("refresh_tokens")

	indexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "token", Value: 1}},
			Options: options.Index().SetUnique(true).SetName("token_unique"),
		},
		{
			Keys:    bson.D{{Key: "user_id", Value: 1}},
			Options: options.Index().SetName("user_id_idx"),
		},
		{
			Keys: bson.D{
				{Key: "revoked", Value: 1},
				{Key: "expires_at", Value: 1},
			},
			Options: options.Index().SetName("revoked_expires_idx"),
		},
		// TTL index - automatically delete expired tokens
		// Note: This also serves as the expires_at index for queries
		{
			Keys:    bson.D{{Key: "expires_at", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(0).SetName("expires_at_ttl"),
		},
		// 🔒 SECURITY HIGH-002: Index for token family rotation
		{
			Keys:    bson.D{{Key: "family_id", Value: 1}},
			Options: options.Index().SetName("family_id_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de refresh_tokens", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de refresh_tokens creados", nil)
	return nil
}

func createFailedLoginAttemptsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("failed_login_attempts")

	indexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "email", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "last_attempt", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "locked_until", Value: 1}},
		},
		// TTL index - automatically delete records after 7 days of last attempt
		{
			Keys:    bson.D{{Key: "last_attempt", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(7 * 24 * 60 * 60), // 7 days
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de failed_login_attempts", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de failed_login_attempts creados", nil)
	return nil
}

func createPasswordResetTokensIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("password_reset_tokens")

	indexes := []mongo.IndexModel{
		// Token lookup (hashed token is unique)
		{
			Keys:    bson.D{{Key: "token", Value: 1}},
			Options: options.Index().SetName("token_idx"),
		},
		// User lookup (find all reset tokens for a user)
		{
			Keys:    bson.D{{Key: "user_id", Value: 1}},
			Options: options.Index().SetName("user_id_idx"),
		},
		// Email lookup (for quick user finding)
		{
			Keys:    bson.D{{Key: "email", Value: 1}},
			Options: options.Index().SetName("email_idx"),
		},
		// Query valid tokens (not used, not expired)
		{
			Keys: bson.D{
				{Key: "used", Value: 1},
				{Key: "expires_at", Value: 1},
			},
			Options: options.Index().SetName("used_expires_idx"),
		},
		// TTL index - automatically delete expired tokens
		// Tokens expire in 1 hour, MongoDB will delete them automatically
		{
			Keys:    bson.D{{Key: "expires_at", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(0).SetName("expires_at_ttl"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de password_reset_tokens", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de password_reset_tokens creados", nil)
	return nil
}

func createProductsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("products")

	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "userCreator", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "category", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "isActive", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
		// Text search index for name and description
		{
			Keys: bson.D{
				{Key: "name", Value: "text"},
				{Key: "description", Value: "text"},
			},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de products", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de products creados", nil)
	return nil
}

func createClubsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("clubs")

	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "ownerId", Value: 1}},
		},
		{
			Keys: bson.D{
				{Key: "isPublic", Value: 1},
				{Key: "isActive", Value: 1},
			},
		},
		{
			// Fixed: Changed from "sportType" to "disciplines" to match model
			Keys: bson.D{{Key: "disciplines", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
		// Text search index
		{
			Keys: bson.D{
				{Key: "name", Value: "text"},
				{Key: "description", Value: "text"},
			},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de clubs", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de clubs creados", nil)
	return nil
}

func createClubMembersIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("club_members")

	indexes := []mongo.IndexModel{
		// Unique compound index - prevent duplicate memberships
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "clubId", Value: 1},
			},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "clubId", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}},
		},
		{
			Keys: bson.D{
				{Key: "clubId", Value: 1},
				{Key: "status", Value: 1},
			},
		},
		{
			Keys: bson.D{{Key: "joinedAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de club_members", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de club_members creados", nil)
	return nil
}

func createAthletesIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("athlete_profiles")

	indexes := []mongo.IndexModel{
		// Primary query indexes
		{
			Keys:    bson.D{{Key: "userId", Value: 1}},
			Options: options.Index().SetName("userId_idx"),
		},
		{
			Keys:    bson.D{{Key: "clubId", Value: 1}},
			Options: options.Index().SetName("clubId_idx"),
		},
		{
			Keys:    bson.D{{Key: "isActive", Value: 1}},
			Options: options.Index().SetName("isActive_idx"),
		},
		// Compound index for rankings (optimized for leaderboard queries)
		{
			Keys: bson.D{
				{Key: "isActive", Value: 1},
				{Key: "totalPoints", Value: -1},
				{Key: "createdAt", Value: -1},
			},
			Options: options.Index().SetName("ranking_idx"),
		},
		// Compound index for user's active profiles
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "isActive", Value: 1},
			},
			Options: options.Index().SetName("user_active_idx"),
		},
		// Compound index for club's active athletes
		{
			Keys: bson.D{
				{Key: "clubId", Value: 1},
				{Key: "isActive", Value: 1},
				{Key: "totalPoints", Value: -1},
			},
			Options: options.Index().SetName("club_athletes_idx"),
		},
		// Text search index for athlete search
		{
			Keys: bson.D{
				{Key: "athleteName", Value: "text"},
				{Key: "bio", Value: "text"},
			},
			Options: options.Index().SetName("athlete_search_idx"),
		},
		// Index for disciplines search
		{
			Keys:    bson.D{{Key: "disciplines", Value: 1}},
			Options: options.Index().SetName("disciplines_idx"),
		},
		// Index for skill level filtering
		{
			Keys: bson.D{
				{Key: "skillLevel", Value: 1},
				{Key: "totalPoints", Value: -1},
			},
			Options: options.Index().SetName("skill_ranking_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de athlete profiles", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de athlete profiles creados", map[string]interface{}{"count": 9})
	return nil
}

func createCompetitionsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competitions")

	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "organizerId", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "startDate", Value: 1}},
		},
		{
			Keys: bson.D{
				{Key: "status", Value: 1},
				{Key: "startDate", Value: 1},
			},
		},
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de competitions", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de competitions creados", nil)
	return nil
}

func createEventsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("events")

	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "organizerId", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "isPublic", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "eventDate", Value: 1}},
		},
		{
			Keys: bson.D{
				{Key: "isPublic", Value: 1},
				{Key: "eventDate", Value: 1},
			},
		},
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de events", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de events creados", nil)
	return nil
}

func createConversationsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("conversations")

	indexes := []mongo.IndexModel{
		// Index for participant queries (find all user's conversations)
		{
			Keys:    bson.D{{Key: "participants", Value: 1}},
			Options: options.Index().SetName("participants_idx"),
		},
		// Index for sorting by last activity
		{
			Keys:    bson.D{{Key: "updated_at", Value: -1}},
			Options: options.Index().SetName("updated_at_idx"),
		},
		// Compound index for active conversations of user
		{
			Keys: bson.D{
				{Key: "participants", Value: 1},
				{Key: "is_active", Value: 1},
			},
			Options: options.Index().SetName("participants_active_idx"),
		},
		// Compound index for finding private conversations
		{
			Keys: bson.D{
				{Key: "type", Value: 1},
				{Key: "participants", Value: 1},
			},
			Options: options.Index().SetName("type_participants_idx"),
		},
		// Index for created_by queries
		{
			Keys:    bson.D{{Key: "created_by", Value: 1}},
			Options: options.Index().SetName("created_by_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de conversations", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de conversations creados", nil)
	return nil
}

func createMessagesIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("messages")

	indexes := []mongo.IndexModel{
		// Compound index for queries: get messages by conversation, sorted by date
		{
			Keys: bson.D{
				{Key: "conversation_id", Value: 1},
				{Key: "created_at", Value: -1},
			},
			Options: options.Index().SetName("conversation_created_idx"),
		},
		// Index for sender queries
		{
			Keys:    bson.D{{Key: "sender_id", Value: 1}},
			Options: options.Index().SetName("sender_idx"),
		},
		// Compound index for filtering deleted messages
		{
			Keys: bson.D{
				{Key: "conversation_id", Value: 1},
				{Key: "is_deleted", Value: 1},
			},
			Options: options.Index().SetName("conversation_deleted_idx"),
		},
		// Index for read receipts queries
		{
			Keys:    bson.D{{Key: "read_by", Value: 1}},
			Options: options.Index().SetName("read_by_idx"),
		},
		// Index for created_at (for cleanup queries)
		{
			Keys:    bson.D{{Key: "created_at", Value: -1}},
			Options: options.Index().SetName("created_at_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de messages", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de messages creados", nil)
	return nil
}

func createConversationParticipantsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("conversation_participants")

	indexes := []mongo.IndexModel{
		// Unique compound index - prevent duplicate participants
		{
			Keys: bson.D{
				{Key: "conversation_id", Value: 1},
				{Key: "user_id", Value: 1},
			},
			Options: options.Index().
				SetUnique(true).
				SetName("conversation_user_unique_idx"),
		},
		// Index for user's conversations
		{
			Keys:    bson.D{{Key: "user_id", Value: 1}},
			Options: options.Index().SetName("user_idx"),
		},
		// Index for conversation queries
		{
			Keys:    bson.D{{Key: "conversation_id", Value: 1}},
			Options: options.Index().SetName("conversation_idx"),
		},
		// Index for unread count queries
		{
			Keys: bson.D{
				{Key: "user_id", Value: 1},
				{Key: "unread_count", Value: -1},
			},
			Options: options.Index().SetName("user_unread_idx"),
		},
		// Index for last_read_at queries
		{
			Keys:    bson.D{{Key: "last_read_at", Value: -1}},
			Options: options.Index().SetName("last_read_at_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de conversation_participants", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de conversation_participants creados", nil)
	return nil
}

func createPostsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("posts")

	indexes := []mongo.IndexModel{
		// Index for user's posts
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		// Index for visibility queries (public posts feed)
		{
			Keys: bson.D{
				{Key: "visibility", Value: 1},
				{Key: "isDeleted", Value: 1},
				{Key: "isActive", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for deleted/archived posts
		{
			Keys: bson.D{
				{Key: "isDeleted", Value: 1},
				{Key: "isArchived", Value: 1},
			},
		},
		// Index for sorting by engagement
		{
			Keys: bson.D{{Key: "likesCount", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "commentsCount", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "viewsCount", Value: -1}},
		},
		// Compound index for user's active posts sorted by date
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "isDeleted", Value: 1},
				{Key: "isArchived", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for created date (chronological feed)
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
		// Text search index for caption
		{
			Keys: bson.D{
				{Key: "caption", Value: "text"},
			},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de posts", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de posts creados", nil)
	return nil
}

func createLikesIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("likes")

	indexes := []mongo.IndexModel{
		// Unique compound index - prevent duplicate likes
		{
			Keys: bson.D{
				{Key: "postId", Value: 1},
				{Key: "userId", Value: 1},
			},
			Options: options.Index().SetUnique(true),
		},
		// Index for getting all likes of a post
		{
			Keys: bson.D{{Key: "postId", Value: 1}},
		},
		// Index for getting all likes by a user
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		// Index for sorting by date
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
		// Compound index for post likes sorted by date
		{
			Keys: bson.D{
				{Key: "postId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de likes", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de likes creados", nil)
	return nil
}

func createSavedPostsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("saved_posts")

	indexes := []mongo.IndexModel{
		// Unique compound index - prevent duplicate saved posts
		{
			Keys: bson.D{
				{Key: "postId", Value: 1},
				{Key: "userId", Value: 1},
			},
			Options: options.Index().SetUnique(true),
		},
		// Index for getting all saved posts by a user
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for user ID lookup
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		// Index for post ID lookup
		{
			Keys: bson.D{{Key: "postId", Value: 1}},
		},
		// Index for sorting by date
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de saved_posts", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de saved_posts creados", nil)
	return nil
}

func createCommentsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("comments")

	indexes := []mongo.IndexModel{
		// Index for getting all comments on a post
		{
			Keys: bson.D{
				{Key: "postId", Value: 1},
				{Key: "isDeleted", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for getting replies to a comment
		{
			Keys: bson.D{
				{Key: "parentCommentId", Value: 1},
				{Key: "isDeleted", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for user's comments
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		// Index for deleted comments
		{
			Keys: bson.D{{Key: "isDeleted", Value: 1}},
		},
		// Index for top-level comments (no parent)
		{
			Keys: bson.D{
				{Key: "postId", Value: 1},
				{Key: "parentCommentId", Value: 1},
				{Key: "isDeleted", Value: 1},
			},
		},
		// Index for sorting by likes
		{
			Keys: bson.D{{Key: "likesCount", Value: -1}},
		},
		// Index for created date
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de comments", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de comments creados", nil)
	return nil
}

func createFollowsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("follows")

	indexes := []mongo.IndexModel{
		// Unique index to prevent duplicate follows
		{
			Keys: bson.D{
				{Key: "followerId", Value: 1},
				{Key: "followingId", Value: 1},
			},
			Options: options.Index().SetUnique(true),
		},
		// Index for getting followers of a user (with status filter)
		{
			Keys: bson.D{
				{Key: "followingId", Value: 1},
				{Key: "status", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for getting users that a user is following (with status filter)
		{
			Keys: bson.D{
				{Key: "followerId", Value: 1},
				{Key: "status", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for pending follow requests
		{
			Keys: bson.D{
				{Key: "followingId", Value: 1},
				{Key: "status", Value: 1},
			},
		},
		// Index for follower ID lookup
		{
			Keys: bson.D{{Key: "followerId", Value: 1}},
		},
		// Index for following ID lookup
		{
			Keys: bson.D{{Key: "followingId", Value: 1}},
		},
		// Index for status filter
		{
			Keys: bson.D{{Key: "status", Value: 1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de follows", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de follows creados", nil)
	return nil
}

func createBlocksIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("blocks")

	indexes := []mongo.IndexModel{
		// Unique index to prevent duplicate blocks
		{
			Keys: bson.D{
				{Key: "blockerId", Value: 1},
				{Key: "blockedId", Value: 1},
			},
			Options: options.Index().SetUnique(true),
		},
		// Index for getting all users blocked by a user
		{
			Keys: bson.D{
				{Key: "blockerId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for checking if a specific user is blocked
		{
			Keys: bson.D{
				{Key: "blockedId", Value: 1},
				{Key: "blockerId", Value: 1},
			},
		},
		// Index for blocker ID lookup
		{
			Keys: bson.D{{Key: "blockerId", Value: 1}},
		},
		// Index for blocked ID lookup
		{
			Keys: bson.D{{Key: "blockedId", Value: 1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de blocks", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de blocks creados", nil)
	return nil
}

func createStoriesIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("stories")

	indexes := []mongo.IndexModel{
		// Index for getting active stories by user
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "isActive", Value: 1},
				{Key: "isDeleted", Value: 1},
				{Key: "expiresAt", Value: -1},
			},
		},
		// Index for getting non-expired stories
		{
			Keys: bson.D{
				{Key: "isActive", Value: 1},
				{Key: "expiresAt", Value: -1},
			},
		},
		// Index for user ID lookup
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		// Index for visibility filter
		{
			Keys: bson.D{
				{Key: "visibility", Value: 1},
				{Key: "expiresAt", Value: -1},
			},
		},
		// TTL index for automatic deletion of expired stories
		{
			Keys:    bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(86400), // 24 hours after expiration
		},
		// Index for created date
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de stories", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de stories creados", nil)
	return nil
}

func createStoryViewsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("story_views")

	indexes := []mongo.IndexModel{
		// Unique index to prevent duplicate views
		{
			Keys: bson.D{
				{Key: "storyId", Value: 1},
				{Key: "userId", Value: 1},
			},
			Options: options.Index().SetUnique(true),
		},
		// Index for getting all viewers of a story
		{
			Keys: bson.D{
				{Key: "storyId", Value: 1},
				{Key: "viewedAt", Value: -1},
			},
		},
		// Index for story ID lookup
		{
			Keys: bson.D{{Key: "storyId", Value: 1}},
		},
		// Index for user ID lookup
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de story_views", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de story_views creados", nil)
	return nil
}

func createHighlightsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("story_highlights")

	indexes := []mongo.IndexModel{
		// Index for getting user highlights
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for user ID lookup
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		// Index for created date
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de highlights", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de highlights creados", nil)
	return nil
}

func createNotificationsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("notifications")

	indexes := []mongo.IndexModel{
		// Index for getting user notifications
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "isDeleted", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for unread notifications
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "isRead", Value: 1},
				{Key: "isDeleted", Value: 1},
			},
		},
		// Index for user ID lookup
		{
			Keys: bson.D{{Key: "userId", Value: 1}},
		},
		// Index for notification type filter
		{
			Keys: bson.D{
				{Key: "type", Value: 1},
				{Key: "createdAt", Value: -1},
			},
		},
		// Index for actor lookup (who triggered notification)
		{
			Keys: bson.D{{Key: "actorId", Value: 1}},
		},
		// TTL index for automatic deletion of expired notifications
		{
			Keys:    bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(0), // Delete when expiresAt is reached
		},
		// Index for created date
		{
			Keys: bson.D{{Key: "createdAt", Value: -1}},
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de notifications", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de notifications creados", nil)
	return nil
}

func createNotificationSettingsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("notification_settings")

	indexes := []mongo.IndexModel{
		// Unique index on user ID
		{
			Keys:    bson.D{{Key: "userId", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de notification_settings", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de notification_settings creados", nil)
	return nil
}

// ============================================================================
// OAUTH SYSTEM INDEXES
// ============================================================================

// createOAuthAccountsIndexes creates indexes for oauth_accounts collection
// 🔒 SECURITY: Unique constraint prevents duplicate provider linkages
func createOAuthAccountsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("oauth_accounts")

	indexes := []mongo.IndexModel{
		// 🔒 SECURITY: Unique constraint - one provider account per user
		// Prevents multiple linkages of same Google/Facebook account
		{
			Keys: bson.D{
				{Key: "provider", Value: 1},
				{Key: "providerId", Value: 1},
			},
			Options: options.Index().
				SetUnique(true).
				SetName("unique_provider_account"),
		},

		// Find all OAuth accounts for a user
		{
			Keys:    bson.D{{Key: "userId", Value: 1}},
			Options: options.Index().SetName("user_oauth_accounts"),
		},

		// Find accounts by email (for account linking verification)
		{
			Keys:    bson.D{{Key: "email", Value: 1}},
			Options: options.Index().SetName("oauth_email_lookup"),
		},

		// Compound index for finding user's specific provider account
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "provider", Value: 1},
			},
			Options: options.Index().SetName("user_provider_account"),
		},

		// Cleanup expired tokens (for maintenance tasks)
		{
			Keys:    bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().SetName("oauth_token_expiry"),
		},

		// Track last used OAuth accounts
		{
			Keys:    bson.D{{Key: "lastUsedAt", Value: -1}},
			Options: options.Index().SetName("oauth_last_used"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de oauth_accounts", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de oauth_accounts creados", map[string]interface{}{"count": 6})
	return nil
}

// createOAuthStateIndexes creates indexes for oauth_state_tokens collection
// 🔒 SECURITY: TTL index auto-deletes expired CSRF tokens
func createOAuthStateIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("oauth_state_tokens")

	indexes := []mongo.IndexModel{
		// 🔒 SECURITY: Unique state tokens prevent CSRF attacks
		// Each state token can only be used once
		{
			Keys: bson.D{{Key: "state", Value: 1}},
			Options: options.Index().
				SetUnique(true).
				SetName("unique_state_token"),
		},

		// 🔒 SECURITY: TTL index - auto-delete after expiration
		// State tokens expire in 10 minutes (configurable)
		// MongoDB will automatically remove expired documents
		{
			Keys: bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().
				SetExpireAfterSeconds(0). // Delete when expiresAt is reached
				SetName("state_token_ttl"),
		},

		// Query by provider for analytics
		{
			Keys:    bson.D{{Key: "provider", Value: 1}},
			Options: options.Index().SetName("state_by_provider"),
		},

		// Compound index for state validation
		// Quickly find and validate state + provider combination
		{
			Keys: bson.D{
				{Key: "state", Value: 1},
				{Key: "provider", Value: 1},
			},
			Options: options.Index().SetName("state_provider_lookup"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de oauth_state_tokens", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de oauth_state_tokens creados", map[string]interface{}{"count": 4})
	return nil
}

// ============================================================================
// SCHOOL AND COURSE SYSTEM INDEXES
// ============================================================================

// createSchoolsIndexes creates indexes for schools collection
func createSchoolsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("schools")

	indexes := []mongo.IndexModel{
		// Owner lookup
		{
			Keys:    bson.D{{Key: "ownerId", Value: 1}},
			Options: options.Index().SetName("owner_idx"),
		},
		// Public schools filter
		{
			Keys: bson.D{
				{Key: "isPublic", Value: 1},
				{Key: "isActive", Value: 1},
			},
			Options: options.Index().SetName("public_active_idx"),
		},
		// Location-based queries
		{
			Keys: bson.D{
				{Key: "country", Value: 1},
				{Key: "city", Value: 1},
			},
			Options: options.Index().SetName("location_idx"),
		},
		// Disciplines filter
		{
			Keys:    bson.D{{Key: "disciplines", Value: 1}},
			Options: options.Index().SetName("disciplines_idx"),
		},
		// Rating-based sorting
		{
			Keys: bson.D{
				{Key: "isActive", Value: 1},
				{Key: "averageRating", Value: -1},
			},
			Options: options.Index().SetName("rating_idx"),
		},
		// Accepting students filter
		{
			Keys: bson.D{
				{Key: "acceptingStudents", Value: 1},
				{Key: "isActive", Value: 1},
			},
			Options: options.Index().SetName("accepting_students_idx"),
		},
		// Text search
		{
			Keys: bson.D{
				{Key: "title", Value: "text"},
				{Key: "description", Value: "text"},
				{Key: "city", Value: "text"},
			},
			Options: options.Index().SetName("school_search_idx"),
		},
		// Created date
		{
			Keys:    bson.D{{Key: "createdAt", Value: -1}},
			Options: options.Index().SetName("created_at_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de schools", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de schools creados", map[string]interface{}{"count": 8})
	return nil
}

// createCoursesIndexes creates indexes for courses collection
func createCoursesIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("courses")

	indexes := []mongo.IndexModel{
		// School lookup
		{
			Keys:    bson.D{{Key: "schoolId", Value: 1}},
			Options: options.Index().SetName("school_idx"),
		},
		// Instructor lookup
		{
			Keys:    bson.D{{Key: "instructorId", Value: 1}},
			Options: options.Index().SetName("instructor_idx"),
		},
		// Active courses filter
		{
			Keys: bson.D{
				{Key: "isActive", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("active_status_idx"),
		},
		// Enrollment availability
		{
			Keys: bson.D{
				{Key: "isActive", Value: 1},
				{Key: "acceptingEnrollments", Value: 1},
			},
			Options: options.Index().SetName("enrollments_idx"),
		},
		// Start date sorting
		{
			Keys: bson.D{
				{Key: "isActive", Value: 1},
				{Key: "startDate", Value: 1},
			},
			Options: options.Index().SetName("start_date_idx"),
		},
		// Discipline filter
		{
			Keys:    bson.D{{Key: "discipline", Value: 1}},
			Options: options.Index().SetName("discipline_idx"),
		},
		// Level filter
		{
			Keys: bson.D{
				{Key: "level", Value: 1},
				{Key: "startDate", Value: 1},
			},
			Options: options.Index().SetName("level_date_idx"),
		},
		// Text search
		{
			Keys: bson.D{
				{Key: "title", Value: "text"},
				{Key: "description", Value: "text"},
			},
			Options: options.Index().SetName("course_search_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de courses", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de courses creados", map[string]interface{}{"count": 8})
	return nil
}

// ============================================================================
// JUDGES AND CATEGORIES SYSTEM INDEXES
// ============================================================================

// createCompetitionCategoriesIndexes creates indexes for competition_categories collection
func createCompetitionCategoriesIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("competition_categories")

	indexes := []mongo.IndexModel{
		// Competition lookup (get all categories for a competition)
		{
			Keys:    bson.D{{Key: "competitionId", Value: 1}},
			Options: options.Index().SetName("competition_idx"),
		},
		// Active categories filter
		{
			Keys: bson.D{
				{Key: "competitionId", Value: 1},
				{Key: "createdAt", Value: -1},
			},
			Options: options.Index().SetName("competition_created_idx"),
		},
		// Skill level filter
		{
			Keys:    bson.D{{Key: "skillLevel", Value: 1}},
			Options: options.Index().SetName("skill_level_idx"),
		},
		// Participants lookup
		{
			Keys:    bson.D{{Key: "participants", Value: 1}},
			Options: options.Index().SetName("participants_idx"),
		},
		// Judges lookup
		{
			Keys:    bson.D{{Key: "judges", Value: 1}},
			Options: options.Index().SetName("judges_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de competition_categories", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de competition_categories creados", map[string]interface{}{"count": 5})
	return nil
}

// createJudgeInvitationsIndexes creates indexes for judge_invitations collection
func createJudgeInvitationsIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("judge_invitations")

	indexes := []mongo.IndexModel{
		// Category lookup
		{
			Keys:    bson.D{{Key: "categoryId", Value: 1}},
			Options: options.Index().SetName("category_idx"),
		},
		// Judge lookup (get all invitations for a judge)
		{
			Keys: bson.D{
				{Key: "judgeId", Value: 1},
				{Key: "status", Value: 1},
				{Key: "createdAt", Value: -1},
			},
			Options: options.Index().SetName("judge_status_idx"),
		},
		// Status filter
		{
			Keys: bson.D{
				{Key: "categoryId", Value: 1},
				{Key: "status", Value: 1},
			},
			Options: options.Index().SetName("category_status_idx"),
		},
		// Organizer lookup
		{
			Keys:    bson.D{{Key: "organizerId", Value: 1}},
			Options: options.Index().SetName("organizer_idx"),
		},
		// Expiration tracking (TTL index)
		{
			Keys:    bson.D{{Key: "expiresAt", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(86400).SetName("expiration_ttl"), // Delete 24h after expiration
		},
		// Pending invitations by category (for auto-cancellation)
		{
			Keys: bson.D{
				{Key: "categoryId", Value: 1},
				{Key: "status", Value: 1},
				{Key: "expiresAt", Value: 1},
			},
			Options: options.Index().SetName("category_pending_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de judge_invitations", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de judge_invitations creados", map[string]interface{}{"count": 6})
	return nil
}

// createJudgeScoresIndexes creates indexes for judge_scores collection
func createJudgeScoresIndexes(ctx context.Context, db *mongo.Database) error {
	collection := db.Collection("judge_scores")

	indexes := []mongo.IndexModel{
		// Category lookup (get all scores for rankings)
		{
			Keys: bson.D{
				{Key: "categoryId", Value: 1},
				{Key: "totalScore", Value: -1},
			},
			Options: options.Index().SetName("category_ranking_idx"),
		},
		// Participant lookup (get all scores for a participant)
		{
			Keys:    bson.D{{Key: "participantId", Value: 1}},
			Options: options.Index().SetName("participant_idx"),
		},
		// Judge lookup (get all scores by a judge)
		{
			Keys:    bson.D{{Key: "judgeId", Value: 1}},
			Options: options.Index().SetName("judge_idx"),
		},
		// Unique constraint - one score per judge per participant
		{
			Keys: bson.D{
				{Key: "categoryId", Value: 1},
				{Key: "participantId", Value: 1},
				{Key: "judgeId", Value: 1},
			},
			Options: options.Index().SetUnique(true).SetName("unique_judge_participant"),
		},
		// Competition lookup (for analytics)
		{
			Keys:    bson.D{{Key: "competitionId", Value: 1}},
			Options: options.Index().SetName("competition_idx"),
		},
		// Created date
		{
			Keys:    bson.D{{Key: "createdAt", Value: -1}},
			Options: options.Index().SetName("created_at_idx"),
		},
	}

	_, err := collection.Indexes().CreateMany(ctx, indexes)
	if err != nil {
		utils.Warn("Error creando índices de judge_scores", map[string]interface{}{"error": err.Error()})
		return err
	}
	utils.Debug("Índices de judge_scores creados", map[string]interface{}{"count": 6})
	return nil
}
