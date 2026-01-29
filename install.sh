#!/bin/bash
# ClaudeAutoAllow Installer
# Usage: curl -sL https://raw.githubusercontent.com/mattbeane/ClaudeAutoAllow/main/install.sh | bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║       Claude Auto-Allow Installer         ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# Check for Hammerspoon
if ! command -v hs &> /dev/null; then
    echo -e "${YELLOW}Hammerspoon not found.${NC}"

    if command -v brew &> /dev/null; then
        echo "Installing via Homebrew..."
        brew install --cask hammerspoon
    else
        echo -e "${RED}Please install Hammerspoon first:${NC}"
        echo "  brew install --cask hammerspoon"
        echo "  or download from https://www.hammerspoon.org/"
        exit 1
    fi
fi

# Create Spoons directory
SPOONS_DIR="$HOME/.hammerspoon/Spoons"
mkdir -p "$SPOONS_DIR"

# Download or copy spoon
SPOON_DIR="$SPOONS_DIR/ClaudeAutoAllow.spoon"

if [ -d "$SPOON_DIR" ]; then
    echo -e "${YELLOW}Existing installation found. Updating...${NC}"
    rm -rf "$SPOON_DIR"
fi

# If running from local (for development)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/init.lua" ]; then
    echo "Installing from local directory..."
    cp -r "$SCRIPT_DIR" "$SPOON_DIR"
else
    # Download from GitHub
    echo "Downloading ClaudeAutoAllow..."
    TEMP_DIR=$(mktemp -d)
    curl -sL "https://github.com/mattbeane/ClaudeAutoAllow/archive/main.zip" -o "$TEMP_DIR/spoon.zip"
    unzip -q "$TEMP_DIR/spoon.zip" -d "$TEMP_DIR"
    mv "$TEMP_DIR/ClaudeAutoAllow-main/ClaudeAutoAllow.spoon" "$SPOON_DIR"
    rm -rf "$TEMP_DIR"
fi

echo -e "${GREEN}✓ Spoon installed to $SPOON_DIR${NC}"

# Update init.lua
INIT_FILE="$HOME/.hammerspoon/init.lua"
LOAD_LINE='hs.loadSpoon("ClaudeAutoAllow"):start()'

if [ -f "$INIT_FILE" ]; then
    if grep -q "ClaudeAutoAllow" "$INIT_FILE"; then
        echo -e "${YELLOW}ClaudeAutoAllow already in init.lua${NC}"
    else
        echo "" >> "$INIT_FILE"
        echo "-- Claude Auto-Allow: auto-click permission prompts" >> "$INIT_FILE"
        echo "$LOAD_LINE" >> "$INIT_FILE"
        echo -e "${GREEN}✓ Added to init.lua${NC}"
    fi
else
    echo "-- Hammerspoon config" > "$INIT_FILE"
    echo "" >> "$INIT_FILE"
    echo "-- Claude Auto-Allow: auto-click permission prompts" >> "$INIT_FILE"
    echo "$LOAD_LINE" >> "$INIT_FILE"
    echo -e "${GREEN}✓ Created init.lua${NC}"
fi

# Start/reload Hammerspoon
echo ""
if pgrep -x "Hammerspoon" > /dev/null; then
    echo "Reloading Hammerspoon..."
    hs -c "hs.reload()" 2>/dev/null || true
else
    echo "Starting Hammerspoon..."
    open -a Hammerspoon
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Installation Complete!           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo "NEXT STEPS:"
echo "  1. Grant Accessibility permissions when prompted"
echo "     (System Settings → Privacy → Accessibility)"
echo ""
echo "  2. Look for ⚡ in your menubar"
echo ""
echo "  3. Try Claude Code - permissions should auto-allow!"
echo ""
echo "Optional: Add a hotkey to toggle in ~/.hammerspoon/init.lua:"
echo '  spoon.ClaudeAutoAllow:bindHotkeys({toggle = {{"cmd", "shift"}, "A"}})'
echo ""
