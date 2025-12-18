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

# Function to create DMG file
create_dmg() {
    APP_BUNDLE_NAME="${PROJECT_NAME}.app"
    RELEASE_APP_BUNDLE_PATH="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${APP_BUNDLE_NAME}"
    PACKAGE_DIR="package"
    DMG_NAME="${PROJECT_NAME}.dmg"
    
    # Check if app bundle exists
    if [ ! -d "${RELEASE_APP_BUNDLE_PATH}" ]; then
        echo -e "${YELLOW}Warning: App bundle not found, skipping DMG creation${NC}"
        return
    fi
    
    # Remove old DMG if it exists
    if [ -f "${DMG_NAME}" ]; then
        rm -f "${DMG_NAME}"
        echo -e "${YELLOW}Removed old DMG file${NC}"
    fi
    
    # Create temporary package directory
    rm -rf "${PACKAGE_DIR}"
    mkdir -p "${PACKAGE_DIR}"
    
    # Copy app bundle to package directory
    cp -R "${RELEASE_APP_BUNDLE_PATH}" "${PACKAGE_DIR}/"
    
    # Get version info
    VERSION=$(defaults read "${PACKAGE_DIR}/${APP_BUNDLE_NAME}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
    BUILD=$(defaults read "${PACKAGE_DIR}/${APP_BUNDLE_NAME}/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "1")
    
    # Create README for the package
    cat > "${PACKAGE_DIR}/README.txt" << EOF
Billing Time Calculator
Version ${VERSION} (Build ${BUILD})

INSTALLATION:
1. Drag ${APP_BUNDLE_NAME} to your Applications folder
2. Open the app from Applications

Or simply double-click ${APP_BUNDLE_NAME} to run it directly.

SYSTEM REQUIREMENTS:
- macOS 13.0 or later

FEATURES:
- Calculate billing calls for Progress Notes and Consult Notes
- Supports both 12-hour and 24-hour time formats
- Automatic warnings for time optimization
- Copy results and suggested time ranges to clipboard
- Display billing tables and calculation details

For more information, see the main README.md file.
EOF
    
    # Create DMG if hdiutil is available
    if command -v hdiutil > /dev/null 2>&1; then
        DMG_TEMP="${PACKAGE_DIR}/temp.dmg"
        DMG_FINAL="${DMG_NAME}"
        
        # Create DMG
        hdiutil create -srcfolder "${PACKAGE_DIR}" -volname "${PROJECT_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 50m "${DMG_TEMP}" > /dev/null 2>&1
        
        # Mount and configure DMG
        DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP}" | egrep '^/dev/' | sed 1q | awk '{print $1}' 2>/dev/null || echo "")
        
        if [ -n "${DEVICE}" ]; then
            # Wait for mount
            sleep 2
            
            # Create symlink to Applications
            MOUNT_POINT="/Volumes/${PROJECT_NAME}"
            if [ -d "${MOUNT_POINT}" ]; then
                ln -s /Applications "${MOUNT_POINT}/Applications" 2>/dev/null || true
            fi
            
            # Unmount
            hdiutil detach "${DEVICE}" > /dev/null 2>&1 || true
        fi
        
        # Convert to compressed read-only format
        hdiutil convert "${DMG_TEMP}" -format UDZO -o "${DMG_FINAL}" > /dev/null 2>&1
        rm -f "${DMG_TEMP}"
        
        # Clean up package directory
        rm -rf "${PACKAGE_DIR}"
        
        # Get DMG file size
        DMG_SIZE=$(du -h "${DMG_FINAL}" | cut -f1)
        
        echo -e "${GREEN}✓ Created ${DMG_NAME} (${DMG_SIZE})${NC}"
        echo -e "${BLUE}DMG location: $(pwd)/${DMG_NAME}${NC}"
    else
        echo -e "${YELLOW}Note: hdiutil not available, skipping DMG creation${NC}"
        rm -rf "${PACKAGE_DIR}"
    fi
}

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
        
        # Create DMG for distribution
        echo -e "${YELLOW}Creating DMG for distribution...${NC}"
        create_dmg
    fi
else
    echo -e "${RED}✗ Build failed!${NC}"
    exit 1
fi

