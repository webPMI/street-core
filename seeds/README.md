# Seed Data Directory

**Purpose**: Contains JSON seed data files for populating MongoDB with test data

---

## Overview

This directory stores JSON files that define test competitions, categories, participants, and scores for development and testing. The seeding tool (`backend/cmd/seed`) reads these files and inserts data into MongoDB.

---

## File Naming Convention

```
competitions_*.json
```

**Examples**:
- `competitions_sample.json` - Sample data (provided)
- `competitions_bmx.json` - BMX competitions
- `competitions_skate.json` - Skating competitions
- `competitions_scooter.json` - Scooter competitions

---

## JSON Structure

Each file must contain the following structure:

```json
{
  "competitions": [
    {
      "_id": {"$oid": "60a7b3c4e5f6a7b8c9d0e1f1"},
      "title": "Competition Name",
      "description": "...",
      "organizerId": {"$oid": "..."},
      "competitionType": "individual",
      "format": "single_round",
      "discipline": "discipline_name",
      "schedule": {
        "startDate": {"$date": "2026-03-15T09:00:00Z"},
        "endDate": {"$date": "2026-03-15T19:00:00Z"},
        "venue": "Venue Name",
        "city": "City",
        "country": "Country"
      },
      "registration": {...},
      "scoringCriteria": {...},
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

---

## Required Fields

### Competition
- `_id` - ObjectID in format `{"$oid": "hex_string"}`
- `title` - Competition name
- `description` - Detailed description
- `organizerId` - Reference to user _id
- `competitionType` - "individual", "team", or "both"
- `format` - "single_round", "multi_round", "elimination", etc.
- `discipline` - Discipline name (e.g., "street_skating")
- `schedule` - Start/end dates, venue info
- `registration` - Participant limits and status
- `scoringCriteria` - Scoring rules and criteria
- `status` - "upcoming", "live", "completed", "cancelled", "postponed"

### Category
- `_id` - ObjectID
- `competitionId` - Reference to competition _id
- `name` - Category name
- `maxParticipants` - Maximum participants
- `status` - "active", "inactive", "closed"

### Participant
- `_id` - ObjectID
- `competitionId` - Reference to competition _id
- `athleteId` - Reference to user _id
- `athleteName` - Athlete display name
- `status` - "pending", "approved", "rejected"

### Round
- `_id` - ObjectID
- `competitionId` - Reference to competition _id
- `name` - Round name (e.g., "Finals", "Semifinals")
- `order` - Round number
- `status` - "pending", "active", "completed"

### Heat
- `_id` - ObjectID
- `competitionId` - Reference to competition _id
- `roundId` - Reference to round _id
- `name` - Heat name
- `mode` - "sequential" or "simultaneous"
- `status` - "pending", "active", "completed"

### Score
- `_id` - ObjectID
- `competitionId` - Reference to competition _id
- `athleteId` - Reference to user _id
- `judgeId` - Reference to judge user _id
- `totalScore` - Numeric score
- `submittedAt` - Submission timestamp

---

## Data Types

### ObjectID Format
```json
{"$oid": "60a7b3c4e5f6a7b8c9d0e1f1"}
```
- Must be valid 24-character hex string
- Use online generator: https://observablehq.com/@hugodf/mongodb-objectid-generator

### Date Format
```json
{"$date": "2026-03-15T10:00:00Z"}
```
- Must be ISO 8601 format
- Use UTC timezone (Z suffix)
- Example: `2026-01-15T09:00:00Z`

---

## Creating Seed Data

### Option 1: Manual Creation

1. Copy `competitions_sample.json`
2. Generate new ObjectIDs for all entities
3. Update relationships (foreign keys)
4. Validate JSON syntax

### Option 2: Use Database Agent Generator

The Database Agent can generate realistic seed data:

```bash
# Generate seed data (placeholder - tool not implemented yet)
go run ./cmd/seedgen --output=seeds/ --count=10
```

### Option 3: Export from Existing Database

```bash
# Export competitions
mongoexport --db=streetcore --collection=competitions --out=seeds/export.json

# Transform to seed format (manual edit required)
```

---

## Validation

### JSON Syntax
```bash
# Validate JSON syntax
cat competitions_sample.json | jq . > /dev/null && echo "Valid JSON"
```

### ObjectID Format
- 24 hex characters: `[0-9a-f]{24}`
- Example: `60a7b3c4e5f6a7b8c9d0e1f1`

### Date Format
- ISO 8601: `YYYY-MM-DDTHH:MM:SSZ`
- Example: `2026-03-15T10:00:00Z`

---

## Usage

### Seed Database

```bash
# From project root
cd backend/scripts
./seed.sh

# Or from backend directory
cd backend
go run ./cmd/seed --dir=../seeds
```

### Dry Run (Preview)

```bash
./scripts/seed.sh --dry-run
```

### Clean and Reseed

```bash
./scripts/seed.sh --clean
```

---

## File Organization

```
seeds/
├── README.md                    # This file
├── competitions_sample.json     # Example seed data (provided)
├── competitions_bmx.json        # BMX-specific data (create as needed)
├── competitions_skate.json      # Skating data (create as needed)
└── competitions_scooter.json    # Scooter data (create as needed)
```

---

## Best Practices

1. **Use meaningful IDs**: Generate unique ObjectIDs for each entity
2. **Maintain relationships**: Ensure foreign keys reference existing documents
3. **Realistic data**: Use real names, locations, and scores
4. **Consistent dates**: Use future dates for "upcoming" competitions
5. **Valid status values**: Use only allowed status constants
6. **Complete scoring criteria**: Define all criteria with weights
7. **Version control**: Commit seed files to git for reproducibility

---

## Common Issues

### "Invalid ObjectID format"
- Check that ObjectIDs are 24 hex characters
- Ensure format: `{"$oid": "..."}`

### "Invalid date format"
- Use ISO 8601: `2026-01-15T10:00:00Z`
- Ensure format: `{"$date": "..."}`

### "Orphaned relationships"
- Verify foreign keys reference existing documents
- Check `competitionId`, `athleteId`, `judgeId` values

### "Duplicate key error"
- Ensure all `_id` values are unique
- Generate new ObjectIDs if copying data

---

## Example Workflow

### 1. Create New Competition

```bash
# Copy sample file
cp competitions_sample.json competitions_custom.json

# Edit file with new data
# - Generate new ObjectIDs for all entities
# - Update competition details
# - Add participants
# - Configure scoring criteria
```

### 2. Validate

```bash
# Check JSON syntax
cat competitions_custom.json | jq . > /dev/null

# Check with seeder (dry run)
cd ../backend
go run ./cmd/seed --dir=../seeds --dry-run
```

### 3. Seed Database

```bash
# Run seeder
./scripts/seed.sh

# Verify data
./scripts/verify-seed.sh
```

---

## ObjectID Generation

### Online Tools
- https://observablehq.com/@hugodf/mongodb-objectid-generator
- https://www.uuidtools.com/generate/mongodb-objectid

### Node.js
```javascript
const { ObjectId } = require('mongodb');
console.log(new ObjectId().toString());
```

### Python
```python
from bson import ObjectId
print(str(ObjectId()))
```

### Go
```go
import "go.mongodb.org/mongo-driver/bson/primitive"
fmt.Println(primitive.NewObjectID().Hex())
```

---

## Related Documentation

- `backend/docs/guides/DATABASE_SEEDING.md` - Complete seeding guide
- `backend/cmd/seed/README.md` - Seeder technical documentation
- `backend/docs/guides/SEEDING_SUMMARY.md` - Implementation summary

---

## Support

For questions:
1. Check `backend/docs/guides/DATABASE_SEEDING.md`
2. Review `competitions_sample.json` for format reference
3. Run seeder in dry-run mode: `./scripts/seed.sh --dry-run`
4. Contact Backend Agent

---

**Happy Seeding! 🌱**
