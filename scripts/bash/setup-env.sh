#!/bin/bash

# setup-env.sh - Script for setting up the development environment
#
# This script helps set up the development environment for the project,
# including checking prerequisites, setting up Docker containers,
# and configuring the application.

# Safer Bash scripting options
set -o pipefail # Don't hide errors within pipes
set -o nounset  # Abort on unbound variable
set -o errexit  # Abort on nonzero exit status

# Default values
DOCKER_COMPOSE_FILE="./compose-mysql.yaml"
USE_DOCKER=true
SETUP_DB=true
INSTALL_DEPS=true

# Function to display usage information
function show_usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --docker-compose FILE  Docker compose file [default: ./compose-mysql.yaml]"
    echo "  --no-docker                Skip Docker setup"
    echo "  --no-db                    Skip database setup"
    echo "  --no-deps                  Skip dependency installation"
    echo "  -h, --help                 Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--docker-compose)
            DOCKER_COMPOSE_FILE="$2"
            shift 2
            ;;
        --no-docker)
            USE_DOCKER=false
            shift
            ;;
        --no-db)
            SETUP_DB=false
            shift
            ;;
        --no-deps)
            INSTALL_DEPS=false
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Function to check if a command exists
function command_exists {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
function check_prerequisites {
    echo "Checking prerequisites..."
    
    # Check Java
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "✓ Java found: $JAVA_VERSION"
    else
        echo "✗ Java not found. Please install Java 17 or later."
        exit 1
    fi
    
    # Check Maven
    if command_exists mvn; then
        MVN_VERSION=$(mvn --version | head -n 1)
        echo "✓ Maven found: $MVN_VERSION"
    else
        echo "✗ Maven not found. Please install Maven 3.6 or later."
        exit 1
    fi
    
    # Check Docker if needed
    if [ "$USE_DOCKER" = true ]; then
        if command_exists docker; then
            DOCKER_VERSION=$(docker --version)
            echo "✓ Docker found: $DOCKER_VERSION"
        else
            echo "✗ Docker not found. Please install Docker or use --no-docker option."
            exit 1
        fi
        
        if command_exists docker-compose; then
            COMPOSE_VERSION=$(docker-compose --version)
            echo "✓ Docker Compose found: $COMPOSE_VERSION"
        else
            echo "✗ Docker Compose not found. Please install Docker Compose or use --no-docker option."
            exit 1
        fi
    fi
    
    echo "All prerequisites are met."
}

# Function to set up Docker containers
function setup_docker {
    if [ "$USE_DOCKER" = true ]; then
        echo "Setting up Docker containers using $DOCKER_COMPOSE_FILE..."
        
        if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
            echo "Error: Docker Compose file not found: $DOCKER_COMPOSE_FILE"
            exit 1
        fi
        
        # Stop any existing containers
        docker-compose -f "$DOCKER_COMPOSE_FILE" down
        
        # Start containers
        docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
        
        # Wait for MySQL to be ready
        echo "Waiting for MySQL to be ready..."
        sleep 10
        
        echo "Docker containers are up and running."
    else
        echo "Skipping Docker setup as requested."
    fi
}

# Function to set up the database
function setup_database {
    if [ "$SETUP_DB" = true ]; then
        echo "Setting up the database..."
        
        if [ "$USE_DOCKER" = true ]; then
            # Database is already set up in Docker, just need to initialize it
            echo "Initializing database..."
            ./scripts/bash/db-operations.sh init
        else
            echo "Please make sure your MySQL database is running and properly configured."
            echo "You can initialize the database using: ./scripts/bash/db-operations.sh init"
        fi
    else
        echo "Skipping database setup as requested."
    fi
}

# Function to install dependencies
function install_dependencies {
    if [ "$INSTALL_DEPS" = true ]; then
        echo "Installing Maven dependencies..."
        mvn dependency:resolve
        
        if [ $? -eq 0 ]; then
            echo "Dependencies installed successfully."
        else
            echo "Error: Failed to install dependencies."
            exit 1
        fi
    else
        echo "Skipping dependency installation as requested."
    fi
}

# Main execution
echo "Setting up development environment..."
check_prerequisites
setup_docker
setup_database
install_dependencies

echo "Environment setup completed successfully."
echo "You can now build and run the application using: ./scripts/bash/build-run.sh"