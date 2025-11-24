#!/bin/bash

# deploy.sh - Script for deploying the application
#
# This script helps with deploying the application to different environments,
# including Kubernetes and Docker environments.

# Safer Bash scripting options
set -o pipefail # Don't hide errors within pipes
set -o nounset  # Abort on unbound variable
set -o errexit  # Abort on nonzero exit status

# Default values
ENVIRONMENT="dev"
DOCKER_REGISTRY=""
IMAGE_TAG="latest"
HELM_CHART_DIR="./helm-charts"
KUBE_NAMESPACE="default"
DOCKER_COMPOSE_FILE="./compose-mysql.yaml"
DEPLOYMENT_TYPE="kubernetes"
SKIP_BUILD=false
SKIP_TESTS=false

# Function to display usage information
function show_usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -e, --environment ENV      Target environment (dev, test, prod) [default: dev]"
    echo "  -r, --registry REGISTRY    Docker registry URL"
    echo "  -t, --tag TAG              Image tag [default: latest]"
    echo "  -c, --chart-dir DIR        Helm chart directory [default: ./helm-charts]"
    echo "  -n, --namespace NS         Kubernetes namespace [default: default]"
    echo "  -d, --docker-compose FILE  Docker compose file [default: ./compose-mysql.yaml]"
    echo "  --docker                   Deploy using Docker Compose instead of Kubernetes"
    echo "  --skip-build               Skip building the application"
    echo "  --skip-tests               Skip tests during build"
    echo "  -h, --help                 Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -c|--chart-dir)
            HELM_CHART_DIR="$2"
            shift 2
            ;;
        -n|--namespace)
            KUBE_NAMESPACE="$2"
            shift 2
            ;;
        -d|--docker-compose)
            DOCKER_COMPOSE_FILE="$2"
            shift 2
            ;;
        --docker)
            DEPLOYMENT_TYPE="docker"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
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

# Function to check prerequisites based on deployment type
function check_prerequisites {
    echo "Checking prerequisites for $DEPLOYMENT_TYPE deployment..."
    
    # Common prerequisites
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo "✓ Java found: $JAVA_VERSION"
    else
        echo "✗ Java not found. Please install Java 17 or later."
        exit 1
    fi
    
    if command_exists mvn; then
        MVN_VERSION=$(mvn --version | head -n 1)
        echo "✓ Maven found: $MVN_VERSION"
    else
        echo "✗ Maven not found. Please install Maven 3.6 or later."
        exit 1
    fi
    
    # Deployment-specific prerequisites
    if [ "$DEPLOYMENT_TYPE" = "kubernetes" ]; then
        if command_exists kubectl; then
            KUBECTL_VERSION=$(kubectl version --client --short)
            echo "✓ kubectl found: $KUBECTL_VERSION"
        else
            echo "✗ kubectl not found. Please install kubectl or use --docker option."
            exit 1
        fi
        
        if command_exists helm; then
            HELM_VERSION=$(helm version --short)
            echo "✓ Helm found: $HELM_VERSION"
        else
            echo "✗ Helm not found. Please install Helm or use --docker option."
            exit 1
        fi
    elif [ "$DEPLOYMENT_TYPE" = "docker" ]; then
        if command_exists docker; then
            DOCKER_VERSION=$(docker --version)
            echo "✓ Docker found: $DOCKER_VERSION"
        else
            echo "✗ Docker not found. Please install Docker."
            exit 1
        fi
        
        if command_exists docker-compose; then
            COMPOSE_VERSION=$(docker-compose --version)
            echo "✓ Docker Compose found: $COMPOSE_VERSION"
        else
            echo "✗ Docker Compose not found. Please install Docker Compose."
            exit 1
        fi
    fi
    
    echo "All prerequisites are met."
}

# Function to build the application
function build_application {
    if [ "$SKIP_BUILD" = true ]; then
        echo "Skipping build as requested."
        return
    fi
    
    echo "Building application for $ENVIRONMENT environment..."
    
    # Build command
    BUILD_CMD="mvn clean package -P$ENVIRONMENT"
    if [ "$SKIP_TESTS" = true ]; then
        BUILD_CMD="$BUILD_CMD -DskipTests"
    fi
    
    # Execute build
    echo "Executing: $BUILD_CMD"
    eval "$BUILD_CMD"
    
    if [ $? -ne 0 ]; then
        echo "Build failed. Exiting."
        exit 1
    fi
    
    echo "Build completed successfully."
}

# Function to build and push Docker image
function build_docker_image {
    if [ "$SKIP_BUILD" = true ]; then
        echo "Skipping Docker image build as requested."
        return
    fi
    
    echo "Building Docker image..."
    
    # Get artifact details
    ARTIFACT_ID=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
    VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    
    # Set image name
    if [ -n "$DOCKER_REGISTRY" ]; then
        IMAGE_NAME="$DOCKER_REGISTRY/$ARTIFACT_ID:$IMAGE_TAG"
    else
        IMAGE_NAME="$ARTIFACT_ID:$IMAGE_TAG"
    fi
    
    # Build Docker image
    echo "Building image: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" .
    
    if [ $? -ne 0 ]; then
        echo "Docker image build failed. Exiting."
        exit 1
    fi
    
    # Push to registry if specified
    if [ -n "$DOCKER_REGISTRY" ]; then
        echo "Pushing image to registry: $IMAGE_NAME"
        docker push "$IMAGE_NAME"
        
        if [ $? -ne 0 ]; then
            echo "Failed to push Docker image. Exiting."
            exit 1
        fi
    fi
    
    echo "Docker image built and pushed successfully."
}

# Function to deploy to Kubernetes
function deploy_to_kubernetes {
    echo "Deploying to Kubernetes in namespace: $KUBE_NAMESPACE"
    
    # Check if namespace exists, create if not
    if ! kubectl get namespace "$KUBE_NAMESPACE" &>/dev/null; then
        echo "Creating namespace: $KUBE_NAMESPACE"
        kubectl create namespace "$KUBE_NAMESPACE"
    fi
    
    # Get artifact details
    ARTIFACT_ID=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
    
    # Set image name for Helm values
    if [ -n "$DOCKER_REGISTRY" ]; then
        IMAGE_NAME="$DOCKER_REGISTRY/$ARTIFACT_ID:$IMAGE_TAG"
    else
        IMAGE_NAME="$ARTIFACT_ID:$IMAGE_TAG"
    fi
    
    # Deploy using Helm
    echo "Deploying using Helm chart from: $HELM_CHART_DIR"
    helm upgrade --install "$ARTIFACT_ID" "$HELM_CHART_DIR" \
        --namespace "$KUBE_NAMESPACE" \
        --set image.repository="$IMAGE_NAME" \
        --set environment="$ENVIRONMENT"
    
    if [ $? -ne 0 ]; then
        echo "Kubernetes deployment failed. Exiting."
        exit 1
    fi
    
    echo "Application deployed to Kubernetes successfully."
    echo "You can check the status with: kubectl get pods -n $KUBE_NAMESPACE"
}

# Function to deploy using Docker Compose
function deploy_to_docker {
    echo "Deploying using Docker Compose with file: $DOCKER_COMPOSE_FILE"
    
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        echo "Error: Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    # Stop any existing containers
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    
    # Start containers
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    if [ $? -ne 0 ]; then
        echo "Docker Compose deployment failed. Exiting."
        exit 1
    fi
    
    echo "Application deployed with Docker Compose successfully."
    echo "You can check the status with: docker-compose -f $DOCKER_COMPOSE_FILE ps"
}

# Main execution
echo "Deploying application to $ENVIRONMENT environment using $DEPLOYMENT_TYPE..."
check_prerequisites
build_application

if [ "$DEPLOYMENT_TYPE" = "kubernetes" ]; then
    build_docker_image
    deploy_to_kubernetes
elif [ "$DEPLOYMENT_TYPE" = "docker" ]; then
    deploy_to_docker
fi

echo "Deployment completed successfully."