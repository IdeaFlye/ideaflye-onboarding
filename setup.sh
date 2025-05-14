#!/bin/bash

# IdeaFlye Development Environment Setup Script
# This script automates the setup process for new developers

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Check if Git is installed
check_git() {
    print_status "Checking Git installation..."
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git and try again."
        exit 1
    fi
    print_status "Git is installed: $(git --version)"
}

# Check Git configuration
check_git_config() {
    print_status "Checking Git configuration..."
    local git_name=$(git config --global user.name)
    local git_email=$(git config --global user.email)
    
    if [ -z "$git_name" ] || [ -z "$git_email" ]; then
        print_warning "Git user configuration is incomplete."
        print_status "Please configure your Git identity:"
        echo "Run the following commands:"
        echo "git config --global user.name \"Your Name\""
        echo "git config --global user.email \"your.email@example.com\""
        exit 1
    fi
    print_status "Git configuration looks good!"
}

# Check GitHub CLI installation
check_gh_cli() {
    print_status "Checking GitHub CLI installation..."
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI is not installed."
        print_status "Installing GitHub CLI is recommended for easier authentication."
        print_status "Visit: https://cli.github.com/ for installation instructions"
    else
        print_status "GitHub CLI is installed: $(gh --version | head -n 1)"
    fi
}

# Function to clone repositories
clone_repositories() {
    print_status "Preparing to clone IdeaFlye repositories..."
    
    # Move up one directory from onboarding folder and create IdeaFlye directory
    cd ..
    mkdir -p IdeaFlye
    cd IdeaFlye
    
    print_status "Fetching repository list from IdeaFlye organization..."
    print_status "Note: You may be prompted for your SSH key passphrase multiple times during cloning"
    print_status "For first-time setup, you'll also need to verify GitHub's host authenticity"
    
    if command -v gh &> /dev/null; then
        print_status "Using GitHub CLI to clone repositories..."
        gh repo list IdeaFlye --limit 1000 --json nameWithOwner -q '.[]|.nameWithOwner' | while read repo; do
            print_status "Cloning $repo..."
            gh repo clone "$repo" || print_error "Failed to clone $repo"
            echo # Add a blank line for better readability
        done
        
        print_status "Successfully cloned repositories:"
        ls -1 | while read dir; do
            if [ -d "$dir" ]; then
                echo "  - $dir"
            fi
        done
    else
        print_warning "GitHub CLI not found. Using HTTPS cloning..."
        print_status "Please install GitHub CLI for automatic repository discovery"
    fi
}

# Main execution
main() {
    print_status "Starting IdeaFlye development environment setup..."
    
    check_git
    check_git_config
    check_gh_cli
    
    # Prompt user before proceeding
    read -p "Ready to clone repositories? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clone_repositories
        print_status "Setup complete! Please check the documentation for next steps."
    else
        print_status "Setup cancelled. Run this script again when you're ready."
    fi
}

# Run main function
main 