#!/bin/bash

# StreetCore Seed Verification Script
# Verifies that seeded data is correct and relationships are valid

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 StreetCore Seed Data Verification${NC}"
echo "====================================="
echo ""

# Check if MongoDB is accessible
if ! command -v mongosh &> /dev/null && ! command -v mongo &> /dev/null; then
    echo -e "${RED}❌ MongoDB shell not found${NC}"
    echo "   Install mongosh: https://www.mongodb.com/try/download/shell"
    exit 1
fi

# Determine which MongoDB shell to use
MONGO_CMD="mongosh"
if ! command -v mongosh &> /dev/null; then
    MONGO_CMD="mongo"
fi

# Load environment variables
if [ -f "../.env" ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
fi

DB_NAME="${DB_NAME:-streetcore}"

echo -e "${BLUE}📊 Checking database: ${DB_NAME}${NC}"
echo ""

# Test users verification
echo -e "${YELLOW}👥 Test Users:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    const users = db.users.find({email: /@streetcore.com$/}).toArray();
    print("   Total test users: " + users.length);

    const adminCount = db.users.countDocuments({role: "admin", email: /@streetcore.com$/});
    print("   Admin accounts: " + adminCount);

    const judgeCount = db.users.countDocuments({email: /^judge.*@streetcore.com$/});
    print("   Judge accounts: " + judgeCount);

    const athleteCount = db.users.countDocuments({email: /^athlete.*@streetcore.com$/});
    print("   Athlete accounts: " + athleteCount);

    users.forEach(u => {
        print("   - " + u.email + " (" + u.role + ") - " + u.firstName + " " + u.lastName);
    });
'
echo ""

# Competitions verification
echo -e "${YELLOW}🏆 Competitions:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    const compCount = db.competitions.countDocuments();
    print("   Total competitions: " + compCount);

    const byStatus = db.competitions.aggregate([
        {$group: {_id: "$status", count: {$sum: 1}}}
    ]).toArray();

    byStatus.forEach(s => {
        print("   - " + s._id + ": " + s.count);
    });

    const competitions = db.competitions.find({}, {title: 1, status: 1, "registration.currentParticipants": 1}).toArray();
    competitions.forEach(c => {
        print("   • " + c.title + " (" + c.status + ") - " + c.registration.currentParticipants + " participants");
    });
'
echo ""

# Categories verification
echo -e "${YELLOW}📋 Categories:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    const catCount = db.categories.countDocuments();
    print("   Total categories: " + catCount);

    const byCompetition = db.categories.aggregate([
        {
            $lookup: {
                from: "competitions",
                localField: "competitionId",
                foreignField: "_id",
                as: "competition"
            }
        },
        {
            $project: {
                competitionTitle: {$arrayElemAt: ["$competition.title", 0]},
                name: 1,
                currentParticipants: 1
            }
        }
    ]).toArray();

    byCompetition.forEach(c => {
        print("   • " + c.competitionTitle + " - " + c.name + " (" + c.currentParticipants + " participants)");
    });
'
echo ""

# Participants verification
echo -e "${YELLOW}👤 Participants:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    const partCount = db.participants.countDocuments();
    print("   Total participants: " + partCount);

    const byStatus = db.participants.aggregate([
        {$group: {_id: "$status", count: {$sum: 1}}}
    ]).toArray();

    byStatus.forEach(s => {
        print("   - " + s._id + ": " + s.count);
    });

    const byCompetition = db.participants.aggregate([
        {
            $group: {
                _id: "$competitionId",
                count: {$sum: 1}
            }
        },
        {
            $lookup: {
                from: "competitions",
                localField: "_id",
                foreignField: "_id",
                as: "competition"
            }
        },
        {
            $project: {
                title: {$arrayElemAt: ["$competition.title", 0]},
                count: 1
            }
        }
    ]).toArray();

    byCompetition.forEach(c => {
        print("   • " + c.title + ": " + c.count + " participants");
    });
'
echo ""

# Rounds verification
echo -e "${YELLOW}🔄 Rounds:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    const roundCount = db.rounds.countDocuments();
    print("   Total rounds: " + roundCount);

    const byStatus = db.rounds.aggregate([
        {$group: {_id: "$status", count: {$sum: 1}}}
    ]).toArray();

    byStatus.forEach(s => {
        print("   - " + s._id + ": " + s.count);
    });
'
echo ""

# Heats verification
echo -e "${YELLOW}🔥 Heats:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    const heatCount = db.heats.countDocuments();
    print("   Total heats: " + heatCount);

    if (heatCount > 0) {
        const byStatus = db.heats.aggregate([
            {$group: {_id: "$status", count: {$sum: 1}}}
        ]).toArray();

        byStatus.forEach(s => {
            print("   - " + s._id + ": " + s.count);
        });
    }
'
echo ""

# Scores verification
echo -e "${YELLOW}🎯 Scores:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    const scoreCount = db.scores.countDocuments();
    print("   Total scores: " + scoreCount);

    if (scoreCount > 0) {
        const avgScore = db.scores.aggregate([
            {$group: {_id: null, avg: {$avg: "$totalScore"}}}
        ]).toArray();

        if (avgScore.length > 0) {
            print("   Average score: " + avgScore[0].avg.toFixed(2));
        }

        const byCompetition = db.scores.aggregate([
            {
                $group: {
                    _id: "$competitionId",
                    count: {$sum: 1},
                    avgScore: {$avg: "$totalScore"}
                }
            },
            {
                $lookup: {
                    from: "competitions",
                    localField: "_id",
                    foreignField: "_id",
                    as: "competition"
                }
            },
            {
                $project: {
                    title: {$arrayElemAt: ["$competition.title", 0]},
                    count: 1,
                    avgScore: 1
                }
            }
        ]).toArray();

        byCompetition.forEach(c => {
            print("   • " + c.title + ": " + c.count + " scores (avg: " + c.avgScore.toFixed(2) + ")");
        });
    }
'
echo ""

# Data integrity checks
echo -e "${YELLOW}🔐 Data Integrity:${NC}"
$MONGO_CMD $DB_NAME --quiet --eval '
    // Check for orphaned participants
    const orphanedParticipants = db.participants.aggregate([
        {
            $lookup: {
                from: "competitions",
                localField: "competitionId",
                foreignField: "_id",
                as: "competition"
            }
        },
        {
            $match: {
                competition: {$size: 0}
            }
        }
    ]).toArray().length;

    if (orphanedParticipants > 0) {
        print("   ⚠️  Orphaned participants: " + orphanedParticipants);
    } else {
        print("   ✅ No orphaned participants");
    }

    // Check for orphaned scores
    const orphanedScores = db.scores.aggregate([
        {
            $lookup: {
                from: "competitions",
                localField: "competitionId",
                foreignField: "_id",
                as: "competition"
            }
        },
        {
            $match: {
                competition: {$size: 0}
            }
        }
    ]).toArray().length;

    if (orphanedScores > 0) {
        print("   ⚠️  Orphaned scores: " + orphanedScores);
    } else {
        print("   ✅ No orphaned scores");
    }

    // Check for competitions without participants
    const emptyCompetitions = db.competitions.aggregate([
        {
            $lookup: {
                from: "participants",
                localField: "_id",
                foreignField: "competitionId",
                as: "participants"
            }
        },
        {
            $match: {
                participants: {$size: 0}
            }
        }
    ]).toArray().length;

    if (emptyCompetitions > 0) {
        print("   ℹ️  Competitions without participants: " + emptyCompetitions);
    } else {
        print("   ✅ All competitions have participants");
    }
'
echo ""

echo -e "${GREEN}✅ Verification complete!${NC}"
