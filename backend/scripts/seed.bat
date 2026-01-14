@echo off
REM StreetCore Database Seeding Script (Windows)
REM This script seeds the MongoDB database with test data for development

setlocal enabledelayedexpansion

echo.
echo ======================================
echo   StreetCore Database Seeding
echo ======================================
echo.

REM Get script directory
set SCRIPT_DIR=%~dp0
set BACKEND_DIR=%SCRIPT_DIR%..
set PROJECT_ROOT=%BACKEND_DIR%\..
set SEED_DIR=%PROJECT_ROOT%\seeds

REM Check if .env file exists
if not exist "%PROJECT_ROOT%\.env" (
    echo [91m ERROR: .env file not found in project root[0m
    echo    Please create .env file with MongoDB credentials
    exit /b 1
)

REM Parse command-line arguments
set DRY_RUN=
set CLEAN=
set SHOW_HELP=

:parse_args
if "%~1"=="" goto end_parse
if /i "%~1"=="--dry-run" (
    set DRY_RUN=--dry-run
    echo [93m Dry run mode enabled[0m
    shift
    goto parse_args
)
if /i "%~1"=="--clean" (
    set CLEAN=--clean
    echo [93m Clean mode enabled ^(will delete existing data^)[0m
    shift
    goto parse_args
)
if /i "%~1"=="--dir" (
    set SEED_DIR=%~2
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--help" (
    set SHOW_HELP=1
    goto show_help
)
echo [91mUnknown option: %~1[0m
echo Use --help for usage information
exit /b 1

:show_help
echo Usage: seed.bat [OPTIONS]
echo.
echo Options:
echo   --dry-run    Perform dry run without inserting data
echo   --clean      Delete existing competition data before seeding
echo   --dir PATH   Specify custom seed data directory ^(default: ..\seeds^)
echo   --help       Show this help message
echo.
exit /b 0

:end_parse

REM Check if seed directory exists
if not exist "%SEED_DIR%" (
    echo [93m WARNING: Seed directory not found: %SEED_DIR%[0m
    echo    The seeding tool will still create test users
    echo.
)

REM Navigate to backend directory
cd /d "%BACKEND_DIR%"

REM Build the seeder
echo [94m Building seeder...[0m
if not exist "bin" mkdir bin
go build -o bin\seed.exe .\cmd\seed
if errorlevel 1 (
    echo [91m Build failed[0m
    exit /b 1
)

echo [92m Build successful[0m
echo.

REM Run the seeder
echo [94m Running seeder...[0m
echo.

bin\seed.exe --dir="%SEED_DIR%" %DRY_RUN% %CLEAN%

REM Check exit code
if errorlevel 1 (
    echo.
    echo [91m Seeding failed[0m
    exit /b 1
)

echo.
echo [92m Seeding completed successfully![0m
echo.
echo [94m Test User Credentials:[0m
echo    Admin:
echo      Email: admin@streetcore.com
echo      Password: Admin123!
echo.
echo    Judges:
echo      judge1@streetcore.com / Judge123!
echo      judge2@streetcore.com / Judge123!
echo      judge3@streetcore.com / Judge123!
echo.
echo    Athletes:
echo      athlete1@streetcore.com / Athlete123!
echo      athlete2@streetcore.com / Athlete123!
echo      athlete3@streetcore.com / Athlete123!
echo      athlete4@streetcore.com / Athlete123!
echo      athlete5@streetcore.com / Athlete123!
echo.

endlocal
