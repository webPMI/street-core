package main

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"backend/config"
	"backend/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Test database name
const testDBName = "streetcore_test_seed"

// setupTestDB creates a test database connection
func setupTestDB(t *testing.T) (*mongo.Client, *mongo.Database, func()) {
	// Use test MongoDB URI or default to localhost
	mongoURI := os.Getenv("TEST_MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Connect to MongoDB
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		t.Skipf("MongoDB not available: %v", err)
		return nil, nil, nil
	}

	// Ping to verify connection
	if err := client.Ping(ctx, nil); err != nil {
		t.Skipf("MongoDB not reachable: %v", err)
		return nil, nil, nil
	}

	db := client.Database(testDBName)

	// Cleanup function
	cleanup := func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		// Drop test database
		db.Drop(ctx)
		client.Disconnect(ctx)
	}

	return client, db, cleanup
}

// createTestSeedDir creates a temporary directory with test seed data
func createTestSeedDir(t *testing.T) (string, func()) {
	tempDir := t.TempDir()

	// Create sample competition JSON
	competitionData := map[string]interface{}{
		"competitions": []interface{}{
			map[string]interface{}{
				"_id":            map[string]interface{}{"$oid": "60a7b3c4e5f6a7b8c9d0e1f1"},
				"title":          "Test Competition",
				"description":    "Test competition for seeding",
				"organizerId":    map[string]interface{}{"$oid": "60a7b3c4e5f6a7b8c9d0e1a1"},
				"organizerName":  "Test Organizer",
				"competitionType": "individual",
				"format":         "single_round",
				"discipline":     "test_discipline",
				"schedule": map[string]interface{}{
					"startDate": map[string]interface{}{"$date": "2026-03-15T09:00:00Z"},
					"endDate":   map[string]interface{}{"$date": "2026-03-15T19:00:00Z"},
					"venue":     "Test Venue",
					"city":      "Test City",
					"country":   "Test Country",
				},
				"registration": map[string]interface{}{
					"maxParticipants":     50,
					"minParticipants":     2,
					"currentParticipants": 0,
					"participantStatus":   "open",
				},
				"scoringCriteria": map[string]interface{}{
					"type":     "points",
					"minScore": 0,
					"maxScore": 100,
					"criteria": []interface{}{
						map[string]interface{}{
							"name":     "Technique",
							"weight":   0.5,
							"maxScore": 50,
						},
						map[string]interface{}{
							"name":     "Style",
							"weight":   0.5,
							"maxScore": 50,
						},
					},
				},
				"requiredJudges": 3,
				"totalRounds":    1,
				"currentRound":   0,
				"status":         "upcoming",
				"isLive":         false,
				"createdAt":      map[string]interface{}{"$date": "2026-01-01T00:00:00Z"},
				"updatedAt":      map[string]interface{}{"$date": "2026-01-01T00:00:00Z"},
			},
		},
		"categories": []interface{}{
			map[string]interface{}{
				"_id":                map[string]interface{}{"$oid": "60a7b3c4e5f6a7b8c9d0e4f1"},
				"competitionId":      map[string]interface{}{"$oid": "60a7b3c4e5f6a7b8c9d0e1f1"},
				"name":               "Test Category",
				"maxParticipants":    30,
				"minParticipants":    2,
				"currentParticipants": 0,
				"status":             "active",
				"order":              1,
				"createdAt":          map[string]interface{}{"$date": "2026-01-01T00:00:00Z"},
				"updatedAt":          map[string]interface{}{"$date": "2026-01-01T00:00:00Z"},
			},
		},
		"participants": []interface{}{},
		"rounds":       []interface{}{},
		"heats":        []interface{}{},
		"scores":       []interface{}{},
	}

	// Write JSON file
	jsonData, err := json.MarshalIndent(competitionData, "", "  ")
	if err != nil {
		t.Fatalf("Failed to marshal test data: %v", err)
	}

	filePath := filepath.Join(tempDir, "competitions_test.json")
	if err := os.WriteFile(filePath, jsonData, 0644); err != nil {
		t.Fatalf("Failed to write test file: %v", err)
	}

	cleanup := func() {
		os.RemoveAll(tempDir)
	}

	return tempDir, cleanup
}

func TestSeeder_seedTestUsers(t *testing.T) {
	client, db, cleanup := setupTestDB(t)
	if db == nil {
		return // Test skipped
	}
	defer cleanup()

	ctx := context.Background()
	seeder := &Seeder{
		db:     db,
		ctx:    ctx,
		dryRun: false,
	}

	// Test user creation
	if err := seeder.seedTestUsers(); err != nil {
		t.Fatalf("seedTestUsers failed: %v", err)
	}

	// Verify users were created
	userCollection := db.Collection("users")

	// Check admin user
	var admin models.User
	err := userCollection.FindOne(ctx, bson.M{"email": "admin@streetcore.com"}).Decode(&admin)
	if err != nil {
		t.Fatalf("Admin user not found: %v", err)
	}

	if admin.Role != models.RoleAdmin {
		t.Errorf("Expected admin role, got %s", admin.Role)
	}

	if admin.FirstName != "Admin" {
		t.Errorf("Expected first name 'Admin', got %s", admin.FirstName)
	}

	// Check that password was hashed
	if len(admin.Password) < 30 {
		t.Error("Password was not hashed properly")
	}

	// Check judge users
	judgeCount, err := userCollection.CountDocuments(ctx, bson.M{"email": bson.M{"$regex": "^judge.*@streetcore.com$"}})
	if err != nil {
		t.Fatalf("Failed to count judges: %v", err)
	}

	if judgeCount != 3 {
		t.Errorf("Expected 3 judges, got %d", judgeCount)
	}

	// Check athlete users
	athleteCount, err := userCollection.CountDocuments(ctx, bson.M{"email": bson.M{"$regex": "^athlete.*@streetcore.com$"}})
	if err != nil {
		t.Fatalf("Failed to count athletes: %v", err)
	}

	if athleteCount != 5 {
		t.Errorf("Expected 5 athletes, got %d", athleteCount)
	}

	// Verify total user count
	totalCount, err := userCollection.CountDocuments(ctx, bson.M{"email": bson.M{"$regex": "@streetcore.com$"}})
	if err != nil {
		t.Fatalf("Failed to count total users: %v", err)
	}

	if totalCount != 9 {
		t.Errorf("Expected 9 total users, got %d", totalCount)
	}

	// Test idempotency - run again
	if err := seeder.seedTestUsers(); err != nil {
		t.Fatalf("Second seedTestUsers failed: %v", err)
	}

	// Verify count didn't change
	newCount, err := userCollection.CountDocuments(ctx, bson.M{"email": bson.M{"$regex": "@streetcore.com$"}})
	if err != nil {
		t.Fatalf("Failed to count users after re-seeding: %v", err)
	}

	if newCount != totalCount {
		t.Errorf("Idempotency failed: expected %d users, got %d", totalCount, newCount)
	}
}

func TestSeeder_seedCompetitionFile(t *testing.T) {
	client, db, cleanup := setupTestDB(t)
	if db == nil {
		return // Test skipped
	}
	defer cleanup()

	seedDir, cleanupSeed := createTestSeedDir(t)
	defer cleanupSeed()

	ctx := context.Background()
	seeder := &Seeder{
		db:          db,
		ctx:         ctx,
		seedDataDir: seedDir,
		dryRun:      false,
	}

	// Seed the test file
	filePath := filepath.Join(seedDir, "competitions_test.json")
	if err := seeder.seedCompetitionFile(filePath); err != nil {
		t.Fatalf("seedCompetitionFile failed: %v", err)
	}

	// Verify competition was inserted
	competitionCollection := db.Collection("competitions")
	compCount, err := competitionCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("Failed to count competitions: %v", err)
	}

	if compCount != 1 {
		t.Errorf("Expected 1 competition, got %d", compCount)
	}

	// Verify competition data
	compID, _ := primitive.ObjectIDFromHex("60a7b3c4e5f6a7b8c9d0e1f1")
	var competition bson.M
	err = competitionCollection.FindOne(ctx, bson.M{"_id": compID}).Decode(&competition)
	if err != nil {
		t.Fatalf("Competition not found: %v", err)
	}

	if competition["title"] != "Test Competition" {
		t.Errorf("Expected title 'Test Competition', got %v", competition["title"])
	}

	if competition["status"] != "upcoming" {
		t.Errorf("Expected status 'upcoming', got %v", competition["status"])
	}

	// Verify category was inserted
	categoryCollection := db.Collection("categories")
	catCount, err := categoryCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("Failed to count categories: %v", err)
	}

	if catCount != 1 {
		t.Errorf("Expected 1 category, got %d", catCount)
	}

	// Verify category data
	var category bson.M
	err = categoryCollection.FindOne(ctx, bson.M{"competitionId": compID}).Decode(&category)
	if err != nil {
		t.Fatalf("Category not found: %v", err)
	}

	if category["name"] != "Test Category" {
		t.Errorf("Expected category name 'Test Category', got %v", category["name"])
	}
}

func TestSeeder_convertTimestamps(t *testing.T) {
	seeder := &Seeder{}

	// Test timestamp conversion
	doc := map[string]interface{}{
		"name": "Test",
		"createdAt": map[string]interface{}{
			"$date": "2026-01-15T10:00:00Z",
		},
		"nested": map[string]interface{}{
			"updatedAt": map[string]interface{}{
				"$date": "2026-01-16T15:30:00Z",
			},
		},
	}

	converted := seeder.convertTimestamps(doc)

	// Check top-level timestamp
	createdAt, ok := converted["createdAt"].(time.Time)
	if !ok {
		t.Error("createdAt was not converted to time.Time")
	}

	expectedTime := time.Date(2026, 1, 15, 10, 0, 0, 0, time.UTC)
	if !createdAt.Equal(expectedTime) {
		t.Errorf("Expected %v, got %v", expectedTime, createdAt)
	}

	// Check nested timestamp
	nested, ok := converted["nested"].(map[string]interface{})
	if !ok {
		t.Fatal("Nested object was not preserved")
	}

	updatedAt, ok := nested["updatedAt"].(time.Time)
	if !ok {
		t.Error("nested.updatedAt was not converted to time.Time")
	}

	expectedNestedTime := time.Date(2026, 1, 16, 15, 30, 0, 0, time.UTC)
	if !updatedAt.Equal(expectedNestedTime) {
		t.Errorf("Expected %v, got %v", expectedNestedTime, updatedAt)
	}

	// Check that non-timestamp fields are preserved
	if converted["name"] != "Test" {
		t.Error("Non-timestamp field was modified")
	}
}

func TestSeeder_cleanExistingData(t *testing.T) {
	client, db, cleanup := setupTestDB(t)
	if db == nil {
		return // Test skipped
	}
	defer cleanup()

	ctx := context.Background()

	// Insert some test data
	competitionCollection := db.Collection("competitions")
	_, err := competitionCollection.InsertOne(ctx, bson.M{
		"_id":   primitive.NewObjectID(),
		"title": "Test Competition",
	})
	if err != nil {
		t.Fatalf("Failed to insert test competition: %v", err)
	}

	participantCollection := db.Collection("participants")
	_, err = participantCollection.InsertOne(ctx, bson.M{
		"_id":           primitive.NewObjectID(),
		"competitionId": primitive.NewObjectID(),
		"athleteName":   "Test Athlete",
	})
	if err != nil {
		t.Fatalf("Failed to insert test participant: %v", err)
	}

	// Verify data exists
	compCount, _ := competitionCollection.CountDocuments(ctx, bson.M{})
	if compCount == 0 {
		t.Fatal("Test data was not inserted")
	}

	// Clean data
	seeder := &Seeder{
		db:  db,
		ctx: ctx,
	}

	if err := seeder.cleanExistingData(); err != nil {
		t.Fatalf("cleanExistingData failed: %v", err)
	}

	// Verify data was deleted
	compCount, err = competitionCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("Failed to count competitions: %v", err)
	}

	if compCount != 0 {
		t.Errorf("Expected 0 competitions after cleaning, got %d", compCount)
	}

	partCount, err := participantCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("Failed to count participants: %v", err)
	}

	if partCount != 0 {
		t.Errorf("Expected 0 participants after cleaning, got %d", partCount)
	}
}

func TestSeeder_dryRunMode(t *testing.T) {
	client, db, cleanup := setupTestDB(t)
	if db == nil {
		return // Test skipped
	}
	defer cleanup()

	ctx := context.Background()
	seeder := &Seeder{
		db:     db,
		ctx:    ctx,
		dryRun: true, // Dry run mode enabled
	}

	// Test dry run for user creation
	if err := seeder.seedTestUsers(); err != nil {
		t.Fatalf("Dry run failed: %v", err)
	}

	// Verify no data was inserted
	userCollection := db.Collection("users")
	count, err := userCollection.CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("Failed to count users: %v", err)
	}

	if count != 0 {
		t.Errorf("Dry run inserted data - expected 0 users, got %d", count)
	}
}

// Benchmark seeding performance
func BenchmarkSeeder_seedTestUsers(b *testing.B) {
	// Skip if MongoDB not available
	mongoURI := os.Getenv("TEST_MONGO_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	ctx := context.Background()
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		b.Skip("MongoDB not available")
	}
	defer client.Disconnect(ctx)

	db := client.Database(testDBName + "_bench")
	defer db.Drop(ctx)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		seeder := &Seeder{
			db:     db,
			ctx:    ctx,
			dryRun: false,
		}

		if err := seeder.seedTestUsers(); err != nil {
			b.Fatalf("seedTestUsers failed: %v", err)
		}

		// Clean up for next iteration
		db.Collection("users").DeleteMany(ctx, bson.M{})
	}
}
