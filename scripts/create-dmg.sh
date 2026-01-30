#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking dependencies...${NC}"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${RED}❌ create-dmg not found!${NC}"
    echo -e "${YELLOW}Installing via Homebrew...${NC}"
    brew install create-dmg
fi

echo -e "${GREEN}✅ All dependencies installed${NC}"

# Navigate to project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Get current version from Xcode project
VERSION=$(grep -m 1 "MARKETING_VERSION" Nag.xcodeproj/project.pbxproj | awk -F' = ' '{print $2}' | tr -d ';' | tr -d ' ')
VERSION=${VERSION:-"1.0.0"}
echo -e "${BLUE}📌 Version: ${VERSION}${NC}"

# Build with xcodebuild if available
if command -v xcodebuild &> /dev/null && xcodebuild -version &> /dev/null; then
    echo -e "${BLUE}🔨 Building Release version...${NC}"
    
    xcodebuild clean build \
        -project Nag.xcodeproj \
        -scheme Nag \
        -configuration Release \
        -quiet || {
            echo -e "${YELLOW}⚠️  xcodebuild failed, looking for existing build...${NC}"
        }
else
    echo -e "${YELLOW}⚠️  xcodebuild not available. Using existing build...${NC}"
    echo -e "${YELLOW}Make sure to build in Xcode first (Cmd+B)${NC}"
fi

# Find the built app (prefer Release, fallback to Debug)
echo -e "${BLUE}🔍 Looking for built app...${NC}"

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Nag.app" -type d 2>/dev/null | \
    while read app; do
        size=$(du -sk "$app" 2>/dev/null | cut -f1)
        if [ "$size" -gt 10 ]; then
            # Prefer Release builds
            if [[ "$app" == *"/Release/"* ]]; then
                echo "9999999 $app"
            else
                echo "$size $app"
            fi
        fi
    done | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ No valid build found!${NC}"
    echo -e "${YELLOW}Build the project in Xcode first (Cmd+B)${NC}"
    exit 1
fi

BUILD_TYPE=$(basename $(dirname "$APP_PATH"))
echo -e "${GREEN}✅ Found: ${BUILD_TYPE} build${NC}"

# Output DMG name
DMG_NAME="Nag-${VERSION}.dmg"
OUTPUT_PATH="${PROJECT_ROOT}/${DMG_NAME}"

# Remove old DMG if exists
if [ -f "$OUTPUT_PATH" ]; then
    echo -e "${BLUE}🗑️  Removing old DMG...${NC}"
    rm -f "$OUTPUT_PATH"
fi

echo -e "${BLUE}📦 Creating DMG: ${DMG_NAME}${NC}"

# Create DMG with horizontally aligned icons
create-dmg \
  --volname "Nag Installer" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 160 \
  --icon "Nag.app" 180 170 \
  --hide-extension "Nag.app" \
  --app-drop-link 480 170 \
  --hdiutil-quiet \
  "$OUTPUT_PATH" \
  "$APP_PATH" 2>&1 | grep -v "execution error" || true

if [ -f "$OUTPUT_PATH" ]; then
    echo -e "${GREEN}✅ DMG created successfully!${NC}"
    echo -e "${GREEN}📍 Location: $OUTPUT_PATH${NC}"
    
    # Show file size
    SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
    echo -e "${GREEN}📊 Size: ${SIZE}${NC}"
    echo -e "${GREEN}🏷️  Version: ${VERSION}${NC}"
    
    # Open folder
    open "$PROJECT_ROOT"
else
    echo -e "${RED}❌ Failed to create DMG${NC}"
    exit 1
fi
