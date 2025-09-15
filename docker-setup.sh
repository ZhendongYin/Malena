#!/bin/bash

# Docker setup script for AI Chat application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 AI Chat Docker Setup${NC}"
echo "================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Generate secret key if not set
if [ -z "$SECRET_KEY_BASE" ]; then
    echo -e "${YELLOW}⚠️  SECRET_KEY_BASE not set. Generating one...${NC}"
    export SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')
    echo -e "${GREEN}✅ Generated SECRET_KEY_BASE${NC}"
fi

# Build the application
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
docker-compose build

# Start services
echo -e "${YELLOW}🚀 Starting services...${NC}"
docker-compose up -d db redis

# Wait for database and redis to be ready
echo -e "${YELLOW}⏳ Waiting for database and redis to be ready...${NC}"
sleep 15

# Run database migrations
echo -e "${YELLOW}📊 Running database migrations...${NC}"
docker-compose run --rm app ./bin/ai_chat eval "Application.ensure_all_started(:ai_chat); Ecto.Migrator.run(AiChat.Repo, :up, all: true)"

# Start the application
echo -e "${YELLOW}🎯 Starting application...${NC}"
docker-compose up -d app

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${GREEN}🌐 Application is running at: http://localhost:4000${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  docker-compose logs -f app     # View application logs"
echo "  docker-compose logs -f db      # View database logs"
echo "  docker-compose logs -f redis   # View redis logs"
echo "  docker-compose down            # Stop all services"
echo "  docker-compose restart app     # Restart application"
echo ""
echo -e "${YELLOW}Environment variables:${NC}"
echo "  SECRET_KEY_BASE=$SECRET_KEY_BASE"
