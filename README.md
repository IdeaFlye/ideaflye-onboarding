# IdeaFlye Developer Onboarding Guide

Welcome to the IdeaFlye development team! This guide will walk you through setting up your development environment and getting started with our codebase.

## Getting Started

1. Clone this repository:
   ```bash
   git clone git@github.com:IdeaFlye/ideaflye-onboarding.git
   cd ideaflye-onboarding
   ```

## Prerequisites

Before you begin, ensure you have the following installed on your system:
- Git
- A code editor (we recommend Visual Studio Code or Cursor)
- Node.js (if required for the project - specific version will be listed in each repository)
- Any other project-specific requirements (will be listed in individual repository READMEs)

## Initial Setup Steps

### 1. Git Configuration
First, ensure Git is installed and configured on your system:
```bash
# Check Git version
git --version

# Configure your Git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. GitHub Access Setup
You have two options for GitHub authentication:

#### Option A: SSH Setup (Recommended)
1. Install GitHub CLI:
   ```bash
   # For Apple Silicon (M1/M2) Macs:
   arch -arm64 brew install gh
   # For Intel Macs:
   brew install gh
   ```

2. Run GitHub CLI authentication:
   ```bash
   gh auth login
   ```
   Follow the prompts:
   - Select "GitHub.com" when asked where you use GitHub
   - Choose "SSH" as your preferred protocol
   - Select "Yes" to generate a new SSH key
   - Enter a passphrase (recommended for security)
   - Provide a descriptive title for your SSH key (e.g., "ideaflye-ssh")
   - Choose "Login with a web browser" for authentication
   - Copy the one-time code shown and complete authentication in your browser

The GitHub CLI will automatically:
- Configure git protocol settings
- Upload your SSH key to GitHub
- Complete your authentication

#### Option B: HTTPS with GitHub CLI
1. Install GitHub CLI
2. Run `gh auth login` and follow the prompts

### 3. Repository Access
1. You'll need to be added to the IdeaFlye GitHub organization
2. Contact your team lead to get the necessary permissions
3. Accept the organization invitation from your email

### 4. Clone Repositories
Once you have access, you can clone all repositories using our setup script:
```bash
# From the root directory of this repository
./onboarding/setup.sh
```

During the first clone operation, you will be prompted to:
1. Verify GitHub's host authenticity - Type 'yes' when asked about GitHub.com's fingerprint
2. Enter your SSH key passphrase (if you set one during setup)
   - Note: You'll need to enter the passphrase for each repository being cloned

#### Using SSH-Agent (Recommended)
To avoid entering your SSH passphrase repeatedly, you can use ssh-agent:

1. Start the SSH agent:
   ```bash
   # Start ssh-agent in the background
   eval "$(ssh-agent -s)"
   ```

2. Add your SSH key:
   ```bash
   # Add your SSH key to ssh-agent
   ssh-add ~/.ssh/id_ed25519
   ```
   - Enter your passphrase once when prompted
   - Your key will remain available until you log out or restart

3. To make this permanent (macOS), add to your `~/.zshrc` or `~/.bash_profile`:
   ```bash
   # Start ssh-agent if not already running
   if [ -z "$SSH_AUTH_SOCK" ]; then
       eval "$(ssh-agent -s)"
       ssh-add ~/.ssh/id_ed25519
   fi
   ```

After setting up ssh-agent, you won't need to enter your passphrase for subsequent Git operations.

The script will clone the following repositories:
- ideaflye-server: Backend server
- ideaflye-client: Frontend client application
- ideaflye-neo4j: Database configuration and scripts
- ideaflye-ai: AI/ML components

## Local Development Environment Setup

This section guides you through setting up the IdeaFlye client and server applications to run locally on your machine for development. When running locally, the client and server will still connect to the production databases (Neo4j and PostgreSQL) hosted in the cloud.

### 1. Install Node.js and npm (via nvm)

We recommend using Node Version Manager (`nvm`) to install and manage Node.js versions.

a.  **Install nvm:**
    Open your terminal and run:
    ```bash
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    ```
    After the script finishes, close and reopen your terminal, or run the commands suggested by the nvm installer to load nvm into your current session (usually `source ~/.zshrc`, `source ~/.bashrc`, or similar depending on your shell).

b.  **Install Node.js (LTS version):**
    Once nvm is installed and loaded, install the latest Long-Term Support (LTS) version of Node.js:
    ```bash
    nvm install --lts
    ```

c.  **Set the LTS version as default:**
    To ensure this version is used automatically in new terminal sessions:
    ```bash
    nvm use --lts
    nvm alias default lts 
    ```
    Verify the installation by opening a new terminal and typing:
    ```bash
    node -v
    npm -v
    ```
    You should see version numbers outputted for both. If you encounter `command not found`, ensure nvm's initialization script is correctly added to your shell's startup file (e.g., `~/.zshrc`, `~/.bash_profile`). The nvm installation usually handles this, but you may need to ensure lines like `export NVM_DIR="$HOME/.nvm"` and `[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"` are present and sourced.

### 2. Configure Local Development Environment

To set up your local development environment with the correct configuration (secrets, database connections, etc.), we provide a script that fetches configuration from the GCP Kubernetes cluster:

a. **Run the setup script:**
   ```bash
   # From the onboarding directory
   ./setup_local_env.sh
   ```

   This script will:
   - Check for required tools (gcloud, kubectl, jq)
   - Guide you through authentication with Google Cloud if needed
   - Help you select the correct GKE cluster
   - Fetch the configuration from Kubernetes ConfigMaps and Secrets
   - Create local `.env` files for both client and server
   - Create the `gcs-key.json` file needed for Google Cloud Storage access

b. **Prerequisites for the script:**
   - Google Cloud SDK (gcloud) installed
   - kubectl command-line tool
   - jq command-line JSON processor
   - Access to the IdeaFlye GCP project
   
   Don't worry if you don't have all these tools - the script will help you install missing dependencies.

### 3. Install Project Dependencies

For both the `ideaflye-client` and `ideaflye-server`, you'll need to install their specific Node.js package dependencies.

a.  **For the Client (`ideaflye-client`):**
    Navigate to the client directory and install dependencies:
    ```bash
    cd IdeaFlye/ideaflye-client 
    npm install --legacy-peer-deps
    ```

b.  **For the Server (`ideaflye-server`):**
    Navigate to the server directory and install dependencies:
    ```bash
    cd IdeaFlye/ideaflye-server
    npm install --legacy-peer-deps
    ```
    *Note: The `--legacy-peer-deps` flag is used to resolve potential peer dependency conflicts that might arise with the project's current package versions.*

### 4. Docker Setup for Apple Silicon Macs (Recommended)

If you're using a Mac with Apple Silicon (M1, M2, etc.), we recommend running the server in Docker to avoid compatibility issues with native Node.js modules like TensorFlow and bcrypt.

a.  **Install Docker Desktop:**
    Download and install Docker Desktop from [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

b.  **Build the Docker image:**
    This is done automatically by the `setup_local_env.sh` script. If you need to manually build it:
    ```bash
    cd IdeaFlye/ideaflye-server
    docker build -t ideaflye-server .
    ```

c.  **Run the server in Docker:**
    ```bash
    cd IdeaFlye/ideaflye-server
    docker run -p 4000:80 -v $(pwd)/.env:/usr/src/app/.env -v $(pwd)/gcs-key.json:/usr/src/app/gcs-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/usr/src/app/gcs-key.json ideaflye-server
    ```

    This command:
    - Maps port 4000 on your host to port 80 in the container
    - Mounts your local `.env` file into the container
    - Mounts your local `gcs-key.json` file into the container
    - Sets the GOOGLE_APPLICATION_CREDENTIALS environment variable
    - Uses the `ideaflye-server` image created earlier

    The server will be accessible at `http://localhost:4000/graphql`

### 5. Running the Applications Locally

Once dependencies are installed, you can start the development servers.

a.  **To start the Client (`ideaflye-client`):**

    **Option 1: Using Docker with the startup script (recommended):**
    ```bash
    # From the onboarding directory
    ./start-client.sh
    ```
    This script will:
    - Check if Docker is installed and running
    - Verify the client configuration files exist
    - Create a development-specific Dockerfile if needed
    - Build the Docker image with the latest code
    - Handle port conflicts automatically
    - Start the client with all required environment variables
    - Mount source files for live reload during development

    **Option 2: Using Node.js directly:**
    ```bash
    cd IdeaFlye/ideaflye-client
    npm start
    ```
    This usually opens the client application in your default web browser.

b.  **To start the Server (`ideaflye-server`):**
    
    **Option 1: Using Docker with the startup script (recommended for Apple Silicon Macs):**
    ```bash
    # From the onboarding directory
    ./start-server.sh
    ```
    This script will:
    - Check if Docker is installed and running
    - Verify the server configuration files exist
    - Build the Docker image if needed
    - Handle port conflicts automatically
    - Start the server with all required parameters

    **Option 2: Using Docker manually:**
    ```bash
    cd IdeaFlye/ideaflye-server
    docker run -p 4000:80 -v $(pwd)/.env:/usr/src/app/.env -v $(pwd)/gcs-key.json:/usr/src/app/gcs-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/usr/src/app/gcs-key.json ideaflye-server
    ```

    **Option 3: Using Node.js directly:**
    ```bash
    cd IdeaFlye/ideaflye-server
    npm start
    ```

### 6. Running the Full Stack in Docker

For the best development experience, especially on Apple Silicon Macs, we recommend running both the client and server in Docker:

1. **Start the server first:**
   ```bash
   # From the onboarding directory
   ./start-server.sh
   ```

2. **Start the client in a new terminal:**
   ```bash
   # From the onboarding directory
   ./start-client.sh
   ```

3. **Access the application:**
   - Frontend UI: http://localhost:3000
   - GraphQL API: http://localhost:4000/graphql

Running in Docker provides these benefits:
- Consistent development environment across all platforms
- Avoids architecture compatibility issues (especially on Apple Silicon)
- Mirrors the production deployment more closely
- Handles all necessary environment variables and file mounts

With both client and server running locally, you can develop and test your changes. Remember that changes pushed to the `master` branch will trigger the production cloud build.

## Project Structure
The IdeaFlye project is organized into multiple repositories, each serving a specific purpose:

### Main Repositories
- `ideaflye-server`: Backend server implementation
- `ideaflye-client`: Frontend client application
- `ideaflye-neo4j`: Neo4j database configuration and management
- `ideaflye-ai`: AI/ML services and components

Each repository contains its own README with specific setup instructions and requirements.

## Development Workflow
1. Always work on feature branches
2. Follow the branching naming convention: `feature/description` or `bugfix/description`
3. Create pull requests for code reviews
4. Ensure all tests pass before requesting review

## Common Issues and Solutions

### TensorFlow and bcrypt Native Module Issues on Apple Silicon
**Problem:** On Apple Silicon Macs (M1/M2), you may encounter errors with native Node.js modules, particularly TensorFlow and bcrypt.
**Solution:** Use Docker as described in section 4 to run the server in a container with compatible binary modules.

### PostgreSQL Connection Errors
**Problem:** `Error connecting to PostgreSQL: Error: connect ECONNREFUSED [IP address]:5432`
**Solution:** This usually occurs when the PostgreSQL IP address has changed in Kubernetes. Run the `setup_local_env.sh` script again to fetch the latest configuration, or manually update the `POSTGRES_HOST` value in the server's `.env` file.

### Docker Port Already in Use
**Problem:** `Error response from daemon: failed to set up container networking: driver failed programming external connectivity: Bind for 0.0.0.0:4000 failed: port is already allocated`
**Solution:** Stop the currently running Docker container:
```bash
docker stop $(docker ps -q)
```
Then run your Docker container again.

### CORS Configuration Issues
**Problem:** `Origin http://localhost:3000 is not allowed by Access-Control-Allow-Origin.`
**Solution:** Ensure the server's .env file has the correct CORS_ORIGIN setting for local development:
```
CORS_ORIGIN="http://localhost:3000"
```
Be careful with duplicate CORS_ORIGIN entries in the .env file - the last one will override previous ones.

### HTTPS vs HTTP in Development
**Problem:** SSL errors when trying to connect to the local server: `An SSL error has occurred and a secure connection to the server cannot be made.`
**Solution:** The client's Apollo configuration should use HTTP for local development but HTTPS in production. This should be handled automatically, but if you encounter SSL errors, check `src/apolloClient.js` to ensure it detects localhost/development environments correctly.

### TensorFlow and Native Module Issues
**Problem:** Errors loading modules like TensorFlow or immutable: `Module not found: Error: Can't resolve '@tensorflow/tfjs-core'`
**Solution:** The Docker setup should handle this automatically. If you encounter these errors, try rebuilding the Docker image:
```bash
docker stop ideaflye-client
docker rm ideaflye-client
docker rmi ideaflye-client
cd /onboarding && ./start-client.sh
```

### Google Cloud Storage Authentication
**Problem:** `Error making bucket public: Could not load the default credentials`
**Solution:** Ensure the `GOOGLE_APPLICATION_CREDENTIALS` environment variable is set correctly when running Docker:
```bash
docker run -p 4000:80 -v $(pwd)/.env:/usr/src/app/.env -v $(pwd)/gcs-key.json:/usr/src/app/gcs-key.json -e GOOGLE_APPLICATION_CREDENTIALS=/usr/src/app/gcs-key.json ideaflye-server
```

## Need Help?
- For technical issues: [Contact information will be added]
- For access issues: Contact your team lead
- For general questions: Check our internal documentation or team communication channels

## Additional Resources
- [Link to internal documentation]
- [Link to coding standards]
- [Link to architecture documentation]

---
*This documentation is maintained by the IdeaFlye team and will be updated regularly.* 