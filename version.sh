#!/bin/bash

# Version management script for BillingTimeCalc
# This script manages version numbers and build numbers

VERSION_FILE=".version"
PROJECT_FILE="project.yml"

# Initialize version file if it doesn't exist
if [ ! -f "$VERSION_FILE" ]; then
    echo "VERSION=1.0" > "$VERSION_FILE"
    echo "BUILD=1" >> "$VERSION_FILE"
fi

# Read current version
source "$VERSION_FILE"

# Function to get current version
get_version() {
    echo "$VERSION"
}

# Function to get current build number
get_build() {
    echo "$BUILD"
}

# Function to increment build number
increment_build() {
    BUILD=$((BUILD + 1))
    echo "VERSION=$VERSION" > "$VERSION_FILE"
    echo "BUILD=$BUILD" >> "$VERSION_FILE"
    echo "$BUILD"
}

# Function to set version
set_version() {
    if [ -z "$1" ]; then
        echo "Usage: $0 set-version <version>"
        exit 1
    fi
    VERSION="$1"
    echo "VERSION=$VERSION" > "$VERSION_FILE"
    echo "BUILD=$BUILD" >> "$VERSION_FILE"
    echo "Version set to $VERSION"
}

# Function to update project.yml with current version
update_project() {
    # Update project.yml with current version and build
    if command -v perl &> /dev/null; then
        perl -i -pe "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VERSION\"/" "$PROJECT_FILE"
        perl -i -pe "s/CURRENT_PROJECT_VERSION: \".*\"/CURRENT_PROJECT_VERSION: \"$BUILD\"/" "$PROJECT_FILE"
    elif command -v sed &> /dev/null; then
        sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VERSION\"/" "$PROJECT_FILE"
        sed -i '' "s/CURRENT_PROJECT_VERSION: \".*\"/CURRENT_PROJECT_VERSION: \"$BUILD\"/" "$PROJECT_FILE"
    else
        echo "Error: Need perl or sed to update project.yml"
        exit 1
    fi
    echo "Updated project.yml: Version $VERSION, Build $BUILD"
}

# Main command handling
case "${1:-}" in
    get-version)
        get_version
        ;;
    get-build)
        get_build
        ;;
    increment-build)
        increment_build
        update_project
        ;;
    set-version)
        set_version "$2"
        update_project
        ;;
    update)
        update_project
        ;;
    *)
        echo "BillingTimeCalc Version Manager"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  get-version       - Display current version"
        echo "  get-build        - Display current build number"
        echo "  increment-build   - Increment build number and update project"
        echo "  set-version <v>  - Set version number (e.g., 1.1)"
        echo "  update           - Update project.yml with current version/build"
        echo ""
        echo "Current: Version $VERSION, Build $BUILD"
        ;;
esac

