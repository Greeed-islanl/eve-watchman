# Makefile for Eve Watchman Deployment

.PHONY: help build up down logs restart clean install update

# Default target
help:
	@echo "Eve Watchman Deployment Commands:"
	@echo ""
	@echo "  make install    - First-time setup (copies .env.example to .env)"
	@echo "  make build      - Build Docker images"
	@echo "  make up         - Start all services"
	@echo "  make down       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - View logs from all services"
	@echo "  make logs-web   - View web application logs"
	@echo "  make logs-relay - View relay service logs"
	@echo "  make logs-db    - View database logs"
	@echo "  make update     - Pull latest changes and rebuild"
	@echo "  make clean      - Remove all containers, networks, and volumes"
	@echo "  make status     - Show status of all services"
	@echo ""

# First-time installation
install:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✓ Created .env file from .env.example"; \
		echo "⚠ Please edit .env and configure your Eve Online application settings"; \
	else \
		echo "✗ .env file already exists, skipping..."; \
	fi

# Build Docker images
build:
	docker compose build

# Start all services
up:
	docker compose up -d
	@echo "✓ Services started. Access the web application at http://localhost:8080"

# Stop all services
down:
	docker compose down

# Restart all services
restart:
	docker compose restart

# View logs
logs:
	docker compose logs -f

logs-web:
	docker compose logs -f web

logs-relay:
	docker compose logs -f relay

logs-db:
	docker compose logs -f database

# Update and rebuild
update:
	git pull
	docker compose down
	docker compose build --no-cache
	docker compose up -d
	@echo "✓ Application updated and restarted"

# Clean up everything
clean:
	@echo "⚠ This will remove all containers, networks, and volumes (including database data)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✓ All services and data removed"; \
	else \
		echo "✗ Cancelled"; \
	fi

# Show service status
status:
	docker compose ps
