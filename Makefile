# ========================================
# STREETCORE BETA - Makefile
# ========================================
# Comandos rápidos para gestión del entorno
# ========================================

.PHONY: help start stop restart reset logs build clean status health backup

# Default target
.DEFAULT_GOAL := help

# Colors for output
COLOR_RESET = \033[0m
COLOR_BOLD = \033[1m
COLOR_GREEN = \033[32m
COLOR_YELLOW = \033[33m
COLOR_BLUE = \033[34m

# ========================================
# HELP
# ========================================
help: ## Show this help message
	@echo "$(COLOR_BOLD)StreetCore BETA - Available Commands$(COLOR_RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_GREEN)%-15s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ""

# ========================================
# MAIN COMMANDS
# ========================================
start: ## Start all services
	@echo "$(COLOR_BLUE)Starting BETA environment...$(COLOR_RESET)"
	@./start-beta.sh || powershell -File start-beta.ps1

stop: ## Stop all services
	@echo "$(COLOR_YELLOW)Stopping services...$(COLOR_RESET)"
	@./stop-beta.sh || powershell -File stop-beta.ps1

restart: stop start ## Restart all services

reset: ## Reset environment (deletes all data!)
	@echo "$(COLOR_YELLOW)Resetting environment...$(COLOR_RESET)"
	@./reset-beta.sh || powershell -File reset-beta.ps1

# ========================================
# BUILD & DEPLOY
# ========================================
build: ## Build all containers
	@echo "$(COLOR_BLUE)Building containers...$(COLOR_RESET)"
	@docker-compose build

build-no-cache: ## Build all containers without cache
	@echo "$(COLOR_BLUE)Building containers (no cache)...$(COLOR_RESET)"
	@docker-compose build --no-cache

build-backend: ## Build only backend
	@echo "$(COLOR_BLUE)Building backend...$(COLOR_RESET)"
	@docker-compose build backend

build-frontend: ## Build only frontend
	@echo "$(COLOR_BLUE)Building frontend...$(COLOR_RESET)"
	@docker-compose build frontend

# ========================================
# MONITORING
# ========================================
logs: ## Show logs from all services
	@docker-compose logs -f

logs-backend: ## Show backend logs
	@docker-compose logs -f backend

logs-frontend: ## Show frontend logs
	@docker-compose logs -f frontend

logs-mongodb: ## Show MongoDB logs
	@docker-compose logs -f mongodb

status: ## Show status of all services
	@docker-compose ps

health: ## Check health of all services
	@echo "$(COLOR_BLUE)Checking service health...$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_BOLD)Backend:$(COLOR_RESET)"
	@curl -s http://localhost:3000/health | jq . || echo "❌ Backend not responding"
	@echo ""
	@echo "$(COLOR_BOLD)Frontend:$(COLOR_RESET)"
	@curl -s http://localhost:80/health || echo "❌ Frontend not responding"
	@echo ""
	@echo "$(COLOR_BOLD)MongoDB:$(COLOR_RESET)"
	@docker exec streetcore-mongodb-beta mongosh --quiet --eval "db.adminCommand('ping')" || echo "❌ MongoDB not responding"

# ========================================
# MAINTENANCE
# ========================================
clean: ## Remove stopped containers and dangling images
	@echo "$(COLOR_YELLOW)Cleaning up...$(COLOR_RESET)"
	@docker-compose down
	@docker system prune -f

clean-all: ## Remove all containers, volumes, and images
	@echo "$(COLOR_YELLOW)WARNING: This will remove ALL data!$(COLOR_RESET)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ]
	@docker-compose down -v
	@docker system prune -af

# ========================================
# BACKUPS
# ========================================
backup-mongodb: ## Backup MongoDB database
	@echo "$(COLOR_BLUE)Creating MongoDB backup...$(COLOR_RESET)"
	@mkdir -p backups/mongodb
	@docker exec streetcore-mongodb-beta mongodump \
		--username=admin \
		--password=admin123 \
		--authenticationDatabase=admin \
		--db=streetcore \
		--out=/backups/backup-$(shell date +%Y%m%d-%H%M%S)
	@echo "$(COLOR_GREEN)✅ Backup created in backups/mongodb/$(COLOR_RESET)"

backup-uploads: ## Backup uploaded files
	@echo "$(COLOR_BLUE)Creating uploads backup...$(COLOR_RESET)"
	@mkdir -p backups/uploads
	@docker cp streetcore-backend-beta:/app/uploads ./backups/uploads-$(shell date +%Y%m%d-%H%M%S)
	@echo "$(COLOR_GREEN)✅ Backup created in backups/uploads/$(COLOR_RESET)"

backup: backup-mongodb backup-uploads ## Full backup (MongoDB + uploads)

# ========================================
# SHELL ACCESS
# ========================================
shell-backend: ## Access backend container shell
	@docker exec -it streetcore-backend-beta sh

shell-frontend: ## Access frontend container shell
	@docker exec -it streetcore-frontend-beta sh

shell-mongodb: ## Access MongoDB shell
	@docker exec -it streetcore-mongodb-beta mongosh -u admin -p admin123 --authenticationDatabase admin

# ========================================
# DEVELOPMENT
# ========================================
dev: ## Start in development mode with live reload
	@echo "$(COLOR_BLUE)Starting development environment...$(COLOR_RESET)"
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# ========================================
# UTILITIES
# ========================================
stats: ## Show container resource usage
	@docker stats

volumes: ## List all volumes
	@docker volume ls | grep streetcore

ports: ## Show exposed ports
	@echo "$(COLOR_BOLD)Exposed Ports:$(COLOR_RESET)"
	@echo "  Frontend:  http://localhost:80"
	@echo "  Backend:   http://localhost:3000"
	@echo "  MongoDB:   mongodb://localhost:27017"

update: ## Pull latest images and rebuild
	@echo "$(COLOR_BLUE)Updating containers...$(COLOR_RESET)"
	@docker-compose pull
	@docker-compose build --pull
	@echo "$(COLOR_GREEN)✅ Containers updated$(COLOR_RESET)"
