# ========================================
# STREETCORE BETA - Environment Validator (Windows)
# ========================================
# Valida configuración antes del despliegue
# ========================================

$ErrorActionPreference = "Stop"

$ERRORS = 0
$WARNINGS = 0

Write-Host "=========================================" -ForegroundColor Blue
Write-Host "  StreetCore BETA - Environment Validation" -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue
Write-Host ""

# ========================================
# 1. CHECK ENVIRONMENT FILE
# ========================================
Write-Host "[1/6] Checking environment file..." -ForegroundColor Yellow

if (-not (Test-Path ".env.beta")) {
    Write-Host "  ❌ .env.beta file not found" -ForegroundColor Red
    $ERRORS++
} else {
    Write-Host "  ✅ .env.beta exists" -ForegroundColor Green

    # Load environment variables
    $envVars = @{}
    Get-Content ".env.beta" | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.+)$") {
            $envVars[$matches[1].Trim()] = $matches[2].Trim()
        }
    }

    # Check critical variables
    $requiredVars = @(
        "ENV",
        "JWT_SECRET",
        "OAUTH_ENCRYPTION_KEY",
        "MONGO_ROOT_USER",
        "MONGO_ROOT_PASSWORD",
        "DB_NAME"
    )

    foreach ($var in $requiredVars) {
        if (-not $envVars.ContainsKey($var) -or [string]::IsNullOrWhiteSpace($envVars[$var])) {
            Write-Host "  ❌ $var is not set" -ForegroundColor Red
            $ERRORS++
        } else {
            Write-Host "  ✅ $var is set" -ForegroundColor Green
        }
    }
}

Write-Host ""

# ========================================
# 2. VALIDATE JWT_SECRET
# ========================================
Write-Host "[2/6] Validating JWT_SECRET..." -ForegroundColor Yellow

if (-not $envVars.ContainsKey("JWT_SECRET") -or [string]::IsNullOrWhiteSpace($envVars["JWT_SECRET"])) {
    Write-Host "  ❌ JWT_SECRET is not set" -ForegroundColor Red
    $ERRORS++
} elseif ($envVars["JWT_SECRET"].Length -lt 32) {
    Write-Host "  ❌ JWT_SECRET is too short (minimum 32 characters)" -ForegroundColor Red
    $ERRORS++
} elseif ($envVars["JWT_SECRET"] -like "*INVALID*") {
    Write-Host "  ❌ JWT_SECRET contains INVALID placeholder" -ForegroundColor Red
    $ERRORS++
} else {
    Write-Host "  ✅ JWT_SECRET is valid ($($envVars['JWT_SECRET'].Length) characters)" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 3. VALIDATE OAUTH_ENCRYPTION_KEY
# ========================================
Write-Host "[3/6] Validating OAUTH_ENCRYPTION_KEY..." -ForegroundColor Yellow

if (-not $envVars.ContainsKey("OAUTH_ENCRYPTION_KEY") -or [string]::IsNullOrWhiteSpace($envVars["OAUTH_ENCRYPTION_KEY"])) {
    Write-Host "  ❌ OAUTH_ENCRYPTION_KEY is not set" -ForegroundColor Red
    $ERRORS++
} elseif ($envVars["OAUTH_ENCRYPTION_KEY"].Length -lt 32) {
    Write-Host "  ❌ OAUTH_ENCRYPTION_KEY is too short (minimum 32 characters)" -ForegroundColor Red
    $ERRORS++
} else {
    Write-Host "  ✅ OAUTH_ENCRYPTION_KEY is valid ($($envVars['OAUTH_ENCRYPTION_KEY'].Length) characters)" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 4. CHECK ADMIN PASSWORD
# ========================================
Write-Host "[4/6] Checking admin password..." -ForegroundColor Yellow

if (-not $envVars.ContainsKey("ADMIN_PASSWORD") -or [string]::IsNullOrWhiteSpace($envVars["ADMIN_PASSWORD"])) {
    Write-Host "  ❌ ADMIN_PASSWORD is not set" -ForegroundColor Red
    $ERRORS++
} elseif ($envVars["ADMIN_PASSWORD"] -eq "Aa-1234!") {
    Write-Host "  ⚠️  Using default admin password (change in production!)" -ForegroundColor Yellow
    $WARNINGS++
} else {
    Write-Host "  ✅ Custom admin password set" -ForegroundColor Green
}

Write-Host ""

# ========================================
# 5. CHECK DOCKER
# ========================================
Write-Host "[5/6] Checking Docker..." -ForegroundColor Yellow

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "  ❌ Docker is not installed" -ForegroundColor Red
    $ERRORS++
} else {
    Write-Host "  ✅ Docker is installed" -ForegroundColor Green

    # Check Docker daemon
    try {
        docker info | Out-Null
        Write-Host "  ✅ Docker daemon is running" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Docker daemon is not running" -ForegroundColor Red
        $ERRORS++
    }
}

Write-Host ""

# ========================================
# 6. CHECK PORTS
# ========================================
Write-Host "[6/6] Checking ports..." -ForegroundColor Yellow

$ports = @{
    80 = "Frontend"
    3000 = "Backend"
    27017 = "MongoDB"
}

foreach ($port in $ports.Keys) {
    $name = $ports[$port]
    $connection = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue

    if ($connection) {
        Write-Host "  ⚠️  Port $port ($name) is already in use" -ForegroundColor Yellow
        $WARNINGS++
    } else {
        Write-Host "  ✅ Port $port ($name) is available" -ForegroundColor Green
    }
}

Write-Host ""

# ========================================
# SUMMARY
# ========================================
Write-Host "=========================================" -ForegroundColor Blue
Write-Host "  Validation Summary" -ForegroundColor Blue
Write-Host "=========================================" -ForegroundColor Blue
Write-Host ""

if ($ERRORS -eq 0 -and $WARNINGS -eq 0) {
    Write-Host "✅ All checks passed! Environment is ready." -ForegroundColor Green
    Write-Host ""
    exit 0
} elseif ($ERRORS -eq 0) {
    Write-Host "⚠️  Validation completed with $WARNINGS warning(s)" -ForegroundColor Yellow
    Write-Host "   You can proceed, but review the warnings above." -ForegroundColor Yellow
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)" -ForegroundColor Red
    Write-Host "   Fix the errors above before deploying." -ForegroundColor Red
    Write-Host ""
    exit 1
}
