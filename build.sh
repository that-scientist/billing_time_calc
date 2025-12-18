#!/bin/bash

# Billing Time Calculator - Build Script
# This script automates the compilation of the Xcode project

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
CONFIGURATION="Release"
BUILD_DIR="build"

# Update version if version.sh exists
if [ -f "version.sh" ]; then
    echo -e "${BLUE}Updating version information...${NC}"
    # Check if --increment flag is passed
    if [ "$1" == "--increment" ]; then
        ./version.sh increment-build
    else
        ./version.sh update
    fi
    # Regenerate Xcode project to pick up version changes
    if command -v xcodegen &> /dev/null; then
        xcodegen generate > /dev/null 2>&1
    fi
fi

echo -e "${GREEN}Building ${PROJECT_NAME}...${NC}"

# Check if .xcodeproj exists
if [ ! -d "${PROJECT_NAME}.xcodeproj" ]; then
    echo -e "${RED}Error: ${PROJECT_NAME}.xcodeproj not found!${NC}"
    echo -e "${YELLOW}Please create an Xcode project first, or run ./setup_xcode_project.sh${NC}"
    exit 1
fi

# Clean previous build and remove app bundle
echo -e "${YELLOW}Cleaning previous build...${NC}"
xcodebuild clean \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    > /dev/null 2>&1 || true

# Remove old app bundle to ensure fresh install
if [ -d "${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app" ]; then
    rm -rf "${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app"
    echo -e "${YELLOW}Removed old app bundle...${NC}"
fi

# Build the project
echo -e "${YELLOW}Building project...${NC}"
xcodebuild build \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -allowProvisioningUpdates

# Unregister old version from Launch Services
if [ -d "${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app" 2>/dev/null || true
fi

# Check build result
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    
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
    fi
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

