#!/bin/bash

# Billing Time Calculator - Xcode Project Setup Script
# This script helps set up the Xcode project

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_NAME="BillingTimeCalc"

echo -e "${BLUE}=== Xcode Project Setup ===${NC}\n"

# Check if project already exists
if [ -d "${PROJECT_NAME}.xcodeproj" ]; then
    echo -e "${GREEN}✓ Xcode project already exists!${NC}"
    exit 0
fi

# Check if xcodegen is available
if command -v xcodegen &> /dev/null; then
    echo -e "${YELLOW}Found xcodegen. Generating project...${NC}"
    
    # Create project.yml if it doesn't exist
    if [ ! -f "project.yml" ]; then
        echo -e "${YELLOW}Creating project.yml...${NC}"
        cat > project.yml << 'EOF'
name: BillingTimeCalc
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    macOS: "13.0"
targets:
  BillingTimeCalc:
    type: application
    platform: macOS
    sources:
      - path: .
        excludes:
          - "*.md"
          - "*.sh"
          - "*.yml"
          - "build"
          - ".git"
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.example.BillingTimeCalc
      INFOPLIST_FILE: Info.plist
      SWIFT_VERSION: "5.9"
      MACOSX_DEPLOYMENT_TARGET: "13.0"
EOF
    fi
    
    xcodegen generate
    echo -e "${GREEN}✓ Xcode project created successfully!${NC}"
    exit 0
fi

# If xcodegen is not available, provide manual instructions
echo -e "${YELLOW}xcodegen not found. Please set up the project manually:${NC}\n"
echo -e "${BLUE}Manual Setup Instructions:${NC}"
echo -e "1. Open Xcode"
echo -e "2. Select 'File' → 'New' → 'Project'"
echo -e "3. Choose 'macOS' → 'App'"
echo -e "4. Fill in:"
echo -e "   - Product Name: ${PROJECT_NAME}"
echo -e "   - Interface: SwiftUI"
echo -e "   - Language: Swift"
echo -e "   - Click 'Next'"
echo -e "5. Choose this directory: $(pwd)"
echo -e "6. Click 'Create'"
echo -e "7. In Xcode:"
echo -e "   - Delete the default App.swift and ContentView.swift files"
echo -e "   - Right-click the project → 'Add Files to ${PROJECT_NAME}...'"
echo -e "   - Select: BillingTimeCalcApp.swift, ContentView.swift, BillingCalculator.swift, Info.plist"
echo -e "   - Make sure 'Copy items if needed' is UNCHECKED"
echo -e "   - Click 'Add'"
echo -e "\n${GREEN}After setup, you can use ./build.sh to build the project.${NC}\n"

# Offer to install xcodegen via Homebrew
if command -v brew &> /dev/null; then
    read -p "Would you like to install xcodegen via Homebrew for automated setup? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing xcodegen...${NC}"
        brew install xcodegen
        echo -e "${GREEN}✓ xcodegen installed! Run this script again to auto-generate the project.${NC}"
    fi
else
    echo -e "${YELLOW}Tip: Install Homebrew and xcodegen for automated project setup:${NC}"
    echo -e "   brew install xcodegen"
fi

