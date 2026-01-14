package main

import (
	"backend/config"
	"backend/models"
	"backend/utils"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Seeder orchestrates the seeding process
type Seeder struct {
	db          *mongo.Database
	ctx         context.Context
	seedDataDir string
	stats       SeedStats
	dryRun      bool
}

// SeedStats tracks seeding statistics
type SeedStats struct {
	UsersCreated       int
	CompetitionsSeeded int
	CategoriesSeeded   int
	ParticipantsSeeded int
	RoundsSeeded       int
	HeatsSeeded        int
	ScoresSeeded       int
	Errors             []string
	StartTime          time.Time
	EndTime            time.Time
}

func main() {
	// Parse command-line flags
	seedDir := flag.String("dir", "../../seeds", "Directory containing seed data JSON files")
	dryRun := flag.Bool("dry-run", false, "Perform dry run without inserting data")
	clean := flag.Bool("clean", false, "Clean existing competition data before seeding")
	flag.Parse()

	fmt.Println("🌱 StreetCore Database Seeding Tool")
	fmt.Println("====================================")

	// Load configuration
	if err := config.LoadConfig(); err != nil {
		fmt.Printf("❌ Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// Initialize logger
	utils.InitLogger()

	// Connect to MongoDB
	client, db := config.ConnectMongo()
	if db == nil {
		fmt.Println("❌ Failed to connect to MongoDB")
		os.Exit(1)
	}
	defer client.Disconnect(context.Background())

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	// Create seeder
	seeder := &Seeder{
		db:          db,
		ctx:         ctx,
		seedDataDir: *seedDir,
		dryRun:      *dryRun,
		stats: SeedStats{
			StartTime: time.Now(),
		},
	}

	if *dryRun {
		fmt.Println("🔍 DRY RUN MODE - No data will be inserted")
	}

	// Clean existing data if requested
	if *clean && !*dryRun {
		if err := seeder.cleanExistingData(); err != nil {
			fmt.Printf("❌ Failed to clean existing data: %v\n", err)
			os.Exit(1)
		}
	}

	// Execute seeding
	if err := seeder.seedAll(); err != nil {
		fmt.Printf("❌ Seeding failed: %v\n", err)
		os.Exit(1)
	}

	// Print statistics
	seeder.printStats()

	if len(seeder.stats.Errors) > 0 {
		fmt.Println("\n⚠️  Seeding completed with errors")
		os.Exit(1)
	}

	fmt.Println("\n✅ Seeding completed successfully!")
}

// seedAll orchestrates the complete seeding process
func (s *Seeder) seedAll() error {
	fmt.Println("\n📊 Starting seeding process...")

	// 1. Seed test users (admin, judges, athletes)
	if err := s.seedTestUsers(); err != nil {
		return fmt.Errorf("failed to seed test users: %w", err)
	}

	// 2. Load and seed competitions data from JSON files
	if err := s.seedCompetitionsFromJSON(); err != nil {
		return fmt.Errorf("failed to seed competitions: %w", err)
	}

	return nil
}

// seedTestUsers creates test users for authentication
func (s *Seeder) seedTestUsers() error {
	fmt.Println("\n👥 Creating test users...")

	users := []struct {
		Email     string
		Password  string
		FirstName string
		LastName  string
		Role      string
		NickName  string
	}{
		{"admin@streetcore.com", "Admin123!", "Admin", "System", models.RoleAdmin, "Administrator"},
		{"judge1@streetcore.com", "Judge123!", "Carlos", "Mendez", models.RoleUser, "Judge_Carlos"},
		{"judge2@streetcore.com", "Judge123!", "Maria", "Rodriguez", models.RoleUser, "Judge_Maria"},
		{"judge3@streetcore.com", "Judge123!", "Luis", "Gomez", models.RoleUser, "Judge_Luis"},
		{"athlete1@streetcore.com", "Athlete123!", "Juan", "Perez", models.RoleUser, "Skater_Juan"},
		{"athlete2@streetcore.com", "Athlete123!", "Sofia", "Garcia", models.RoleUser, "BMX_Sofia"},
		{"athlete3@streetcore.com", "Athlete123!", "Diego", "Martinez", models.RoleUser, "Street_Diego"},
		{"athlete4@streetcore.com", "Athlete123!", "Ana", "Lopez", models.RoleUser, "Park_Ana"},
		{"athlete5@streetcore.com", "Athlete123!", "Miguel", "Torres", models.RoleUser, "Vert_Miguel"},
	}

	userCollection := s.db.Collection("users")

	for _, userData := range users {
		// Check if user already exists
		var existing models.User
		err := userCollection.FindOne(s.ctx, bson.M{"email": userData.Email}).Decode(&existing)
		if err == nil {
			fmt.Printf("   ⏭️  User %s already exists\n", userData.Email)
			continue
		}

		if s.dryRun {
			fmt.Printf("   🔍 [DRY RUN] Would create user: %s (%s)\n", userData.Email, userData.Role)
			continue
		}

		// Create user
		user := &models.User{
			Email:     userData.Email,
			FirstName: userData.FirstName,
			LastName:  userData.LastName,
			Role:      userData.Role,
			Password:  userData.Password,
			NickName:  &userData.NickName,
			IsActive:  true,
		}

		// Prepare for insert (hashes password)
		if err := user.PrepareForInsert(); err != nil {
			s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to prepare user %s: %v", userData.Email, err))
			continue
		}

		// Insert user
		_, err = userCollection.InsertOne(s.ctx, user)
		if err != nil {
			s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to insert user %s: %v", userData.Email, err))
			continue
		}

		s.stats.UsersCreated++
		fmt.Printf("   ✅ Created user: %s (%s)\n", userData.Email, userData.Role)
	}

	return nil
}

// seedCompetitionsFromJSON loads competition data from JSON files
func (s *Seeder) seedCompetitionsFromJSON() error {
	fmt.Println("\n🏆 Seeding competitions from JSON files...")

	// Check if seed directory exists
	if _, err := os.Stat(s.seedDataDir); os.IsNotExist(err) {
		fmt.Printf("   ⚠️  Seed directory not found: %s\n", s.seedDataDir)
		fmt.Println("   💡 Run the database seed generation tool first")
		return nil
	}

	// Look for competition JSON files
	competitionFiles, err := filepath.Glob(filepath.Join(s.seedDataDir, "competitions_*.json"))
	if err != nil {
		return fmt.Errorf("failed to find competition files: %w", err)
	}

	if len(competitionFiles) == 0 {
		fmt.Println("   ⚠️  No competition JSON files found")
		return nil
	}

	// Seed each competition file
	for _, file := range competitionFiles {
		if err := s.seedCompetitionFile(file); err != nil {
			s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to seed file %s: %v", file, err))
			continue
		}
	}

	return nil
}

// seedCompetitionFile seeds a single competition JSON file
func (s *Seeder) seedCompetitionFile(filePath string) error {
	fmt.Printf("\n   📄 Processing: %s\n", filepath.Base(filePath))

	// Read JSON file
	data, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file: %w", err)
	}

	// Parse JSON structure
	var competitionData map[string]interface{}
	if err := json.Unmarshal(data, &competitionData); err != nil {
		return fmt.Errorf("failed to parse JSON: %w", err)
	}

	// Extract collections
	competitions, ok := competitionData["competitions"].([]interface{})
	if !ok || len(competitions) == 0 {
		return fmt.Errorf("no competitions found in file")
	}

	// Seed each competition with its related data
	for _, comp := range competitions {
		competition := comp.(map[string]interface{})
		if err := s.seedCompetition(competition, competitionData); err != nil {
			s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to seed competition: %v", err))
			continue
		}
	}

	return nil
}

// seedCompetition seeds a single competition and its related entities
func (s *Seeder) seedCompetition(competition map[string]interface{}, allData map[string]interface{}) error {
	title := competition["title"].(string)
	fmt.Printf("      🏆 Seeding competition: %s\n", title)

	if s.dryRun {
		fmt.Printf("         🔍 [DRY RUN] Would insert competition and related data\n")
		return nil
	}

	// Get competition ID
	compIDStr := competition["_id"].(map[string]interface{})["$oid"].(string)
	compID, err := primitive.ObjectIDFromHex(compIDStr)
	if err != nil {
		return fmt.Errorf("invalid competition ID: %w", err)
	}

	// Check if competition already exists
	competitionCol := s.db.Collection("competitions")
	var existing bson.M
	err = competitionCol.FindOne(s.ctx, bson.M{"_id": compID}).Decode(&existing)
	if err == nil {
		fmt.Printf("         ⏭️  Competition already exists\n")
		return nil
	}

	// Convert and insert competition
	if err := s.insertDocument("competitions", competition); err != nil {
		return fmt.Errorf("failed to insert competition: %w", err)
	}
	s.stats.CompetitionsSeeded++

	// Seed related entities
	if err := s.seedRelatedEntities(compID, allData); err != nil {
		return fmt.Errorf("failed to seed related entities: %w", err)
	}

	fmt.Printf("         ✅ Competition seeded successfully\n")
	return nil
}

// seedRelatedEntities seeds categories, participants, rounds, heats, and scores
func (s *Seeder) seedRelatedEntities(compID primitive.ObjectID, allData map[string]interface{}) error {
	// Seed categories
	if categories, ok := allData["categories"].([]interface{}); ok {
		for _, cat := range categories {
			category := cat.(map[string]interface{})
			catCompID := category["competitionId"].(map[string]interface{})["$oid"].(string)
			if catCompID == compID.Hex() {
				if err := s.insertDocument("categories", category); err != nil {
					s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to insert category: %v", err))
				} else {
					s.stats.CategoriesSeeded++
				}
			}
		}
	}

	// Seed participants
	if participants, ok := allData["participants"].([]interface{}); ok {
		for _, part := range participants {
			participant := part.(map[string]interface{})
			partCompID := participant["competitionId"].(map[string]interface{})["$oid"].(string)
			if partCompID == compID.Hex() {
				if err := s.insertDocument("participants", participant); err != nil {
					s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to insert participant: %v", err))
				} else {
					s.stats.ParticipantsSeeded++
				}
			}
		}
	}

	// Seed rounds
	if rounds, ok := allData["rounds"].([]interface{}); ok {
		for _, rnd := range rounds {
			round := rnd.(map[string]interface{})
			rndCompID := round["competitionId"].(map[string]interface{})["$oid"].(string)
			if rndCompID == compID.Hex() {
				if err := s.insertDocument("rounds", round); err != nil {
					s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to insert round: %v", err))
				} else {
					s.stats.RoundsSeeded++
				}
			}
		}
	}

	// Seed heats
	if heats, ok := allData["heats"].([]interface{}); ok {
		for _, ht := range heats {
			heat := ht.(map[string]interface{})
			htCompID := heat["competitionId"].(map[string]interface{})["$oid"].(string)
			if htCompID == compID.Hex() {
				if err := s.insertDocument("heats", heat); err != nil {
					s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to insert heat: %v", err))
				} else {
					s.stats.HeatsSeeded++
				}
			}
		}
	}

	// Seed scores
	if scores, ok := allData["scores"].([]interface{}); ok {
		for _, sc := range scores {
			score := sc.(map[string]interface{})
			scCompID := score["competitionId"].(map[string]interface{})["$oid"].(string)
			if scCompID == compID.Hex() {
				if err := s.insertDocument("scores", score); err != nil {
					s.stats.Errors = append(s.stats.Errors, fmt.Sprintf("Failed to insert score: %v", err))
				} else {
					s.stats.ScoresSeeded++
				}
			}
		}
	}

	return nil
}

// insertDocument inserts a document into the specified collection
func (s *Seeder) insertDocument(collectionName string, doc map[string]interface{}) error {
	collection := s.db.Collection(collectionName)

	// Convert JSON timestamps to Go time.Time
	doc = s.convertTimestamps(doc)

	_, err := collection.InsertOne(s.ctx, doc)
	return err
}

// convertTimestamps recursively converts MongoDB date objects to time.Time
func (s *Seeder) convertTimestamps(doc map[string]interface{}) map[string]interface{} {
	for key, value := range doc {
		switch v := value.(type) {
		case map[string]interface{}:
			// Check if it's a MongoDB date object
			if dateStr, ok := v["$date"].(string); ok {
				if parsedTime, err := time.Parse(time.RFC3339, dateStr); err == nil {
					doc[key] = parsedTime
				}
			} else {
				// Recursively convert nested objects
				doc[key] = s.convertTimestamps(v)
			}
		}
	}
	return doc
}

// cleanExistingData removes existing competition data
func (s *Seeder) cleanExistingData() error {
	fmt.Println("\n🧹 Cleaning existing competition data...")

	collections := []string{
		"competitions",
		"categories",
		"participants",
		"rounds",
		"heats",
		"scores",
		"leaderboards",
		"judge_invitations",
	}

	for _, collName := range collections {
		collection := s.db.Collection(collName)
		result, err := collection.DeleteMany(s.ctx, bson.M{})
		if err != nil {
			return fmt.Errorf("failed to clean %s: %w", collName, err)
		}
		if result.DeletedCount > 0 {
			fmt.Printf("   ✅ Deleted %d documents from %s\n", result.DeletedCount, collName)
		}
	}

	return nil
}

// printStats prints seeding statistics
func (s *Seeder) printStats() {
	s.stats.EndTime = time.Now()
	duration := s.stats.EndTime.Sub(s.stats.StartTime)

	fmt.Println("\n📊 Seeding Statistics")
	fmt.Println("=====================")
	fmt.Printf("⏱️  Duration: %s\n", duration.Round(time.Millisecond))
	fmt.Printf("👥 Users created: %d\n", s.stats.UsersCreated)
	fmt.Printf("🏆 Competitions seeded: %d\n", s.stats.CompetitionsSeeded)
	fmt.Printf("📋 Categories seeded: %d\n", s.stats.CategoriesSeeded)
	fmt.Printf("👤 Participants seeded: %d\n", s.stats.ParticipantsSeeded)
	fmt.Printf("🔄 Rounds seeded: %d\n", s.stats.RoundsSeeded)
	fmt.Printf("🔥 Heats seeded: %d\n", s.stats.HeatsSeeded)
	fmt.Printf("🎯 Scores seeded: %d\n", s.stats.ScoresSeeded)

	if len(s.stats.Errors) > 0 {
		fmt.Printf("\n⚠️  Errors encountered: %d\n", len(s.stats.Errors))
		for i, err := range s.stats.Errors {
			if i >= 10 {
				fmt.Printf("   ... and %d more errors\n", len(s.stats.Errors)-10)
				break
			}
			fmt.Printf("   • %s\n", err)
		}
	}
}
