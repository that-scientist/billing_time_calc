#!/bin/bash

# Billing Time Calculator - Build and Run Script
# This script builds the project and optionally runs it

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="BillingTimeCalc"
SCHEME_NAME="BillingTimeCalc"
CONFIGURATION="Debug"
BUILD_DIR="build"

echo -e "${BLUE}=== Billing Time Calculator - Build & Run ===${NC}\n"

# Check if .xcodeproj exists
if [ ! -d "${PROJECT_NAME}.xcodeproj" ]; then
    echo -e "${RED}Error: ${PROJECT_NAME}.xcodeproj not found!${NC}"
    echo -e "${YELLOW}Please create an Xcode project first.${NC}"
    echo -e "${YELLOW}You can do this by:${NC}"
    echo -e "  1. Open Xcode"
    echo -e "  2. Create a new macOS App project"
    echo -e "  3. Add the Swift files to the project"
    exit 1
fi

# Update version if version.sh exists
if [ -f "version.sh" ]; then
    echo -e "${BLUE}Updating version information...${NC}"
    ./version.sh update
    # Regenerate Xcode project to pick up version changes
    if command -v xcodegen &> /dev/null; then
        xcodegen generate > /dev/null 2>&1
    fi
fi

# Build the project
echo -e "${YELLOW}Building project...${NC}"
xcodebuild build \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO

# Check build result
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}\n"
    
    # Find the built app
    APP_PATH=$(find "${BUILD_DIR}" -name "${PROJECT_NAME}.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo -e "${GREEN}App location: ${APP_PATH}${NC}"
        
        # Display version info
        if [ -f "version.sh" ]; then
            VERSION=$(./version.sh get-version)
            BUILD=$(./version.sh get-build)
            echo -e "${BLUE}Version: ${VERSION} (Build ${BUILD})${NC}"
        fi
        
        # Ask if user wants to run the app
        read -p "Do you want to run the app? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Launching app...${NC}"
            open "${APP_PATH}"
        fi
    else
        echo -e "${YELLOW}Warning: Could not find built app${NC}"
    fi
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

