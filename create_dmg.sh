#!/bin/bash

# Create DMG for macOS OpenVPN Client Distribution
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

echo "📦 Creating DMG for macOS OpenVPN Client"

# Build paths
APP_PATH="${PROJECT_ROOT}/build/macos/Build/Products/Release/fl_openvpn_client.app"
DMG_NAME="OpenVPN_Client_macOS"
DMG_PATH="${PROJECT_ROOT}/${DMG_NAME}.dmg"

# Verify app exists
if [ ! -d "${APP_PATH}" ]; then
    echo "❌ App not found at ${APP_PATH}"
    echo "Please run 'flutter build macos --release' first"
    exit 1
fi

# Remove existing DMG
if [ -f "${DMG_PATH}" ]; then
    echo "🗑️  Removing existing DMG..."
    rm -f "${DMG_PATH}"
fi

# Create temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)
echo "📁 Using temporary directory: ${TEMP_DIR}"

# Copy app to temp directory
echo "📋 Copying app to temporary directory..."
cp -R "${APP_PATH}" "${TEMP_DIR}/"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "${TEMP_DIR}/Applications"

# Get app size for DMG sizing
APP_SIZE=$(du -sm "${APP_PATH}" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))  # Add 50MB buffer

echo "📊 App size: ${APP_SIZE}MB, DMG size: ${DMG_SIZE}MB"

# Create DMG
echo "🔨 Creating DMG..."
hdiutil create -volname "OpenVPN Client" \
    -srcfolder "${TEMP_DIR}" \
    -ov -format UDZO \
    -size ${DMG_SIZE}m \
    "${DMG_PATH}"

# Clean up
echo "🧹 Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

# Verify DMG
if [ -f "${DMG_PATH}" ]; then
    DMG_ACTUAL_SIZE=$(du -sh "${DMG_PATH}" | cut -f1)
    echo ""
    echo "✅ DMG created successfully!"
    echo "📍 Location: ${DMG_PATH}"
    echo "📊 Size: ${DMG_ACTUAL_SIZE}"
    echo ""
    echo "🚀 Ready for distribution!"
    echo "   - Double-click to mount"
    echo "   - Drag app to Applications folder"
    echo "   - Eject when done"
else
    echo "❌ Failed to create DMG"
    exit 1
fi
