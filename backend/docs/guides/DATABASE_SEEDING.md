# Database Seeding Guide

**Version**: 1.0
**Last Updated**: 2026-01-11

## Overview

The StreetCore seeding system provides a robust way to populate the MongoDB database with realistic test data for development and testing. The seeder injects competitions, participants, scores, and test users with proper relationships and validation.

---

## Quick Start

### Prerequisites

1. MongoDB running (Docker or local)
2. `.env` file configured with MongoDB credentials
3. Go 1.24+ installed

### Basic Usage

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

**Direct Go execution:**
```bash
cd backend
go run ./cmd/seed --dir=../seeds
```

---

## Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dir PATH` | Seed data directory | `../../seeds` |
| `--dry-run` | Preview without inserting | `false` |
| `--clean` | Delete existing data first | `false` |
| `--help` | Show help message | - |

### Examples

**Dry run to preview:**
```bash
./seed.sh --dry-run
```

**Clean and reseed:**
```bash
./seed.sh --clean
```

**Custom seed directory:**
```bash
./seed.sh --dir=/path/to/custom/seeds
```

---

## Test Users

The seeder automatically creates the following test users:

### Admin Account
- **Email**: `admin@streetcore.com`
- **Password**: `Admin123!`
- **Role**: `admin`
- **Use**: Full system access, competition management

### Judge Accounts (3 judges)
- **judge1@streetcore.com** / `Judge123!` - Carlos Mendez
- **judge2@streetcore.com** / `Judge123!` - Maria Rodriguez
- **judge3@streetcore.com** / `Judge123!` - Luis Gomez
- **Role**: `user` (with judge permissions in competitions)
- **Use**: Score submissions, judge panel management

### Athlete Accounts (5 athletes)
- **athlete1@streetcore.com** / `Athlete123!` - Juan Perez (Skater)
- **athlete2@streetcore.com** / `Athlete123!` - Sofia Garcia (BMX)
- **athlete3@streetcore.com** / `Athlete123!` - Diego Martinez (Street)
- **athlete4@streetcore.com** / `Athlete123!` - Ana Lopez (Park)
- **athlete5@streetcore.com** / `Athlete123!` - Miguel Torres (Vert)
- **Role**: `user`
- **Use**: Competition registration, athlete profiles

---

## Seed Data Format

The seeder expects JSON files in the following format:

### Directory Structure
```
seeds/
├── competitions_bmx.json
├── competitions_skate.json
└── competitions_scooter.json
```

### JSON Schema

**competitions_*.json:**
```json
{
  "competitions": [
    {
      "_id": {"$oid": "507f1f77bcf86cd799439011"},
      "title": "Street Battle 2026",
      "description": "Annual street competition...",
      "organizerId": {"$oid": "..."},
      "competitionType": "individual",
      "format": "single_round",
      "discipline": "street_skating",
      "schedule": {
        "startDate": {"$date": "2026-03-15T10:00:00Z"},
        "endDate": {"$date": "2026-03-15T18:00:00Z"},
        "venue": "Skate Plaza Central",
        "city": "Madrid",
        "country": "Spain"
      },
      "registration": {
        "maxParticipants": 50,
        "minParticipants": 8,
        "currentParticipants": 0,
        "participantStatus": "open"
      },
      "scoringCriteria": {
        "type": "points",
        "minScore": 0,
        "maxScore": 100,
        "criteria": [
          {
            "name": "Technique",
            "weight": 0.4,
            "maxScore": 40
          },
          {
            "name": "Difficulty",
            "weight": 0.3,
            "maxScore": 30
          },
          {
            "name": "Style",
            "weight": 0.3,
            "maxScore": 30
          }
        ]
      },
      "status": "upcoming",
      "createdAt": {"$date": "2026-01-01T00:00:00Z"},
      "updatedAt": {"$date": "2026-01-01T00:00:00Z"}
    }
  ],
  "categories": [...],
  "participants": [...],
  "rounds": [...],
  "heats": [...],
  "scores": [...]
}
```

### Key Features

1. **ObjectID References**: Proper MongoDB ObjectID format with `{"$oid": "..."}`
2. **Date Handling**: ISO 8601 dates with `{"$date": "..."}`
3. **Relationships**: Foreign keys properly linked (competitionId, athleteId, etc.)
4. **Realistic Data**: Names, scores, and statuses matching real-world usage

---

## Seeding Process Flow

```
1. Load Configuration
   ├─ Read .env file
   ├─ Connect to MongoDB
   └─ Initialize logger

2. Create Test Users
   ├─ Check if users exist (skip duplicates)
   ├─ Hash passwords (bcrypt cost 12)
   └─ Insert users into database

3. Process JSON Files
   ├─ Read competitions_*.json files
   ├─ Validate JSON structure
   └─ For each competition:
       ├─ Insert competition document
       ├─ Insert categories
       ├─ Insert participants
       ├─ Insert rounds
       ├─ Insert heats
       └─ Insert scores

4. Print Statistics
   └─ Show counts and errors
```

---

## Idempotency

The seeder is **idempotent** - it can be run multiple times safely:

- **Users**: Skips existing users by email
- **Competitions**: Checks for existing `_id` before inserting
- **Related entities**: Only inserts if parent exists

**Re-seeding workflow:**
```bash
# Option 1: Clean and reseed
./seed.sh --clean

# Option 2: Manual cleanup
mongo streetcore --eval "db.competitions.deleteMany({})"
./seed.sh
```

---

## Verification

### Check Seeded Data

**MongoDB Shell:**
```javascript
// Check users
db.users.find({email: /streetcore.com/}).pretty()

// Check competitions
db.competitions.countDocuments()
db.competitions.find().pretty()

// Check participants
db.participants.aggregate([
  {$group: {_id: "$competitionId", count: {$sum: 1}}}
])

// Check scores
db.scores.aggregate([
  {$group: {_id: "$competitionId", count: {$sum: 1}}}
])
```

**API Testing:**
```bash
# Login as admin
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@streetcore.com","password":"Admin123!"}'

# Get competitions
curl -X GET http://localhost:3000/api/v1/competitions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Testing Competition Logic

After seeding, verify that competition features work correctly:

### 1. Registration Flow
```bash
# Register athlete to competition
curl -X POST http://localhost:3000/api/v1/competitions/{id}/register \
  -H "Authorization: Bearer ATHLETE_TOKEN"
```

### 2. Judge Assignment
```bash
# Assign judge to competition (as admin)
curl -X POST http://localhost:3000/api/v1/competitions/{id}/judges \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -d '{"judgeId": "JUDGE_USER_ID"}'
```

### 3. Score Submission
```bash
# Submit score (as judge)
curl -X POST http://localhost:3000/api/v1/competitions/{id}/scores \
  -H "Authorization: Bearer JUDGE_TOKEN" \
  -d '{"athleteId": "...", "totalScore": 85.5}'
```

### 4. Leaderboard
```bash
# Get leaderboard
curl -X GET http://localhost:3000/api/v1/competitions/{id}/leaderboard \
  -H "Authorization: Bearer ANY_TOKEN"
```

---

## Troubleshooting

### "Failed to connect to MongoDB"
- Check if MongoDB is running: `docker ps` or `systemctl status mongod`
- Verify `.env` credentials: `MONGO_URI`, `DB_NAME`
- Check network connectivity to MongoDB host

### "User already exists"
- Expected behavior for idempotency
- Use `--clean` flag to delete and recreate users

### "No competition JSON files found"
- Generate seed data first using Database Agent's seed generator
- Check `seeds/` directory exists and contains `competitions_*.json`

### "Failed to insert competition"
- Check ObjectID format in JSON files
- Verify foreign key references are valid
- Ensure no duplicate `_id` values

### Permission Errors
**Linux/Mac:**
```bash
chmod +x backend/scripts/seed.sh
```

**Windows:**
- Run Command Prompt as Administrator
- Or adjust PowerShell execution policy: `Set-ExecutionPolicy RemoteSigned`

---

## Advanced Usage

### Custom Seed Data

Create your own JSON files:

```bash
# Create custom seed
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

# Seed it
./seed.sh --dir=seeds
```

### Programmatic Seeding

```go
import "backend/cmd/seed"

func setupTestData() {
    seeder := seed.NewSeeder(db, ctx, "../../seeds")
    seeder.SeedAll()
}
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Seed Test Database

on:
  workflow_dispatch:

jobs:
  seed:
    runs-on: ubuntu-latest
    services:
      mongodb:
        image: mongo:7.0
        ports:
          - 27017:27017
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.24'
      - name: Seed database
        working-directory: backend
        run: |
          go run ./cmd/seed --dir=../seeds
```

### Docker Compose Integration

```yaml
services:
  seed:
    build:
      context: .
      dockerfile: Dockerfile.seed
    depends_on:
      - mongodb
    environment:
      MONGO_URI: mongodb://mongodb:27017
      DB_NAME: streetcore
    volumes:
      - ./seeds:/seeds
    command: ["--dir=/seeds"]
```

---

## Best Practices

1. **Always use --dry-run first** to preview changes
2. **Clean data between test runs** for consistent state
3. **Version seed data files** in git for reproducibility
4. **Document test scenarios** that rely on seeded data
5. **Keep passwords simple** for development (but NEVER in production)
6. **Use meaningful names** for test users/competitions
7. **Test end-to-end flows** after seeding

---

## Related Documentation

- `backend/docs/modules/competitions/README.md` - Competition system overview
- `backend/docs/architecture/adr/ADR-005-hexagonal.md` - Architecture patterns
- `backend/cmd/seed/main.go` - Seeder implementation

---

## Support

If you encounter issues:

1. Check this documentation
2. Review error messages in seeder output
3. Verify MongoDB connection and credentials
4. Check logs: `backend/logs/app.log`
5. Contact Backend Agent for assistance

---

**Happy Seeding! 🌱**
