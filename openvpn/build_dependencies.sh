#!/bin/bash

# OpenVPN Dependencies Build Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
DEPS_DIR="${BUILD_DIR}/deps"
INSTALL_DIR="${BUILD_DIR}/install"

echo "🚀 Building OpenVPN dependencies"
mkdir -p "${BUILD_DIR}" "${DEPS_DIR}" "${INSTALL_DIR}"

clone_or_update() {
    local repo_url="$1"
    local repo_name="$2"
    local commit_hash="$3"

    echo "📥 Cloning/updating ${repo_name} to commit ${commit_hash}..."
    if [ -d "${DEPS_DIR}/${repo_name}" ]; then
        cd "${DEPS_DIR}/${repo_name}"
        git fetch origin
        git checkout "${commit_hash}"
    else
        cd "${DEPS_DIR}"
        git clone "${repo_url}" "${repo_name}"
        cd "${repo_name}"
        git checkout "${commit_hash}"
    fi
}

# Clone dependencies with pinned stable versions
# Using specific commit hashes for reproducible builds

# ASIO 1.30.2 (stable release)
clone_or_update "https://github.com/chriskohlhoff/asio.git" "asio" "asio-1-30-2"

# fmt 11.0.2 (latest stable release)
clone_or_update "https://github.com/fmtlib/fmt.git" "fmt" "11.0.2"

# LZ4 1.10.0 (latest stable release)
clone_or_update "https://github.com/lz4/lz4.git" "lz4" "v1.10.0"

# OpenSSL 3.3.2 (latest stable LTS release)
clone_or_update "https://github.com/openssl/openssl.git" "openssl" "openssl-3.3.2"

# OpenVPN3 Core (latest stable release 3.11.1)
clone_or_update "https://github.com/OpenVPN/openvpn3.git" "openvpn3-core" "release/3.11.1"

echo "✅ All dependencies ready!"
