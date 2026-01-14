# Database Seeding - Quick Start Guide

**5-Minute Setup for Development**

---

## Prerequisites

- ✅ MongoDB running (Docker or local)
- ✅ `.env` file configured
- ✅ Go 1.24+ installed

---

## Step 1: Seed the Database

### Linux/Mac
```bash
cd backend/scripts
./seed.sh
```

### Windows
```cmd
cd backend\scripts
seed.bat
```

**Expected output**:
```
🌱 StreetCore Database Seeding
====================================

✅ Archivo .env cargado correctamente
🔨 Building seeder...
✅ Build successful

🚀 Running seeder...

👥 Creating test users...
   ✅ Created user: admin@streetcore.com (admin)
   ✅ Created user: judge1@streetcore.com (user)
   ✅ Created user: judge2@streetcore.com (user)
   ✅ Created user: judge3@streetcore.com (user)
   ✅ Created user: athlete1@streetcore.com (user)
   ✅ Created user: athlete2@streetcore.com (user)
   ✅ Created user: athlete3@streetcore.com (user)
   ✅ Created user: athlete4@streetcore.com (user)
   ✅ Created user: athlete5@streetcore.com (user)

🏆 Seeding competitions from JSON files...
   📄 Processing: competitions_sample.json
      🏆 Seeding competition: Madrid Street Battle 2026
         ✅ Competition seeded successfully

📊 Seeding Statistics
=====================
⏱️  Duration: 1.23s
👥 Users created: 9
🏆 Competitions seeded: 1
📋 Categories seeded: 2
👤 Participants seeded: 5
🔄 Rounds seeded: 1
🔥 Heats seeded: 0
🎯 Scores seeded: 0

✅ Seeding completed successfully!
```

---

## Step 2: Verify Data

```bash
cd backend/scripts
./verify-seed.sh
```

**Expected output**:
```
🔍 StreetCore Seed Data Verification
=====================================

📊 Checking database: streetcore

👥 Test Users:
   Total test users: 9
   Admin accounts: 1
   Judge accounts: 3
   Athlete accounts: 5
   - admin@streetcore.com (admin) - Admin System
   - judge1@streetcore.com (user) - Carlos Mendez
   - judge2@streetcore.com (user) - Maria Rodriguez
   ...

🏆 Competitions:
   Total competitions: 1
   - upcoming: 1
   • Madrid Street Battle 2026 (upcoming) - 5 participants

✅ Verification complete!
```

---

## Step 3: Test Authentication

### Login as Admin

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@streetcore.com",
    "password": "Admin123!"
  }'
```

**Expected response**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "email": "admin@streetcore.com",
      "firstName": "Admin",
      "lastName": "System",
      "role": "admin"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "..."
  }
}
```

### Login as Judge

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "judge1@streetcore.com",
    "password": "Judge123!"
  }'
```

### Login as Athlete

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "athlete1@streetcore.com",
    "password": "Athlete123!"
  }'
```

---

## Step 4: Test Competition API

### Get Competitions

```bash
# Save admin token
TOKEN="your_admin_token_here"

# Get all competitions
curl -X GET http://localhost:3000/api/v1/competitions \
  -H "Authorization: Bearer $TOKEN"
```

**Expected response**:
```json
{
  "success": true,
  "data": {
    "competitions": [
      {
        "id": "...",
        "title": "Madrid Street Battle 2026",
        "status": "upcoming",
        "registration": {
          "currentParticipants": 5,
          "maxParticipants": 50
        }
      }
    ],
    "pagination": {...}
  }
}
```

### Get Specific Competition

```bash
COMP_ID="60a7b3c4e5f6a7b8c9d0e1f1"

curl -X GET http://localhost:3000/api/v1/competitions/$COMP_ID \
  -H "Authorization: Bearer $TOKEN"
```

---

## Test User Credentials

Copy-paste ready credentials:

### Admin
```
Email: admin@streetcore.com
Password: Admin123!
```

### Judges
```
Email: judge1@streetcore.com
Password: Judge123!

Email: judge2@streetcore.com
Password: Judge123!

Email: judge3@streetcore.com
Password: Judge123!
```

### Athletes
```
Email: athlete1@streetcore.com
Password: Athlete123!

Email: athlete2@streetcore.com
Password: Athlete123!

Email: athlete3@streetcore.com
Password: Athlete123!

Email: athlete4@streetcore.com
Password: Athlete123!

Email: athlete5@streetcore.com
Password: Athlete123!
```

---

## Common Commands

### Reseed Database

```bash
# Clean and reseed
./scripts/seed.sh --clean
```

### Preview Changes (Dry Run)

```bash
# See what would be inserted
./scripts/seed.sh --dry-run
```

### Check MongoDB Directly

```bash
# Connect to MongoDB
mongosh streetcore

# Count users
db.users.countDocuments({email: /@streetcore.com$/})

# List competitions
db.competitions.find({}, {title: 1, status: 1}).pretty()

# Check participants
db.participants.countDocuments()
```

---

## Troubleshooting

### "MongoDB connection failed"
```bash
# Check if MongoDB is running
docker ps | grep mongo

# Or for local installation
systemctl status mongod
```

### "User already exists"
✅ This is normal - seeder is idempotent. Use `--clean` to reset.

### "No JSON files found"
✅ Using sample data - seeder still creates test users.

### "Permission denied"
```bash
# Make scripts executable
chmod +x backend/scripts/*.sh
```

---

## Next Steps

1. ✅ **Seed complete** - You now have test users and sample data
2. ✅ **Start backend** - `cd backend && go run main.go`
3. ✅ **Test API** - Use curl or Postman with test credentials
4. ✅ **Start frontend** - `cd street_core && flutter run`
5. ✅ **Develop features** - Use test accounts for authentication

---

## Full Documentation

- **Complete Guide**: `backend/docs/guides/DATABASE_SEEDING.md`
- **Technical Docs**: `backend/cmd/seed/README.md`
- **Seed Format**: `seeds/README.md`

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Seed database | `./scripts/seed.sh` |
| Clean & reseed | `./scripts/seed.sh --clean` |
| Preview changes | `./scripts/seed.sh --dry-run` |
| Verify data | `./scripts/verify-seed.sh` |
| Login admin | `curl POST /api/v1/auth/login {"email":"admin@streetcore.com","password":"Admin123!"}` |
| Get competitions | `curl GET /api/v1/competitions -H "Authorization: Bearer $TOKEN"` |
| Check MongoDB | `mongosh streetcore` |

---

**You're all set! Happy coding! 🚀**
