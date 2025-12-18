#!/bin/bash

# Install and Run Script
# This script ensures the old app is quit, installs the new version, and runs it

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="BillingTimeCalc"
BUILD_DIR="build"
APP_PATH="${BUILD_DIR}/Build/Products/Release/${PROJECT_NAME}.app"

echo -e "${BLUE}=== Install and Run ${PROJECT_NAME} ===${NC}\n"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${YELLOW}App not found. Building first...${NC}"
    ./build.sh
fi

# Quit any running instances
echo -e "${YELLOW}Quitting any running instances...${NC}"
osascript -e "tell application \"${PROJECT_NAME}\" to quit" 2>/dev/null || true
sleep 1

# Kill any remaining processes
pkill -f "${PROJECT_NAME}" 2>/dev/null || true
sleep 1

# Unregister from Launch Services (force refresh)
echo -e "${YELLOW}Refreshing Launch Services...${NC}"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$APP_PATH" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_PATH" 2>/dev/null || true

# Display version info
if [ -f "version.sh" ]; then
    VERSION=$(./version.sh get-version)
    BUILD=$(./version.sh get-build)
    echo -e "${GREEN}Installing Version ${VERSION} (Build ${BUILD})${NC}"
fi

# Launch the app
echo -e "${GREEN}Launching ${PROJECT_NAME}...${NC}"
open "$APP_PATH"

echo -e "${GREEN}✓ Done!${NC}"

