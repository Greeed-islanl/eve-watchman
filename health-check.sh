#!/bin/bash
# Health check script for Eve Watchman deployment

set -e

echo "==================================="
echo "Eve Watchman Deployment Health Check"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
echo -n "Checking Docker installation... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
echo -n "Checking Docker Compose installation... "
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env file exists
echo -n "Checking for .env file... "
if [ -f .env ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "Warning: .env file not found. Run 'make install' or 'cp .env.example .env'"
fi

# Check if services are running
echo ""
echo "Checking service status..."
echo "-----------------------------------"

services=("database" "web" "relay")
all_running=true

for service in "${services[@]}"; do
    echo -n "  $service: "
    if docker compose ps --filter "status=running" | grep -q "$service"; then
        echo -e "${GREEN}running${NC}"
    else
        echo -e "${RED}not running${NC}"
        all_running=false
    fi
done

# Check if containers are healthy
echo ""
echo "Checking container health..."
echo "-----------------------------------"

echo -n "  Database: "
if docker compose ps database | grep -q "healthy"; then
    echo -e "${GREEN}healthy${NC}"
elif docker compose ps database | grep -q "running"; then
    echo -e "${YELLOW}starting...${NC}"
else
    echo -e "${RED}unhealthy${NC}"
fi

# Check web service accessibility
echo ""
echo "Checking web service accessibility..."
echo "-----------------------------------"

WEB_PORT=$(grep "WEB_PORT" .env 2>/dev/null | cut -d'=' -f2 || echo "8080")
echo -n "  HTTP request to localhost:$WEB_PORT... "

if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$WEB_PORT" > /tmp/http_status 2>/dev/null; then
    status_code=$(cat /tmp/http_status)
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 400 ]; then
        echo -e "${GREEN}✓ (HTTP $status_code)${NC}"
    else
        echo -e "${YELLOW}⚠ (HTTP $status_code)${NC}"
    fi
else
    echo -e "${RED}✗ (unreachable)${NC}"
fi

# Check volume status
echo ""
echo "Checking volumes..."
echo "-----------------------------------"
docker volume ls | grep "eve-watchman" | while read -r line; do
    echo "  $line"
done

# Summary
echo ""
echo "==================================="
if $all_running; then
    echo -e "${GREEN}All services are running!${NC}"
    echo ""
    echo "Access the application at: http://localhost:$WEB_PORT"
else
    echo -e "${YELLOW}Some services are not running.${NC}"
    echo ""
    echo "To start services: docker compose up -d"
    echo "To view logs: docker compose logs -f"
fi
echo "==================================="
