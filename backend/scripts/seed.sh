#!/bin/bash

# StreetCore Database Seeding Script
# This script seeds the MongoDB database with test data for development

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BACKEND_DIR")"

echo -e "${BLUE}🌱 StreetCore Database Seeding${NC}"
echo "=================================="
echo ""

# Check if .env file exists
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${RED}❌ Error: .env file not found in project root${NC}"
    echo "   Please create .env file with MongoDB credentials"
    exit 1
fi

# Parse command-line arguments
DRY_RUN=""
CLEAN=""
SEED_DIR="$PROJECT_ROOT/seeds"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN="--dry-run"
            echo -e "${YELLOW}🔍 Dry run mode enabled${NC}"
            shift
            ;;
        --clean)
            CLEAN="--clean"
            echo -e "${YELLOW}🧹 Clean mode enabled (will delete existing data)${NC}"
            shift
            ;;
        --dir)
            SEED_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: ./seed.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Perform dry run without inserting data"
            echo "  --clean      Delete existing competition data before seeding"
            echo "  --dir PATH   Specify custom seed data directory (default: ../seeds)"
            echo "  --help       Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if seed directory exists
if [ ! -d "$SEED_DIR" ]; then
    echo -e "${YELLOW}⚠️  Warning: Seed directory not found: $SEED_DIR${NC}"
    echo "   The seeding tool will still create test users"
    echo ""
fi

# Navigate to backend directory
cd "$BACKEND_DIR"

# Build and run the seeder
echo -e "${BLUE}🔨 Building seeder...${NC}"
if ! go build -o bin/seed ./cmd/seed; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"
echo ""

# Run the seeder
echo -e "${BLUE}🚀 Running seeder...${NC}"
echo ""

./bin/seed --dir="$SEED_DIR" $DRY_RUN $CLEAN

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Seeding completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📝 Test User Credentials:${NC}"
    echo "   Admin:"
    echo "     Email: admin@streetcore.com"
    echo "     Password: Admin123!"
    echo ""
    echo "   Judges:"
    echo "     judge1@streetcore.com / Judge123!"
    echo "     judge2@streetcore.com / Judge123!"
    echo "     judge3@streetcore.com / Judge123!"
    echo ""
    echo "   Athletes:"
    echo "     athlete1@streetcore.com / Athlete123!"
    echo "     athlete2@streetcore.com / Athlete123!"
    echo "     athlete3@streetcore.com / Athlete123!"
    echo "     athlete4@streetcore.com / Athlete123!"
    echo "     athlete5@streetcore.com / Athlete123!"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Seeding failed${NC}"
    exit 1
fi
