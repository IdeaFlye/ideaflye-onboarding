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
(This section will be populated as we encounter and solve issues during development)

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