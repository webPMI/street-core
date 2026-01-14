# Street Core Backend - Makefile
# ================================

.PHONY: all build run test test-unit test-integration test-coverage lint clean help

# Variables
BINARY_NAME=street-core
MAIN_PATH=./main.go
BUILD_DIR=./bin
COVERAGE_DIR=./coverage

# Go commands
GOCMD=go
GOBUILD=$(GOCMD) build
GORUN=$(GOCMD) run
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOFMT=gofmt
GOLINT=golangci-lint

# Build flags
LDFLAGS=-ldflags "-s -w"

# Default target
all: lint test build

# ============================================================================
# BUILD TARGETS
# ============================================================================

## build: Build the application
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

## run: Run the application
run:
	@echo "Starting server..."
	$(GORUN) $(MAIN_PATH)

## run-dev: Run in development mode with hot reload (requires air)
run-dev:
	@echo "Starting server with hot reload..."
	air

# ============================================================================
# TEST TARGETS
# ============================================================================

## test: Run all tests
test:
	@echo "Running all tests..."
	$(GOTEST) -v ./...

## test-unit: Run unit tests only (excludes integration tests)
test-unit:
	@echo "Running unit tests..."
	$(GOTEST) -v -short ./...

## test-integration: Run integration tests only
test-integration:
	@echo "Running integration tests..."
	$(GOTEST) -v -run Integration ./tests/integration/...

## test-coverage: Run tests with coverage report
test-coverage:
	@echo "Running tests with coverage..."
	@mkdir -p $(COVERAGE_DIR)
	$(GOTEST) -v -coverprofile=$(COVERAGE_DIR)/coverage.out ./...
	$(GOCMD) tool cover -html=$(COVERAGE_DIR)/coverage.out -o $(COVERAGE_DIR)/coverage.html
	@echo "Coverage report: $(COVERAGE_DIR)/coverage.html"

## test-coverage-func: Show function-level coverage
test-coverage-func:
	@echo "Function coverage report:"
	$(GOTEST) -coverprofile=$(COVERAGE_DIR)/coverage.out ./...
	$(GOCMD) tool cover -func=$(COVERAGE_DIR)/coverage.out

## test-bench: Run benchmark tests
test-bench:
	@echo "Running benchmarks..."
	$(GOTEST) -bench=. -benchmem ./...

## test-race: Run tests with race detector
test-race:
	@echo "Running tests with race detector..."
	$(GOTEST) -race -v ./...

## test-specific: Run specific test (usage: make test-specific TEST=TestName)
test-specific:
	@echo "Running test: $(TEST)"
	$(GOTEST) -v -run $(TEST) ./...

# ============================================================================
# CODE QUALITY TARGETS
# ============================================================================

## lint: Run linters
lint:
	@echo "Running linters..."
	@if command -v $(GOLINT) > /dev/null; then \
		$(GOLINT) run ./...; \
	else \
		echo "golangci-lint not installed. Running go vet instead..."; \
		$(GOCMD) vet ./...; \
	fi

## fmt: Format code
fmt:
	@echo "Formatting code..."
	$(GOFMT) -s -w .

## fmt-check: Check if code is formatted
fmt-check:
	@echo "Checking code formatting..."
	@test -z "$$($(GOFMT) -l .)" || (echo "Code is not formatted. Run 'make fmt'" && exit 1)

## vet: Run go vet
vet:
	@echo "Running go vet..."
	$(GOCMD) vet ./...

# ============================================================================
# DEPENDENCY TARGETS
# ============================================================================

## deps: Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download

## deps-tidy: Tidy dependencies
deps-tidy:
	@echo "Tidying dependencies..."
	$(GOMOD) tidy

## deps-verify: Verify dependencies
deps-verify:
	@echo "Verifying dependencies..."
	$(GOMOD) verify

## deps-update: Update all dependencies
deps-update:
	@echo "Updating dependencies..."
	$(GOGET) -u ./...
	$(GOMOD) tidy

# ============================================================================
# DOCKER TARGETS
# ============================================================================

## docker-build: Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker build -t $(BINARY_NAME):latest .

## docker-run: Run Docker container
docker-run:
	@echo "Running Docker container..."
	docker run -p 3000:3000 --env-file .env $(BINARY_NAME):latest

## docker-compose-up: Start services with docker-compose
docker-compose-up:
	docker-compose up -d

## docker-compose-down: Stop services with docker-compose
docker-compose-down:
	docker-compose down

# ============================================================================
# UTILITY TARGETS
# ============================================================================

## clean: Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(COVERAGE_DIR)
	@rm -f coverage.out
	@echo "Clean complete"

## generate: Run go generate
generate:
	@echo "Running go generate..."
	$(GOCMD) generate ./...

## docs: Generate API documentation (requires swag)
docs:
	@echo "Generating API documentation..."
	@if command -v swag > /dev/null; then \
		swag init -g main.go -o ./docs; \
	else \
		echo "swag not installed. Run: go install github.com/swaggo/swag/cmd/swag@latest"; \
	fi

## help: Show this help
help:
	@echo "Street Core Backend - Available Commands"
	@echo "========================================="
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'

# ============================================================================
# CI/CD TARGETS
# ============================================================================

## ci: Run CI pipeline (lint, test, build)
ci: deps-tidy fmt-check vet lint test build
	@echo "CI pipeline complete"

## pre-commit: Run pre-commit checks
pre-commit: fmt vet lint test-unit
	@echo "Pre-commit checks complete"
