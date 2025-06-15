#!/bin/bash

# OpenVPN Flutter Project Build Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENVPN_DIR="${SCRIPT_DIR}/openvpn"

echo "🚀 Building OpenVPN Flutter Project"

show_usage() {
    echo "Usage: $0 [android|desktop|all] [--clean] [--deps-only]"
}

PLATFORM="$1"
if [ -z "$PLATFORM" ]; then
    show_usage
    exit 1
fi

echo "📦 Building dependencies for ${PLATFORM}..."

if [ "$PLATFORM" = "android" ]; then
    cd "${OPENVPN_DIR}"
    ./build_android.sh
elif [ "$PLATFORM" = "desktop" ]; then
    cd "${OPENVPN_DIR}"
    ./build_dependencies.sh
fi

echo "✅ Build completed!"
