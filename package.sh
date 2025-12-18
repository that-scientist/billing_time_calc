#!/bin/bash

# Package BillingTimeCalc for Distribution
# Creates a portable .app bundle and optionally a DMG file

set -e

APP_NAME="BillingTimeCalc"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_BUNDLE_NAME="${APP_NAME}.app"
APP_BUNDLE_PATH="${BUILD_DIR}/Build/Products/Release/${APP_BUNDLE_NAME}"
PACKAGE_DIR="${PROJECT_DIR}/package"
DMG_NAME="${APP_NAME}.dmg"
ZIP_NAME="${APP_NAME}.zip"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Packaging ${APP_NAME} for Distribution ===${NC}"

# 1. Ensure we have a fresh build
echo -e "${YELLOW}Building the latest version...${NC}"
"${PROJECT_DIR}/build.sh" > /dev/null 2>&1

# Check if app bundle exists
if [ ! -d "${APP_BUNDLE_PATH}" ]; then
    echo -e "${RED}Error: App bundle not found at ${APP_BUNDLE_PATH}${NC}"
    echo -e "${YELLOW}Please run ./build.sh first${NC}"
    exit 1
fi

# 2. Create package directory
echo -e "${YELLOW}Creating package directory...${NC}"
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"

# 3. Copy app bundle to package directory
echo -e "${YELLOW}Copying app bundle...${NC}"
cp -R "${APP_BUNDLE_PATH}" "${PACKAGE_DIR}/"

# 4. Get version info
VERSION=$(defaults read "${PACKAGE_DIR}/${APP_BUNDLE_NAME}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
BUILD=$(defaults read "${PACKAGE_DIR}/${APP_BUNDLE_NAME}/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "1")

echo -e "${GREEN}App version: ${VERSION} (Build ${BUILD})${NC}"

# 5. Create a README for the package
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

For more information, see the main README.md file.
EOF

# 6. Create ZIP file
echo -e "${YELLOW}Creating ZIP archive...${NC}"
cd "${PACKAGE_DIR}"
zip -r "${ZIP_NAME}" "${APP_BUNDLE_NAME}" "README.txt" > /dev/null 2>&1
mv "${ZIP_NAME}" "${PROJECT_DIR}/"
cd "${PROJECT_DIR}"

echo -e "${GREEN}✓ Created ${ZIP_NAME}${NC}"

# 7. Optionally create DMG (if hdiutil is available)
if command -v hdiutil > /dev/null 2>&1; then
    echo -e "${YELLOW}Creating DMG file...${NC}"
    
    DMG_TEMP="${PACKAGE_DIR}/temp.dmg"
    DMG_FINAL="${PROJECT_DIR}/${DMG_NAME}"
    
    # Remove old DMG if it exists
    rm -f "${DMG_FINAL}"
    
    # Create DMG
    hdiutil create -srcfolder "${PACKAGE_DIR}" -volname "${APP_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 50m "${DMG_TEMP}" > /dev/null 2>&1
    
    # Mount and configure DMG
    DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
    
    # Wait for mount
    sleep 2
    
    # Unmount
    hdiutil detach "${DEVICE}" > /dev/null 2>&1
    
    # Convert to read-only
    hdiutil convert "${DMG_TEMP}" -format UDZO -o "${DMG_FINAL}" > /dev/null 2>&1
    rm -f "${DMG_TEMP}"
    
    echo -e "${GREEN}✓ Created ${DMG_NAME}${NC}"
else
    echo -e "${YELLOW}Note: hdiutil not available, skipping DMG creation${NC}"
fi

# 8. Show package info
echo -e "\n${BLUE}=== Package Created Successfully ===${NC}"
echo -e "${GREEN}Package location: ${PACKAGE_DIR}/${NC}"
echo -e "${GREEN}ZIP file: ${PROJECT_DIR}/${ZIP_NAME}${NC}"
if [ -f "${PROJECT_DIR}/${DMG_NAME}" ]; then
    echo -e "${GREEN}DMG file: ${PROJECT_DIR}/${DMG_NAME}${NC}"
fi
echo -e "\n${YELLOW}To distribute:${NC}"
echo -e "  - Share the ZIP file (${ZIP_NAME})"
if [ -f "${PROJECT_DIR}/${DMG_NAME}" ]; then
    echo -e "  - Or share the DMG file (${DMG_NAME})"
fi
echo -e "  - Users can extract and drag ${APP_BUNDLE_NAME} to Applications"

