#!/bin/bash
# ========================================
# STREETCORE BETA - Environment Validator
# ========================================
# Valida configuración antes del despliegue
# ========================================

set -e

COLOR_RESET='\033[0m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_RED='\033[31m'
COLOR_BLUE='\033[34m'

ERRORS=0
WARNINGS=0

echo -e "${COLOR_BLUE}=========================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}  StreetCore BETA - Environment Validation${COLOR_RESET}"
echo -e "${COLOR_BLUE}=========================================${COLOR_RESET}"
echo ""

# ========================================
# 1. CHECK ENVIRONMENT FILE
# ========================================
echo -e "${COLOR_YELLOW}[1/6] Checking environment file...${COLOR_RESET}"

if [ ! -f ".env.beta" ]; then
    echo -e "${COLOR_RED}  ❌ .env.beta file not found${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${COLOR_GREEN}  ✅ .env.beta exists${COLOR_RESET}"

    # Load environment variables
    source .env.beta

    # Check critical variables
    REQUIRED_VARS=(
        "ENV"
        "JWT_SECRET"
        "OAUTH_ENCRYPTION_KEY"
        "MONGO_ROOT_USER"
        "MONGO_ROOT_PASSWORD"
        "DB_NAME"
    )

    for VAR in "${REQUIRED_VARS[@]}"; do
        VALUE="${!VAR}"
        if [ -z "$VALUE" ]; then
            echo -e "${COLOR_RED}  ❌ $VAR is not set${COLOR_RESET}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${COLOR_GREEN}  ✅ $VAR is set${COLOR_RESET}"
        fi
    done
fi

echo ""

# ========================================
# 2. VALIDATE JWT_SECRET
# ========================================
echo -e "${COLOR_YELLOW}[2/6] Validating JWT_SECRET...${COLOR_RESET}"

if [ -z "$JWT_SECRET" ]; then
    echo -e "${COLOR_RED}  ❌ JWT_SECRET is not set${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
elif [ ${#JWT_SECRET} -lt 32 ]; then
    echo -e "${COLOR_RED}  ❌ JWT_SECRET is too short (minimum 32 characters)${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
elif [[ "$JWT_SECRET" == *"INVALID"* ]]; then
    echo -e "${COLOR_RED}  ❌ JWT_SECRET contains INVALID placeholder${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${COLOR_GREEN}  ✅ JWT_SECRET is valid (${#JWT_SECRET} characters)${COLOR_RESET}"
fi

echo ""

# ========================================
# 3. VALIDATE OAUTH_ENCRYPTION_KEY
# ========================================
echo -e "${COLOR_YELLOW}[3/6] Validating OAUTH_ENCRYPTION_KEY...${COLOR_RESET}"

if [ -z "$OAUTH_ENCRYPTION_KEY" ]; then
    echo -e "${COLOR_RED}  ❌ OAUTH_ENCRYPTION_KEY is not set${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
elif [ ${#OAUTH_ENCRYPTION_KEY} -lt 32 ]; then
    echo -e "${COLOR_RED}  ❌ OAUTH_ENCRYPTION_KEY is too short (minimum 32 characters)${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${COLOR_GREEN}  ✅ OAUTH_ENCRYPTION_KEY is valid (${#OAUTH_ENCRYPTION_KEY} characters)${COLOR_RESET}"
fi

echo ""

# ========================================
# 4. CHECK ADMIN PASSWORD
# ========================================
echo -e "${COLOR_YELLOW}[4/6] Checking admin password...${COLOR_RESET}"

if [ -z "$ADMIN_PASSWORD" ]; then
    echo -e "${COLOR_RED}  ❌ ADMIN_PASSWORD is not set${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
elif [ "$ADMIN_PASSWORD" == "Aa-1234!" ]; then
    echo -e "${COLOR_YELLOW}  ⚠️  Using default admin password (change in production!)${COLOR_RESET}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${COLOR_GREEN}  ✅ Custom admin password set${COLOR_RESET}"
fi

echo ""

# ========================================
# 5. CHECK DOCKER
# ========================================
echo -e "${COLOR_YELLOW}[5/6] Checking Docker...${COLOR_RESET}"

if ! command -v docker &> /dev/null; then
    echo -e "${COLOR_RED}  ❌ Docker is not installed${COLOR_RESET}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${COLOR_GREEN}  ✅ Docker is installed${COLOR_RESET}"

    # Check Docker daemon
    if ! docker info &> /dev/null; then
        echo -e "${COLOR_RED}  ❌ Docker daemon is not running${COLOR_RESET}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${COLOR_GREEN}  ✅ Docker daemon is running${COLOR_RESET}"
    fi
fi

echo ""

# ========================================
# 6. CHECK PORTS
# ========================================
echo -e "${COLOR_YELLOW}[6/6] Checking ports...${COLOR_RESET}"

PORTS=(80 3000 27017)
PORT_NAMES=("Frontend" "Backend" "MongoDB")

for i in "${!PORTS[@]}"; do
    PORT="${PORTS[$i]}"
    NAME="${PORT_NAMES[$i]}"

    if lsof -Pi :$PORT -sTCP:LISTEN -t &> /dev/null; then
        echo -e "${COLOR_YELLOW}  ⚠️  Port $PORT ($NAME) is already in use${COLOR_RESET}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${COLOR_GREEN}  ✅ Port $PORT ($NAME) is available${COLOR_RESET}"
    fi
done

echo ""

# ========================================
# SUMMARY
# ========================================
echo -e "${COLOR_BLUE}=========================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}  Validation Summary${COLOR_RESET}"
echo -e "${COLOR_BLUE}=========================================${COLOR_RESET}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${COLOR_GREEN}✅ All checks passed! Environment is ready.${COLOR_RESET}"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${COLOR_YELLOW}⚠️  Validation completed with $WARNINGS warning(s)${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}   You can proceed, but review the warnings above.${COLOR_RESET}"
    echo ""
    exit 0
else
    echo -e "${COLOR_RED}❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${COLOR_RESET}"
    echo -e "${COLOR_RED}   Fix the errors above before deploying.${COLOR_RESET}"
    echo ""
    exit 1
fi
