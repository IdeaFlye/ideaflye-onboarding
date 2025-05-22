#!/bin/bash

# setup_local_env.sh - Configure IdeaFlye local development environment
# This script fetches configuration from GCP Kubernetes ConfigMaps and Secrets
# to enable local development that connects to production databases.

# Default values for GCP project and cluster
GCP_PROJECT="vm-server-setup-1"
CLUSTER_NAME="" # Will prompt user if not set
CLUSTER_ZONE="" # Will prompt user if not set

# Color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
BASE_DIR="/Users/et/Desktop/IdeaFlye" # Base directory for the project
SERVER_DIR="$BASE_DIR/IdeaFlye/ideaflye-server"
CLIENT_DIR="$BASE_DIR/IdeaFlye/ideaflye-client"
SERVER_ENV_FILE="$SERVER_DIR/.env"
CLIENT_ENV_FILE="$CLIENT_DIR/.env"
GCS_KEY_FILE="$SERVER_DIR/gcs-key.json"

# Names of Kubernetes ConfigMaps and Secrets
SERVER_SECRET="ideaflye-server-secrets"
CLIENT_SECRET="ideaflye-client-secrets"
GCS_KEY_SECRET="gcs-key"

# Architecture detection variables
IS_APPLE_SILICON=false
# Default to ARM for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # More reliable check for Apple Silicon
    if /usr/sbin/sysctl -n machdep.cpu.brand_string | grep -q "Apple"; then
        echo "Detected Apple Silicon Mac"
        IS_APPLE_SILICON=true
    else
        echo "Detected Intel Mac"
        IS_APPLE_SILICON=false
    fi
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for yes/no confirmation
confirm() {
    read -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

echo -e "${BLUE}IdeaFlye Development Environment Setup${NC}"
echo "This script will configure your local environment by fetching"
echo "configuration from your GCP Kubernetes cluster."
echo ""

# Check for required tools
echo -e "${BLUE}Checking for required tools...${NC}"

# Check for gcloud
if ! command_exists gcloud; then
    echo -e "${RED}Error: Google Cloud SDK (gcloud) not found.${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
echo -e "${GREEN}✓ gcloud found${NC}"

# Check for kubectl
if ! command_exists kubectl; then
    echo -e "${YELLOW}kubectl not found. Would you like to install it now?${NC}"
    if confirm "Install kubectl using gcloud components install?"; then
        gcloud components install kubectl
    else
        echo -e "${RED}kubectl is required for this script. Exiting.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ kubectl found${NC}"

# Check for jq
if ! command_exists jq; then
    echo -e "${YELLOW}jq not found. This is required for JSON parsing.${NC}"
    
    # Detection of OS and architecture for automatic installation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - detect architecture and install appropriately
        echo -e "${YELLOW}Detected macOS. Checking architecture...${NC}"
        
        # More robust architecture detection for Apple Silicon 
        # even when running under Rosetta
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            # Check if we're on Apple Silicon running under Rosetta
            if /usr/sbin/sysctl -n machdep.cpu.brand_string | grep -q "Apple"; then
                echo "Detected Apple Silicon running under Rosetta (x86_64 mode)"
                IS_APPLE_SILICON=true
            else
                echo "Detected native Intel architecture: $ARCH"
                IS_APPLE_SILICON=false
            fi
        elif [[ "$ARCH" == "arm64" ]]; then
            echo "Detected native Apple Silicon (ARM64) architecture"
            IS_APPLE_SILICON=true
        else
            echo "Unknown architecture: $ARCH, assuming Intel compatible"
            IS_APPLE_SILICON=false
        fi
        
        if command_exists brew; then
            if [[ "$IS_APPLE_SILICON" == true ]]; then
                echo -e "${YELLOW}Installing jq for Apple Silicon...${NC}"
                
                # Check if Homebrew is in the ARM location
                if [ -x "/opt/homebrew/bin/brew" ]; then
                    echo "Using ARM Homebrew at /opt/homebrew/bin"
                    /usr/bin/arch -arm64 /opt/homebrew/bin/brew install jq
                else
                    echo "Using arch -arm64 flag with Homebrew in PATH"
                    /usr/bin/arch -arm64 brew install jq
                fi
            else
                echo -e "${YELLOW}Installing jq for Intel architecture...${NC}"
                # Ensure we're using Intel homebrew
                if [ -x "/usr/local/bin/brew" ]; then
                    /usr/local/bin/brew install jq
                else
                    echo "Using Homebrew in PATH"
                    brew install jq
                fi
            fi
        else
            echo -e "${YELLOW}Homebrew not found. Installing Homebrew first...${NC}"
            
            if [[ "$IS_APPLE_SILICON" == true ]]; then
                echo "Installing Homebrew for Apple Silicon..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Always use arch -arm64 regardless of installation path
                eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || brew shellenv)"
                /usr/bin/arch -arm64 brew install jq
            else
                echo "Installing Homebrew for Intel architecture..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                eval "$(/usr/local/bin/brew shellenv 2>/dev/null || brew shellenv)"
                brew install jq
            fi
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        # Linux - try apt-get first, then yum
        echo -e "${YELLOW}Detected Linux. Attempting to install jq...${NC}"
        if command_exists apt-get; then
            echo "Using apt-get to install jq..."
            sudo apt-get update && sudo apt-get install -y jq
        elif command_exists yum; then
            echo "Using yum to install jq..."
            sudo yum install -y jq
        elif command_exists dnf; then
            echo "Using dnf to install jq..."
            sudo dnf install -y jq
        else
            echo -e "${RED}Could not find package manager. Please install jq manually.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
        echo "Please install jq manually and run this script again."
        exit 1
    fi
    
    # Verify jq was installed successfully
    if command_exists jq; then
        echo -e "${GREEN}✓ jq installed successfully${NC}"
    else
        echo -e "${RED}Failed to install jq automatically.${NC}"
        echo "Let's try a direct installation method..."
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Download jq binary directly
            echo "Downloading jq binary directly..."
            mkdir -p /tmp/jq-download
            cd /tmp/jq-download
            
            # Determine URL based on architecture
            if [[ "$IS_APPLE_SILICON" == true ]]; then
                curl -L -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64
            else
                curl -L -o jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64
            fi
            
            chmod +x jq
            echo "Installing jq to /usr/local/bin (will prompt for password)..."
            sudo mkdir -p /usr/local/bin
            sudo mv jq /usr/local/bin/
            cd - > /dev/null
            
            if command_exists jq; then
                echo -e "${GREEN}✓ jq installed successfully via direct download${NC}"
            else
                echo -e "${RED}All installation methods failed.${NC}"
                echo "Please install jq manually according to your system requirements."
                echo "You can try: 'brew install jq' or download from https://stedolan.github.io/jq/"
                exit 1
            fi
        else
            echo "Please install jq manually according to your system requirements."
            exit 1
        fi
    fi
fi
echo -e "${GREEN}✓ jq found${NC}"

# Check for Node.js and npm
if ! command_exists node || ! command_exists npm; then
    echo -e "${YELLOW}Node.js and/or npm not found. These are required for the IdeaFlye application.${NC}"
    
    # Architecture was already detected at the start
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ "$IS_APPLE_SILICON" == true ]]; then
            echo -e "${YELLOW}Detected macOS with Apple Silicon architecture${NC}"
        else
            echo -e "${YELLOW}Detected macOS with Intel architecture${NC}"
        fi
    fi
    
    if confirm "Would you like to install Node.js and npm now?"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command_exists brew; then
                echo -e "${YELLOW}Installing Node.js using Homebrew...${NC}"
                
                # Install with appropriate architecture flag
                if [[ "$IS_APPLE_SILICON" == true ]]; then
                    echo "Installing Node.js for Apple Silicon..."
                    
                    # Always use arch -arm64 for safety on Apple Silicon
                    echo "Using arch -arm64 flag with Homebrew"
                    /usr/bin/arch -arm64 brew install node
                else
                    echo "Installing Node.js for Intel architecture..."
                    brew install node
                fi
            else
                echo -e "${YELLOW}Homebrew not found. Installing Homebrew first...${NC}"
                
                if [[ "$IS_APPLE_SILICON" == true ]]; then
                    echo "Installing Homebrew for Apple Silicon..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    # Always use arch -arm64 regardless of installation path
                    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || brew shellenv)"
                    /usr/bin/arch -arm64 brew install node
                else
                    echo "Installing Homebrew for Intel architecture..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    eval "$(/usr/local/bin/brew shellenv 2>/dev/null || brew shellenv)"
                    brew install node
                fi
            fi
        elif [[ "$OSTYPE" == "linux"* ]]; then
            # Linux installation
            echo -e "${YELLOW}Detected Linux. Attempting to install Node.js...${NC}"
            if command_exists apt-get; then
                echo "Using apt-get to install Node.js..."
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                sudo apt-get install -y nodejs
            elif command_exists yum; then
                echo "Using yum to install Node.js..."
                curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
                sudo yum install -y nodejs
            elif command_exists dnf; then
                echo "Using dnf to install Node.js..."
                curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
                sudo dnf install -y nodejs
            else
                echo -e "${RED}Could not find package manager. Please install Node.js manually.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
            echo "Please install Node.js manually and run this script again."
            exit 1
        fi
        
        # Verify Node.js and npm were installed successfully
        if command_exists node && command_exists npm; then
            NODE_VERSION=$(node -v)
            NPM_VERSION=$(npm -v)
            echo -e "${GREEN}✓ Node.js ($NODE_VERSION) and npm ($NPM_VERSION) installed successfully${NC}"
        else
            echo -e "${RED}Failed to install Node.js and npm.${NC}"
            echo "Please install them manually according to your system requirements."
            exit 1
        fi
    else
        echo -e "${RED}Node.js and npm are required for this application. Exiting.${NC}"
        exit 1
    fi
else
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    # Show architecture even when Node.js is already installed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ "$IS_APPLE_SILICON" == true ]]; then
            echo -e "${GREEN}✓ Node.js ($NODE_VERSION) and npm ($NPM_VERSION) found on Apple Silicon Mac${NC}"
        else
            echo -e "${GREEN}✓ Node.js ($NODE_VERSION) and npm ($NPM_VERSION) found on Intel Mac${NC}"
        fi
    else
        echo -e "${GREEN}✓ Node.js ($NODE_VERSION) and npm ($NPM_VERSION) found${NC}"
    fi
fi

# Check gcloud auth
echo -e "${BLUE}Checking Google Cloud authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    echo -e "${YELLOW}Not authenticated with Google Cloud.${NC}"
    if confirm "Would you like to authenticate now?"; then
        gcloud auth login
    else
        echo -e "${RED}Authentication is required. Exiting.${NC}"
        exit 1
    fi
fi
CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
echo -e "${GREEN}✓ Authenticated as: ${CURRENT_ACCOUNT}${NC}"

# Check and set project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [[ "$CURRENT_PROJECT" != "$GCP_PROJECT" ]]; then
    echo -e "${YELLOW}Current project is: $CURRENT_PROJECT${NC}"
    echo -e "${YELLOW}Expected project is: $GCP_PROJECT${NC}"
    if confirm "Switch to project $GCP_PROJECT?"; then
        gcloud config set project $GCP_PROJECT
    else
        if confirm "Continue with project $CURRENT_PROJECT instead?"; then
            GCP_PROJECT=$CURRENT_PROJECT
        else
            echo -e "${RED}Project configuration is required. Exiting.${NC}"
            exit 1
        fi
    fi
fi
echo -e "${GREEN}✓ Using project: $GCP_PROJECT${NC}"

# Check kubectl context
echo -e "${BLUE}Checking Kubernetes cluster configuration...${NC}"
if ! kubectl config current-context &>/dev/null; then
    echo -e "${YELLOW}No active Kubernetes context found.${NC}"
    echo "Let's set up access to your GKE cluster."
    
    # Get available clusters if not specified
    if [[ -z "$CLUSTER_NAME" || -z "$CLUSTER_ZONE" ]]; then
        echo "Fetching available GKE clusters in project $GCP_PROJECT..."
        CLUSTERS=$(gcloud container clusters list --project $GCP_PROJECT --format="csv[no-heading](name,zone)")
        
        if [[ -z "$CLUSTERS" ]]; then
            echo -e "${RED}No GKE clusters found in project $GCP_PROJECT.${NC}"
            echo "Please create a cluster or specify a different project."
            exit 1
        fi
        
        # Display available clusters for selection
        echo -e "${YELLOW}Available clusters:${NC}"
        i=1
        while IFS=',' read -r name zone; do
            echo "$i) $name (zone: $zone)"
            CLUSTER_NAMES[$i]=$name
            CLUSTER_ZONES[$i]=$zone
            ((i++))
        done <<< "$CLUSTERS"
        
        # Prompt for cluster selection
        read -p "Select a cluster (1-$((i-1))): " CLUSTER_IDX
        if [[ $CLUSTER_IDX -ge 1 && $CLUSTER_IDX -lt $i ]]; then
            CLUSTER_NAME=${CLUSTER_NAMES[$CLUSTER_IDX]}
            CLUSTER_ZONE=${CLUSTER_ZONES[$CLUSTER_IDX]}
        else
            echo -e "${RED}Invalid selection. Exiting.${NC}"
            exit 1
        fi
    fi
    
    echo "Setting up kubectl to access cluster $CLUSTER_NAME in zone $CLUSTER_ZONE..."
    gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $GCP_PROJECT
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to configure kubectl. Exiting.${NC}"
        exit 1
    fi
fi

CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null)
echo -e "${GREEN}✓ Using Kubernetes context: $CURRENT_CONTEXT${NC}"

# Confirm before proceeding
echo ""
echo -e "${BLUE}Ready to fetch configuration from Kubernetes${NC}"
echo "This will:"
echo "1. Create/overwrite $SERVER_ENV_FILE"
echo "2. Create/overwrite $CLIENT_ENV_FILE"
echo "3. Create/overwrite $GCS_KEY_FILE"
echo ""
if ! confirm "Do you want to continue?"; then
    echo "Operation cancelled."
    exit 0
fi

# Create server .env file
echo -e "${BLUE}Creating server .env file...${NC}"
echo "# Auto-generated from Kubernetes ConfigMaps and Secrets" > "$SERVER_ENV_FILE"
echo "# Last fetched: $(date)" >> "$SERVER_ENV_FILE"
echo "" >> "$SERVER_ENV_FILE"

# Local development specific values
echo "NODE_ENV=\"development\"" >> "$SERVER_ENV_FILE"
echo "PORT=\"4000\"" >> "$SERVER_ENV_FILE"
echo "CORS_ORIGIN=\"http://localhost:3000\"" >> "$SERVER_ENV_FILE"

# Fetch server secrets
echo "Fetching server secrets ($SERVER_SECRET)..."
if kubectl get secret $SERVER_SECRET &>/dev/null; then
    kubectl get secret $SERVER_SECRET -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key)=\"\(.value | @base64d)\""' >> "$SERVER_ENV_FILE"
    echo -e "${GREEN}✓ Server secrets fetched successfully${NC}"
else
    echo -e "${RED}Error: Secret $SERVER_SECRET not found in Kubernetes.${NC}"
    echo "Server .env file will only contain local development values."
fi

echo -e "${GREEN}✓ Server .env file created at $SERVER_ENV_FILE${NC}"

# Create client .env file
echo -e "${BLUE}Creating client .env file...${NC}"
echo "# Auto-generated from Kubernetes ConfigMaps and Secrets" > "$CLIENT_ENV_FILE"
echo "# Last fetched: $(date)" >> "$CLIENT_ENV_FILE"
echo "" >> "$CLIENT_ENV_FILE"

# Local development specific values
echo "REACT_APP_GRAPHQL_URI=\"http://localhost:4000/graphql\"" >> "$CLIENT_ENV_FILE"
echo "REACT_APP_ALPHA_TESTING=\"false\"" >> "$CLIENT_ENV_FILE"

# Fetch client secrets/configmap
echo "Fetching client configuration ($CLIENT_SECRET)..."
if kubectl get secret $CLIENT_SECRET &>/dev/null; then
    kubectl get secret $CLIENT_SECRET -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key)=\"\(.value | @base64d)\""' >> "$CLIENT_ENV_FILE"
    echo -e "${GREEN}✓ Client secrets fetched successfully${NC}"
elif kubectl get configmap $CLIENT_SECRET &>/dev/null; then
    kubectl get configmap $CLIENT_SECRET -o jsonpath='{.data}' | jq -r 'to_entries[] | "\(.key)=\"\(.value)\""' >> "$CLIENT_ENV_FILE"
    echo -e "${GREEN}✓ Client configmap fetched successfully${NC}"
else
    echo -e "${YELLOW}Warning: Could not find $CLIENT_SECRET as either a Secret or ConfigMap.${NC}"
    echo "Client .env file will only contain local development values."
fi

echo -e "${GREEN}✓ Client .env file created at $CLIENT_ENV_FILE${NC}"

# Fetch and write GCS key
echo -e "${BLUE}Fetching GCS key...${NC}"
if kubectl get secret $GCS_KEY_SECRET &>/dev/null; then
    echo "Found $GCS_KEY_SECRET Secret. Creating gcs-key.json..."
    kubectl get secret $GCS_KEY_SECRET -o jsonpath='{.data.key\.json}' | base64 --decode > "$GCS_KEY_FILE"
    echo -e "${GREEN}✓ GCS key file created at $GCS_KEY_FILE${NC}"
else
    echo -e "${YELLOW}Warning: Could not find $GCS_KEY_SECRET Secret.${NC}"
    
    # Check for local credentials file
    CREDENTIALS_FILE="$BASE_DIR/gcs-credentials.json"
    GCP_CREDENTIALS_FILE="$BASE_DIR/gcp-service-account.json"
    
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo "Found local credentials file at $CREDENTIALS_FILE"
        cp "$CREDENTIALS_FILE" "$GCS_KEY_FILE"
        echo -e "${GREEN}✓ GCS key file copied from local credentials file${NC}"
    elif [ -f "$GCP_CREDENTIALS_FILE" ]; then
        echo "Found local credentials file at $GCP_CREDENTIALS_FILE"
        cp "$GCP_CREDENTIALS_FILE" "$GCS_KEY_FILE"
        echo -e "${GREEN}✓ GCS key file copied from local GCP credentials file${NC}"
    elif [ -f "$SERVER_DIR/gcs-credentials.json" ]; then
        echo "Found credentials file in server directory"
        cp "$SERVER_DIR/gcs-credentials.json" "$GCS_KEY_FILE"
        echo -e "${GREEN}✓ GCS key file copied from server directory${NC}"
    else
        echo -e "${RED}Local credentials file not found${NC}"
        echo -e "${YELLOW}Please obtain the GCP credentials file from your team administrator${NC}"
        echo -e "${YELLOW}and save it as $CREDENTIALS_FILE or $GCP_CREDENTIALS_FILE${NC}"
        echo -e "${YELLOW}Then run this setup script again.${NC}"
        echo -e "${RED}Server will not be able to access Google Cloud Storage without this file.${NC}"
    fi
fi

# Ensure files are properly gitignored
echo -e "${BLUE}Ensuring files are properly gitignored...${NC}"
SERVER_GITIGNORE="$SERVER_DIR/.gitignore"
CLIENT_GITIGNORE="$CLIENT_DIR/.gitignore"

if [ -f "$SERVER_GITIGNORE" ]; then
    if ! grep -q "^\.env$" "$SERVER_GITIGNORE"; then
        echo ".env" >> "$SERVER_GITIGNORE"
        echo -e "${GREEN}✓ Added .env to server .gitignore${NC}"
    fi
    if ! grep -q "^gcs-key.json$" "$SERVER_GITIGNORE"; then
        echo "gcs-key.json" >> "$SERVER_GITIGNORE"
        echo -e "${GREEN}✓ Added gcs-key.json to server .gitignore${NC}"
    fi
fi

if [ -f "$CLIENT_GITIGNORE" ]; then
    if ! grep -q "^\.env$" "$CLIENT_GITIGNORE"; then
        echo ".env" >> "$CLIENT_GITIGNORE"
        echo -e "${GREEN}✓ Added .env to client .gitignore${NC}"
    fi
fi

# Docker Installation and Setup
echo -e "${BLUE}Setting up Docker for server...${NC}"

# Check if Docker is installed
if ! command_exists docker; then
    echo -e "${YELLOW}Docker not found. Docker is recommended for running the server on Apple Silicon Macs.${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}Detected macOS. You can install Docker Desktop from the official website.${NC}"
        echo "Please visit: https://www.docker.com/products/docker-desktop/"
        
        if confirm "Would you like to open the Docker Desktop download page?"; then
            open "https://www.docker.com/products/docker-desktop/"
            echo "Please install Docker Desktop and then run this script again to continue with Docker setup."
            echo "Note: You may need to restart your computer after Docker installation."
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        echo -e "${YELLOW}Detected Linux. Would you like to install Docker?${NC}"
        if confirm "Install Docker using the official convenience script?"; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            echo -e "${GREEN}✓ Docker installed. You may need to log out and back in for group changes to take effect.${NC}"
        fi
    else
        echo -e "${YELLOW}Please install Docker manually for your operating system.${NC}"
    fi
else
    echo -e "${GREEN}✓ Docker found${NC}"
    
    # Check Docker permissions
    if ! docker info &>/dev/null; then
        echo -e "${YELLOW}Unable to connect to Docker daemon. Docker might not be running or you lack permissions.${NC}"
        echo "Please ensure Docker is running and you have the necessary permissions."
        echo "On Linux, you might need to add your user to the docker group: sudo usermod -aG docker \$USER"
        echo "Then log out and back in for the changes to take effect."
    else
        echo -e "${GREEN}✓ Docker daemon is accessible${NC}"
        
        # Build Docker image for the server
        echo -e "${BLUE}Building Docker image for the server...${NC}"
        echo "This may take a few minutes, especially on the first run."
        
        # Navigate to server directory
        cd "$SERVER_DIR"
        
        # Build the Docker image
        if docker build -t ideaflye-server .; then
            echo -e "${GREEN}✓ Docker image built successfully!${NC}"
        else
            echo -e "${RED}Failed to build Docker image. Please check the error messages above.${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}✅ Configuration setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the created .env files to ensure everything looks correct"
echo ""
echo "2. Start the server using one of these methods:"
echo "   Method A: Using the startup script (recommended for Apple Silicon Macs):"
echo "   ./start-server.sh"
echo ""
echo "   Method B: Using Docker manually:"
echo "   cd IdeaFlye/ideaflye-server"
echo "   docker run -p 4000:80 -v \$(pwd)/.env:/usr/src/app/.env -v \$(pwd)/gcs-key.json:/usr/src/app/gcs-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/usr/src/app/gcs-key.json ideaflye-server"
echo ""
echo "   Method C: Using Node.js directly:"
echo "   cd IdeaFlye/ideaflye-server" 
echo "   npm start"
echo ""
echo "3. Start the client using one of these methods:"
echo "   Method A: Using the startup script (recommended):"
echo "   ./start-client.sh"
echo ""
echo "   Method B: Using Node.js directly:"
echo "   cd IdeaFlye/ideaflye-client"
echo "   npm start"
echo ""
echo -e "${BLUE}For the best experience:${NC}"
echo "We recommend running both client and server in Docker, especially on Apple Silicon Macs:"
echo "1. Start the server: ./start-server.sh"
echo "2. Start the client: ./start-client.sh (in a new terminal window)"
echo ""
echo "Access the application at:"
echo "- Frontend UI: http://localhost:3000"
echo "- GraphQL API: http://localhost:4000/graphql"
echo ""
echo "Your local IdeaFlye development environment should now be connected to"
echo "the production databases while running locally." 