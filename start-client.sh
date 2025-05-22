#!/bin/bash

# Color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLIENT_DIR="/Users/et/Desktop/IdeaFlye/ideaflye-client"

echo -e "${BLUE}IdeaFlye Client Starter${NC}"
echo "This script will start the IdeaFlye client using Docker."

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker not found.${NC}"
    echo "Please install Docker first. Run setup_local_env.sh for assistance."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker daemon not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if container with the name 'ideaflye-client' already exists
if docker ps -a --format '{{.Names}}' | grep -q "^ideaflye-client$"; then
    # Check if it's running
    if docker ps --format '{{.Names}}' | grep -q "^ideaflye-client$"; then
        echo -e "${YELLOW}A container named 'ideaflye-client' is already running.${NC}"
        echo -e "Would you like to stop it and start a new one? [y/N]"
    else
        echo -e "${YELLOW}A container named 'ideaflye-client' exists but is not running.${NC}"
        echo -e "Would you like to remove it and start a new one? [y/N]"
    fi
    
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${YELLOW}Stopping and removing existing container...${NC}"
        docker stop ideaflye-client 2>/dev/null || true
        docker rm ideaflye-client 2>/dev/null || true
    else
        echo -e "${YELLOW}Keeping existing container. Exiting script.${NC}"
        exit 0
    fi
fi

# Navigate to client directory
cd "$CLIENT_DIR" || {
    echo -e "${RED}Error: Cannot find client directory at $CLIENT_DIR${NC}"
    echo "Please make sure you've cloned the repositories correctly."
    exit 1
}

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found in client directory.${NC}"
    echo "Please run setup_local_env.sh first to create the necessary configuration files."
    exit 1
fi

# Use the existing Dockerfile.dev
if [ ! -f "Dockerfile.dev" ]; then
    echo -e "${RED}Error: Dockerfile.dev not found in client directory.${NC}"
    echo "Please create it or run setup_local_env.sh again."
    exit 1
fi

echo -e "${GREEN}✓ Using existing Dockerfile.dev${NC}"

# Check if port 3000 is already in use
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}Port 3000 is already in use. Stopping any running Docker containers...${NC}"
    docker stop $(docker ps -q --filter name=ideaflye-client) 2>/dev/null || true
    
    # Double-check if port is still in use after stopping Docker containers
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${YELLOW}Port 3000 is still in use. Would you like to use a different port? [y/N]${NC}"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo -e "Please enter the port number to use:"
            read -r port
            CLIENT_PORT=$port
        else
            echo -e "${RED}Cannot start client because port 3000 is in use. Please stop the service using this port and try again.${NC}"
            exit 1
        fi
    else
        CLIENT_PORT=3000
    fi
else
    CLIENT_PORT=3000
fi

# Check if Docker image exists, build if it doesn't or if we need to rebuild
echo -e "${YELLOW}Building ideaflye-client image with development settings...${NC}"
if ! docker build -t ideaflye-client -f Dockerfile.dev .; then
    echo -e "${RED}Failed to build Docker image. Please check the error messages above.${NC}"
    exit 1
fi

# Run the client in Docker
echo -e "${GREEN}Starting IdeaFlye client on port $CLIENT_PORT using Docker...${NC}"
echo -e "${YELLOW}Note: The client may take a minute to start and be available in your browser.${NC}"

# Extract environment variables from .env file
ENV_VARS=$(grep -v '^#' .env | xargs -I{} echo "--env {}")

# Add custom environment variables to force development mode
ENV_CUSTOM="--env NODE_ENV=development --env REACT_APP_NODE_ENV=development"

# Run with source code mounted for live reload
# NOTE: We don't mount node_modules to avoid conflicts
docker run -p $CLIENT_PORT:3000 \
    --name ideaflye-client \
    $ENV_VARS \
    $ENV_CUSTOM \
    -v "$(pwd)/.env:/usr/src/app/.env" \
    -v "$(pwd)/src:/usr/src/app/src" \
    -v "$(pwd)/public:/usr/src/app/public" \
    -e CHOKIDAR_USEPOLLING=true \
    -e WDS_SOCKET_PORT=$CLIENT_PORT \
    ideaflye-client

# This part will only execute if the Docker container stops
echo -e "${YELLOW}Client stopped.${NC}" 