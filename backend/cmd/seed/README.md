# Database Seeder

**Version**: 1.0
**Path**: `backend/cmd/seed/`
**Purpose**: Populate MongoDB with realistic test data for development and testing

---

## Overview

The database seeder is a standalone Go application that injects test data into MongoDB. It creates:

- **Test users** (admin, judges, athletes) with hashed passwords
- **Competitions** with proper relationships
- **Categories, participants, rounds, heats, scores** from JSON files

The seeder is **idempotent** - it can be run multiple times without duplicating data.

---

## Quick Start

### Using Shell Scripts (Recommended)

**Linux/Mac:**
```bash
cd backend/scripts
./seed.sh
```

**Windows:**
```cmd
cd backend\scripts
seed.bat
```

### Direct Go Execution

```bash
cd backend
go run ./cmd/seed --dir=../seeds
```

### Build and Run

```bash
cd backend
go build -o bin/seed ./cmd/seed
./bin/seed --dir=../seeds
```

---

## Command-Line Options

```
Usage: seed [OPTIONS]

Options:
  --dir PATH       Seed data directory (default: ../../seeds)
  --dry-run        Preview without inserting data
  --clean          Delete existing competition data first
  --help           Show help message
```

### Examples

**Preview changes:**
```bash
./bin/seed --dry-run
```

**Clean and reseed:**
```bash
./bin/seed --clean
```

**Custom seed directory:**
```bash
./bin/seed --dir=/path/to/seeds
```

---

## Architecture

```
cmd/seed/
└── main.go              # Seeder implementation

Key Components:
├── Seeder struct        # Orchestrates seeding process
├── SeedStats struct     # Tracks statistics
├── seedAll()            # Main entry point
├── seedTestUsers()      # Creates test users
├── seedCompetitionsFromJSON()  # Loads JSON files
└── seedCompetition()    # Seeds single competition

Flow:
1. Load config & connect to MongoDB
2. Create test users (admin, judges, athletes)
3. Load JSON files from seed directory
4. For each competition:
   - Insert competition document
   - Insert related categories
   - Insert participants
   - Insert rounds, heats, scores
5. Print statistics
```

---

## Test Users Created

The seeder automatically creates 9 test users:

### 1. Admin Account
```
Email: admin@streetcore.com
Password: Admin123!
Role: admin
Name: Admin System
```

### 2. Judge Accounts (3)
```
judge1@streetcore.com / Judge123!  (Carlos Mendez)
judge2@streetcore.com / Judge123!  (Maria Rodriguez)
judge3@streetcore.com / Judge123!  (Luis Gomez)
```

### 3. Athlete Accounts (5)
```
athlete1@streetcore.com / Athlete123!  (Juan Perez - Skater)
athlete2@streetcore.com / Athlete123!  (Sofia Garcia - BMX)
athlete3@streetcore.com / Athlete123!  (Diego Martinez - Street)
athlete4@streetcore.com / Athlete123!  (Ana Lopez - Park)
athlete5@streetcore.com / Athlete123!  (Miguel Torres - Vert)
```

**Notes:**
- Passwords are hashed using bcrypt (cost 12)
- Users are skipped if they already exist (by email)
- All users have `isActive: true`

---

## Seed Data Format

The seeder expects JSON files in the `seeds/` directory with the following structure:

### File Naming Convention
```
competitions_*.json
```

Examples:
- `competitions_bmx.json`
- `competitions_skate.json`
- `competitions_sample.json`

### JSON Structure

```json
{
  "competitions": [
    {
      "_id": {"$oid": "60a7b3c4e5f6a7b8c9d0e1f1"},
      "title": "Madrid Street Battle 2026",
      "description": "...",
      "organizerId": {"$oid": "..."},
      "competitionType": "individual",
      "format": "single_round",
      "discipline": "street_skating",
      "schedule": {
        "startDate": {"$date": "2026-03-15T09:00:00Z"},
        "endDate": {"$date": "2026-03-15T19:00:00Z"},
        "venue": "Skate Plaza Central"
      },
      "registration": {
        "maxParticipants": 50,
        "currentParticipants": 5
      },
      "scoringCriteria": {
        "type": "weighted_average",
        "criteria": [...]
      },
      "status": "upcoming",
      "createdAt": {"$date": "2026-01-05T10:00:00Z"},
      "updatedAt": {"$date": "2026-01-10T15:30:00Z"}
    }
  ],
  "categories": [...],
  "participants": [...],
  "rounds": [...],
  "heats": [...],
  "scores": [...]
}
```

### Key Points

1. **ObjectID Format**: Use `{"$oid": "hex_string"}`
2. **Date Format**: Use `{"$date": "ISO8601_string"}`
3. **Relationships**: Foreign keys must match (e.g., `competitionId` references competition `_id`)
4. **Validation**: Data should pass entity validation (see domain models)

---

## Seeding Process

### 1. Configuration Loading
- Reads `.env` file for MongoDB credentials
- Initializes logger
- Connects to MongoDB with retry logic

### 2. Test User Creation
- Checks if users exist by email
- Creates users if not found
- Hashes passwords using bcrypt
- Skips duplicates (idempotent)

### 3. JSON File Processing
- Scans `seeds/` directory for `competitions_*.json`
- Loads and validates JSON structure
- Extracts competitions and related entities

### 4. Data Insertion
For each competition:
1. Check if competition exists (by `_id`)
2. Insert competition document
3. Insert related categories (matching `competitionId`)
4. Insert participants (matching `competitionId`)
5. Insert rounds (matching `competitionId`)
6. Insert heats (matching `competitionId`)
7. Insert scores (matching `competitionId`)

### 5. Statistics Reporting
- Users created
- Competitions seeded
- Categories, participants, rounds, heats, scores
- Errors encountered
- Total duration

---

## Idempotency

The seeder can be run multiple times safely:

**Users:**
- Query by email before inserting
- Skip if user exists
- No duplicates created

**Competitions:**
- Query by `_id` before inserting
- Skip if competition exists
- Related entities only inserted if parent exists

**Clean Mode:**
```bash
./bin/seed --clean
```
- Deletes all competition-related data
- Preserves test users
- Collections cleared: competitions, categories, participants, rounds, heats, scores, leaderboards, judge_invitations

---

## Verification

### Using Verification Script

```bash
cd backend/scripts
chmod +x verify-seed.sh
./verify-seed.sh
```

This checks:
- Test user counts and roles
- Competition counts by status
- Category distribution
- Participant assignments
- Score statistics
- Data integrity (orphaned records)

### Manual MongoDB Queries

```javascript
// Connect to MongoDB
mongosh streetcore

// Check users
db.users.find({email: /@streetcore.com$/}).pretty()

// Check competitions
db.competitions.countDocuments()
db.competitions.find({}, {title: 1, status: 1}).pretty()

// Check participants
db.participants.aggregate([
  {$group: {_id: "$competitionId", count: {$sum: 1}}}
])

// Check scores
db.scores.aggregate([
  {$group: {_id: "$competitionId", count: {$sum: 1}, avg: {$avg: "$totalScore"}}}
])
```

### API Testing

```bash
# Login as admin
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@streetcore.com","password":"Admin123!"}'

# Get competitions
curl -X GET http://localhost:3000/api/v1/competitions \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get specific competition
curl -X GET http://localhost:3000/api/v1/competitions/{id} \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Troubleshooting

### Build Errors

**Error: Cannot find package**
```bash
cd backend
go mod tidy
go mod download
```

**Error: Permission denied**
```bash
chmod +x scripts/seed.sh
chmod +x scripts/verify-seed.sh
```

### Connection Errors

**Error: Failed to connect to MongoDB**
- Check if MongoDB is running: `docker ps`
- Verify `.env` credentials: `MONGO_URI`, `DB_NAME`
- Test connection: `mongosh $MONGO_URI`

**Error: Authentication failed**
- Verify `DB_APP_USER` and `DB_APP_PASS` in `.env`
- Ensure user exists in MongoDB: `db.getUsers()`

### Data Errors

**Error: Failed to insert competition**
- Check ObjectID format in JSON: `{"$oid": "..."}`
- Verify foreign key references exist
- Ensure no duplicate `_id` values

**Error: Invalid date format**
- Use ISO 8601 format: `2026-01-15T10:00:00Z`
- Wrap in MongoDB date object: `{"$date": "..."}`

---

## Advanced Usage

### Custom Seed Data

Create your own JSON file:

```bash
cat > seeds/competitions_custom.json << 'EOF'
{
  "competitions": [
    {
      "_id": {"$oid": "60a7b3c4e5f6a7b8c9d0e1f2"},
      "title": "My Custom Competition",
      ...
    }
  ]
}
EOF

./scripts/seed.sh
```

### Programmatic Usage

```go
import (
    "backend/cmd/seed"
    "backend/config"
    "context"
)

func main() {
    // Load config
    config.LoadConfig()

    // Connect to MongoDB
    client, db := config.ConnectMongo()
    defer client.Disconnect(context.Background())

    // Create seeder
    seeder := seed.NewSeeder(db, context.Background(), "./seeds")

    // Run seeding
    if err := seeder.SeedAll(); err != nil {
        log.Fatal(err)
    }
}
```

### CI/CD Integration

**GitHub Actions:**
```yaml
- name: Seed test database
  run: |
    cd backend
    go run ./cmd/seed --dir=../seeds
```

**Docker Compose:**
```yaml
services:
  seed:
    build: .
    command: ["./bin/seed", "--dir=/seeds"]
    volumes:
      - ./seeds:/seeds
```

---

## Performance

### Benchmarks

| Operation | Documents | Duration |
|-----------|-----------|----------|
| Test users | 9 | ~500ms |
| Small competition | 1 comp, 10 participants | ~1s |
| Medium competition | 1 comp, 50 participants, 150 scores | ~3s |
| Large dataset | 10 comps, 500 participants, 1500 scores | ~15s |

### Optimization Tips

1. **Use bulk operations** for large datasets (TODO)
2. **Disable indexes temporarily** for mass inserts (TODO)
3. **Run in transactions** for data integrity (TODO)
4. **Use dry-run mode** to validate before inserting

---

## Related Files

```
backend/
├── cmd/seed/
│   ├── main.go              # Seeder implementation
│   └── README.md            # This file
├── scripts/
│   ├── seed.sh              # Linux/Mac wrapper
│   ├── seed.bat             # Windows wrapper
│   └── verify-seed.sh       # Verification script
└── docs/guides/
    └── DATABASE_SEEDING.md  # Complete guide
```

**Sample seed data:**
- `seeds/competitions_sample.json` - Example structure

---

## Future Enhancements

- [ ] Bulk insert operations for performance
- [ ] Transaction support for atomicity
- [ ] Seed data versioning
- [ ] Seed data generator (random realistic data)
- [ ] Administrative endpoint: `POST /admin/seed`
- [ ] Progress bar for large datasets
- [ ] Rollback support (undo seeding)

---

## Support

For issues or questions:

1. Check `backend/docs/guides/DATABASE_SEEDING.md`
2. Review error messages in console output
3. Run verification script: `./scripts/verify-seed.sh`
4. Check logs: `backend/logs/app.log`
5. Contact Backend Agent

---

**Happy Seeding! 🌱**
