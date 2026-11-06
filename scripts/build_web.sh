#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Stark Group VMS - Flutter Web Production Build Script for Netlify
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================================"
echo " Starting Stark Group VMS Web Production Build"
echo "========================================================"

# ------------------------------------------------------------------------------
# 1. Validate Production API_BASE_URL
# ------------------------------------------------------------------------------
API_BASE_URL="${API_BASE_URL:-}"

if [ -z "${API_BASE_URL}" ]; then
  echo "[-] ERROR: API_BASE_URL environment variable is required."
  echo "    Please set API_BASE_URL in your Netlify Build Environment variables."
  echo "    Example: API_BASE_URL=https://api.vms.starkgroup.test"
  exit 1
fi

# Reject localhost in production builds unless explicitly overridden for testing
if [[ "${API_BASE_URL}" =~ localhost|127\.0\.0\.1 ]] && [ "${ALLOW_LOCALHOST:-0}" != "1" ]; then
  echo "[-] ERROR: API_BASE_URL cannot point to localhost in production: '${API_BASE_URL}'"
  echo "    Use a valid public HTTPS origin for production."
  exit 1
fi

# Validate URL scheme
if [[ ! "${API_BASE_URL}" =~ ^https?:// ]]; then
  echo "[-] ERROR: API_BASE_URL must include a valid HTTP or HTTPS scheme: '${API_BASE_URL}'"
  exit 1
fi

# Strip trailing slashes
API_BASE_URL="${API_BASE_URL%/}"
echo "[+] Target backend API_BASE_URL: ${API_BASE_URL}"

# ------------------------------------------------------------------------------
# 2. Pinned Flutter SDK Setup
# ------------------------------------------------------------------------------
FLUTTER_VERSION="3.47.5"
FLUTTER_CHANNEL="stable"
SDK_DIR="${PROJECT_ROOT}/.flutter-sdk"

# Check if flutter is already installed on host and matches pinned version
HAVE_FLUTTER=0
if command -v flutter >/dev/null 2>&1; then
  CURRENT_VERSION=$(flutter --version 2>&1 | head -n 1 | awk '{print $2}')
  if [ "${CURRENT_VERSION}" = "${FLUTTER_VERSION}" ]; then
    echo "[+] Using host Flutter SDK version ${CURRENT_VERSION}"
    HAVE_FLUTTER=1
  else
    echo "[*] Host Flutter version (${CURRENT_VERSION}) differs from pinned version (${FLUTTER_VERSION})."
  fi
fi

if [ "${HAVE_FLUTTER}" -eq 0 ]; then
  if [ -d "${SDK_DIR}/flutter/bin" ]; then
    export PATH="${SDK_DIR}/flutter/bin:${PATH}"
    INSTALLED_VER=$(flutter --version 2>&1 | head -n 1 | awk '{print $2}')
    if [ "${INSTALLED_VER}" = "${FLUTTER_VERSION}" ]; then
      echo "[+] Cached Flutter SDK ${INSTALLED_VER} found in ${SDK_DIR}."
      HAVE_FLUTTER=1
    else
      echo "[*] Cached SDK version mismatch. Re-downloading pinned SDK."
      rm -rf "${SDK_DIR}"
    fi
  fi
fi

if [ "${HAVE_FLUTTER}" -eq 0 ]; then
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  echo "[*] Setting up pinned Flutter ${FLUTTER_VERSION} for OS=${OS}, ARCH=${ARCH}..."

  if [ "${OS}" != "Linux" ]; then
    echo "[-] Automated Flutter SDK download is configured for Linux CI (Netlify)."
    echo "    On local development machines (${OS}), please install Flutter ${FLUTTER_VERSION} via your local SDK manager."
    exit 1
  fi

  if [ "${ARCH}" != "x86_64" ]; then
    echo "[-] Unsupported build architecture: ${ARCH}. Expected x86_64 for Linux."
    exit 1
  fi

  FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
  FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"
  EXPECTED_SHA256="2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb"

  mkdir -p "${SDK_DIR}"
  ARCHIVE_PATH="${SDK_DIR}/${FLUTTER_ARCHIVE}"

  echo "[*] Downloading official Flutter SDK archive from ${FLUTTER_URL}..."
  curl -sSL --retry 3 --fail -o "${ARCHIVE_PATH}" "${FLUTTER_URL}"

  echo "[*] Verifying SHA256 checksum..."
  ACTUAL_SHA256=$(sha256sum "${ARCHIVE_PATH}" | awk '{print $1}')
  if [ "${ACTUAL_SHA256}" != "${EXPECTED_SHA256}" ]; then
    echo "[-] ERROR: Checksum verification failed!"
    echo "    Expected: ${EXPECTED_SHA256}"
    echo "    Actual:   ${ACTUAL_SHA256}"
    rm -rf "${SDK_DIR}"
    exit 1
  fi
  echo "[+] Checksum verified successfully."

  echo "[*] Extracting Flutter SDK..."
  tar -xf "${ARCHIVE_PATH}" -C "${SDK_DIR}"
  rm -f "${ARCHIVE_PATH}"

  export PATH="${SDK_DIR}/flutter/bin:${PATH}"
fi

# Ensure git safe directory for Flutter SDK in containerized CI
git config --global --add safe.directory "${SDK_DIR}/flutter" 2>/dev/null || true

echo "[+] Active Flutter environment:"
flutter --version

# ------------------------------------------------------------------------------
# 3. Resolve Dependencies
# ------------------------------------------------------------------------------
echo "[*] Resolving Dart/Flutter dependencies..."
flutter pub get

# ------------------------------------------------------------------------------
# 4. Compile Production Web Release
# ------------------------------------------------------------------------------
echo "[*] Building Flutter Web production release bundle..."
flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL="${API_BASE_URL}"

# ------------------------------------------------------------------------------
# 5. Assemble the Next.js landing page and Flutter workspace
# ------------------------------------------------------------------------------
if [ ! -f "build/web/index.html" ]; then
  echo "[-] ERROR: Build output missing build/web/index.html!"
  exit 1
fi

echo "[*] Building the landing page..."
npm --prefix landing ci
npm --prefix landing run build

# Keep the Flutter entry point on the same origin for hash routes and session storage.
cp build/web/index.html build/web/workspace.html
cp -R landing/out/. build/web/

echo "========================================================"
echo " Web build succeeded!"
echo " Publish Directory: build/web"
echo " Target API_BASE_URL: ${API_BASE_URL}"
echo "========================================================"
