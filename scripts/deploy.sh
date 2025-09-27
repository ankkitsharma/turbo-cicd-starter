#!/bin/bash

# Deployment script for VPS
# This script should be run on your VPS server

set -e

# Configuration
PROJECT_DIR="/opt/turbo-ci-starter"
REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO.git"  # Update this with your actual repo
BRANCH="main"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
fi

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_DIR" ]; then
    log "Creating project directory: $PROJECT_DIR"
    sudo mkdir -p "$PROJECT_DIR"
    sudo chown $USER:$USER "$PROJECT_DIR"
fi

# Navigate to project directory
cd "$PROJECT_DIR"

# Clone repository if it doesn't exist
if [ ! -d ".git" ]; then
    log "Cloning repository..."
    git clone "$REPO_URL" .
else
    log "Pulling latest changes..."
    git pull origin "$BRANCH"
fi

# Check if docker-compose.yml exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    error "docker-compose.yml not found in $PROJECT_DIR"
fi

# Login to GitHub Container Registry (if needed)
log "Logging in to GitHub Container Registry..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin

# Pull latest images
log "Pulling latest Docker images..."
docker-compose pull

# Stop existing containers
log "Stopping existing containers..."
docker-compose down

# Start services
log "Starting services..."
docker-compose up -d

# Wait for services to be ready
log "Waiting for services to be ready..."
sleep 10

# Check if services are running
log "Checking service status..."
docker-compose ps

# Clean up unused images
log "Cleaning up unused Docker images..."
docker image prune -f

log "Deployment completed successfully!"

# Show running services
log "Running services:"
docker-compose ps