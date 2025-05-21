#!/bin/bash

# Color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVER_DIR="/Users/et/Desktop/IdeaFlye/IdeaFlye/ideaflye-server"

echo -e "${BLUE}IdeaFlye Server Starter${NC}"
echo "This script will start the IdeaFlye server using Docker."

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

# Navigate to server directory
cd "$SERVER_DIR" || {
    echo -e "${RED}Error: Cannot find server directory at $SERVER_DIR${NC}"
    echo "Please make sure you've cloned the repositories correctly."
    exit 1
}

# Check if .env and gcs-key.json exist
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found in server directory.${NC}"
    echo "Please run setup_local_env.sh first to create the necessary configuration files."
    exit 1
fi

if [ ! -f "gcs-key.json" ]; then
    echo -e "${RED}Error: gcs-key.json file not found in server directory.${NC}"
    echo "Please run setup_local_env.sh first to create the necessary configuration files."
    exit 1
fi

# Check if Docker image exists, build if it doesn't
if ! docker images | grep -q "ideaflye-server"; then
    echo -e "${YELLOW}Docker image not found. Building ideaflye-server image...${NC}"
    if ! docker build -t ideaflye-server .; then
        echo -e "${RED}Failed to build Docker image. Please check the error messages above.${NC}"
        exit 1
    fi
fi

# Check if port 4000 is already in use
if lsof -Pi :4000 -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}Port 4000 is already in use. Stopping any running Docker containers...${NC}"
    docker stop $(docker ps -q --filter ancestor=ideaflye-server) 2>/dev/null || true
    
    # Double-check if port is still in use after stopping Docker containers
    if lsof -Pi :4000 -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${YELLOW}Port 4000 is still in use. Would you like to use a different port? [y/N]${NC}"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo -e "Please enter the port number to use:"
            read -r port
            SERVER_PORT=$port
        else
            echo -e "${RED}Cannot start server because port 4000 is in use. Please stop the service using this port and try again.${NC}"
            exit 1
        fi
    else
        SERVER_PORT=4000
    fi
else
    SERVER_PORT=4000
fi

# Run the server in Docker
echo -e "${GREEN}Starting IdeaFlye server on port $SERVER_PORT using Docker...${NC}"
docker run -p $SERVER_PORT:80 \
    -v "$(pwd)/.env:/usr/src/app/.env" \
    -v "$(pwd)/gcs-key.json:/usr/src/app/gcs-key.json" \
    -e GOOGLE_APPLICATION_CREDENTIALS=/usr/src/app/gcs-key.json \
    ideaflye-server

# This part will only execute if the Docker container stops
echo -e "${YELLOW}Server stopped.${NC}" 