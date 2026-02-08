#!/bin/bash

# Generate Xcode project for BrowserCat

set -e

echo "=== BrowserCat Project Generator ==="
echo ""

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing via Homebrew..."
    brew install xcodegen
fi

# Generate project
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Project generated successfully!"
echo ""
echo "Next steps:"
echo "1. Open BrowserCat.xcodeproj in Xcode"
echo "2. Set your Development Team in Signing & Capabilities"
echo "3. Build and run (Cmd+R)"
echo ""
echo "To open the project:"
echo "  open BrowserCat.xcodeproj"
