#!/bin/bash

# Force Install Script
# Completely removes old versions and installs fresh build

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="BillingTimeCalc"
BUILD_DIR="build"
APP_PATH="${BUILD_DIR}/Build/Products/Release/${PROJECT_NAME}.app"

echo -e "${BLUE}=== Force Install ${PROJECT_NAME} ===${NC}\n"

# Step 1: Quit all instances
echo -e "${YELLOW}Step 1: Quitting all running instances...${NC}"
pkill -9 -f "${PROJECT_NAME}" 2>/dev/null || true
osascript -e "tell application \"${PROJECT_NAME}\" to quit" 2>/dev/null || true
sleep 2

# Step 2: Remove from common locations
echo -e "${YELLOW}Step 2: Removing old versions from common locations...${NC}"
rm -rf "/Applications/${PROJECT_NAME}.app" 2>/dev/null || true
rm -rf "${HOME}/Applications/${PROJECT_NAME}.app" 2>/dev/null || true
rm -rf "${HOME}/Desktop/${PROJECT_NAME}.app" 2>/dev/null || true

# Step 3: Unregister from Launch Services
echo -e "${YELLOW}Step 3: Unregistering from Launch Services...${NC}"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "/Applications/${PROJECT_NAME}.app" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "${HOME}/Applications/${PROJECT_NAME}.app" 2>/dev/null || true

# Step 4: Build fresh
echo -e "${YELLOW}Step 4: Building fresh version...${NC}"
./version.sh increment-build > /dev/null 2>&1
xcodegen generate > /dev/null 2>&1
./build.sh > /dev/null 2>&1

# Step 5: Verify build
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}✗ Build failed! App not found at ${APP_PATH}${NC}"
    exit 1
fi

# Step 6: Display version
if [ -f "version.sh" ]; then
    VERSION=$(./version.sh get-version)
    BUILD=$(./version.sh get-build)
    echo -e "${GREEN}✓ Built Version ${VERSION} (Build ${BUILD})${NC}"
fi

# Step 7: Register with Launch Services
echo -e "${YELLOW}Step 5: Registering with Launch Services...${NC}"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_PATH" 2>/dev/null || true

# Step 8: Launch
echo -e "${GREEN}Step 6: Launching ${PROJECT_NAME}...${NC}"
open "$APP_PATH"

echo -e "\n${GREEN}✓ Installation complete!${NC}"
echo -e "${BLUE}App location: ${APP_PATH}${NC}"
echo -e "${YELLOW}Note: If you still don't see the note selector, try:${NC}"
echo -e "  1. Quit the app completely (⌘Q)"
echo -e "  2. Run this script again"
echo -e "  3. Or manually launch: open \"${APP_PATH}\""

