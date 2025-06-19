#!/bin/bash

# macOS Developer Account Setup Script for OpenVPN Flutter App
# This script helps configure the project for your Apple Developer Account

set -e

echo "🍎 Setting up macOS OpenVPN with Apple Developer Account"
echo "======================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
echo "🔍 Checking required tools..."

if ! command_exists flutter; then
    echo "❌ Flutter not found. Please install Flutter and add it to PATH."
    exit 1
fi

if ! command_exists xcodebuild; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ All required tools found"

# Get user input for configuration
echo ""
echo "📝 Please provide your Apple Developer Account information:"
echo ""

read -p "Enter your Team ID (found in Apple Developer Account): " TEAM_ID
read -p "Enter your Bundle Identifier (e.g., com.bilinluo.fl-openvpn-client): " BUNDLE_ID
read -p "Enter your Organization Name (e.g., Bilin Luo): " ORG_NAME

if [ -z "$TEAM_ID" ] || [ -z "$BUNDLE_ID" ] || [ -z "$ORG_NAME" ]; then
    echo "❌ All fields are required. Please run the script again."
    exit 1
fi

echo ""
echo "🔧 Configuration Summary:"
echo "Team ID: $TEAM_ID"
echo "Bundle ID: $BUNDLE_ID"
echo "Organization: $ORG_NAME"
echo ""

read -p "Is this correct? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Setup cancelled. Please run the script again."
    exit 1
fi

# Update AppInfo.xcconfig
echo "📝 Updating AppInfo.xcconfig..."
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID/" macos/Runner/Configs/AppInfo.xcconfig
sed -i '' "s/Copyright © 2025 .*/Copyright © 2025 $ORG_NAME. All rights reserved./" macos/Runner/Configs/AppInfo.xcconfig

echo "✅ AppInfo.xcconfig updated"

# Update Xcode project with Team ID
echo "📝 Updating Xcode project with Team ID..."

# Create a temporary script to update the project file
cat > update_project.py << 'EOF'
import sys
import re

def update_project_file(file_path, team_id):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Add DEVELOPMENT_TEAM to build configurations
    patterns = [
        (r'(CODE_SIGN_STYLE = Automatic;)', r'\1\n\t\t\t\tDEVELOPMENT_TEAM = ' + team_id + ';'),
        (r'(CODE_SIGN_IDENTITY = "-";)', r'CODE_SIGN_IDENTITY = "Apple Development";'),
    ]
    
    for pattern, replacement in patterns:
        content = re.sub(pattern, replacement, content)
    
    with open(file_path, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    update_project_file(sys.argv[1], sys.argv[2])
EOF

python3 update_project.py macos/Runner.xcodeproj/project.pbxproj "$TEAM_ID"
rm update_project.py

echo "✅ Xcode project updated with Team ID"

# Clean and prepare for build
echo "🧹 Cleaning previous builds..."
flutter clean
cd macos && rm -rf build && cd ..

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "� Initializing Xcode build tools..."
echo "   Running xcodebuild -runFirstLaunch to fix plugin issues..."
sudo xcodebuild -runFirstLaunch

echo "�🔨 Building macOS app..."
flutter build macos --debug

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 macOS app built successfully!"
    echo ""
    echo "📱 Next Steps:"
    echo "1. Open Xcode: open macos/Runner.xcworkspace"
    echo "2. In Xcode, select your Team in Signing & Capabilities"
    echo "3. Verify the Bundle Identifier: $BUNDLE_ID"
    echo "4. Build and run from Xcode to test VPN functionality"
    echo ""
    echo "🔐 VPN Testing:"
    echo "- The app will request VPN permission on first connection"
    echo "- Allow VPN access in System Preferences when prompted"
    echo "- Test with a real OpenVPN configuration file"
    echo ""
    echo "⚠️  Important Notes:"
    echo "- VPN features require proper code signing with your developer certificate"
    echo "- The app must be signed and notarized for distribution"
    echo "- NetworkExtension entitlements are already configured"
    echo ""
else
    echo "❌ Build failed. Please check the errors above."
    echo ""
    echo "🔧 Troubleshooting:"
    echo "1. Ensure your Apple Developer Account is active"
    echo "2. Check that the Bundle ID is unique and available"
    echo "3. Verify Xcode is properly installed and updated"
    echo "4. Try opening the project in Xcode and building manually"
fi

echo ""
echo "📚 For more information, see:"
echo "- PLATFORM_BUILD_GUIDE.md (macOS section)"
echo "- Apple Developer Documentation on NetworkExtension"
echo ""
echo "🎯 Setup complete!"
