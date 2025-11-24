#!/bin/bash

# build-run.sh - Script to build and run the Spring Boot application
# 
# This script builds the project using Maven and runs the resulting JAR file.
# It supports different profiles (h2, mysql) and can be configured with JVM options.

# Safer Bash scripting options
set -o pipefail # Don't hide errors within pipes
set -o nounset  # Abort on unbound variable
set -o errexit  # Abort on nonzero exit status

# Default values
PROFILE="h2"
JVM_OPTS=""
SKIP_TESTS=false

# Function to display usage information
function show_usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -p, --profile PROFILE    Set Spring profile (h2, mysql) [default: h2]"
    echo "  -j, --jvm-opts OPTS      Set JVM options"
    echo "  -s, --skip-tests         Skip tests during build"
    echo "  -h, --help               Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -j|--jvm-opts)
            JVM_OPTS="$2"
            shift 2
            ;;
        -s|--skip-tests)
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

# Validate profile
if [[ "$PROFILE" != "h2" && "$PROFILE" != "mysql" ]]; then
    echo "Error: Invalid profile '$PROFILE'. Must be 'h2' or 'mysql'."
    exit 1
fi

echo "Building application with Maven..."

# Build command
BUILD_CMD="mvn clean package"
if [ "$SKIP_TESTS" = true ]; then
    BUILD_CMD="$BUILD_CMD -DskipTests"
fi

# Execute build
echo "Executing: $BUILD_CMD"
eval "$BUILD_CMD"

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Build failed. Exiting."
    exit 1
fi

# Find the generated JAR file
JAR_FILE=$(find target -name "*.jar" -not -name "*sources.jar" -not -name "*javadoc.jar" | head -1)

if [ -z "$JAR_FILE" ]; then
    echo "Error: Could not find JAR file in target directory."
    exit 1
fi

echo "Starting application with profile: $PROFILE"
echo "JAR file: $JAR_FILE"

# Run the application
java $JVM_OPTS -jar "$JAR_FILE" --spring.profiles.active="$PROFILE"