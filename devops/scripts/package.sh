#!/usr/bin/env bash
set -euo pipefail

# package.sh - Build and package bone macOS app
# Usage: ./package.sh [--dmg|--pkg|--all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/.build"
RELEASE_DIR="${BUILD_DIR}/release"
PACKAGE_DIR="${BUILD_DIR}/package"
APP_NAME="bone"
BUNDLE_ID="com.bingtong.bone"
APP_BUNDLE="${PACKAGE_DIR}/${APP_NAME}.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
BUILD_DMG=false
BUILD_PKG=false

if [[ $# -eq 0 ]]; then
    # Default: build app bundle only
    :
elif [[ "$1" == "--dmg" ]]; then
    BUILD_DMG=true
elif [[ "$1" == "--pkg" ]]; then
    BUILD_PKG=true
elif [[ "$1" == "--all" ]]; then
    BUILD_DMG=true
    BUILD_PKG=true
else
    echo "Usage: $0 [--dmg|--pkg|--all]"
    exit 1
fi

# Step 1: Clean and build release binary
log_info "Building release binary..."
cd "${PROJECT_ROOT}"
rm -rf "${RELEASE_DIR}"
swift build -c release 2>&1 | tee "${BUILD_DIR}/build.log"

BINARY_PATH="${BUILD_DIR}/release/${APP_NAME}"
if [[ ! -f "${BINARY_PATH}" ]]; then
    log_error "Release binary not found at ${BINARY_PATH}"
    exit 1
fi

# Step 2: Create .app bundle structure
log_info "Creating .app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BINARY_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Step 3: Generate Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

log_info "Info.plist generated"

# Step 4: Build AppIcon.icns from PNGs
ICONSET_DIR="${BUILD_DIR}/AppIcon.iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

# Copy PNGs with iconutil naming convention
if [[ -f "${PROJECT_ROOT}/Resources/AppIcon_16.png" ]]; then
    cp "${PROJECT_ROOT}/Resources/AppIcon_16.png" "${ICONSET_DIR}/icon_16x16.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_32.png" "${ICONSET_DIR}/icon_16x16@2x.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_32.png" "${ICONSET_DIR}/icon_32x32.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_64.png" "${ICONSET_DIR}/icon_32x32@2x.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_128.png" "${ICONSET_DIR}/icon_128x128.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_256.png" "${ICONSET_DIR}/icon_128x128@2x.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_256.png" "${ICONSET_DIR}/icon_256x256.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_512.png" "${ICONSET_DIR}/icon_256x256@2x.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_512.png" "${ICONSET_DIR}/icon_512x512.png"
    cp "${PROJECT_ROOT}/Resources/AppIcon_1024.png" "${ICONSET_DIR}/icon_512x512@2x.png"

    iconutil -c icns "${ICONSET_DIR}" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    log_info "AppIcon.icns created"
else
    log_warn "AppIcon PNGs not found, app will use default icon"
fi
rm -rf "${ICONSET_DIR}"

# Copy status bar icons into app bundle
if [[ -d "${PROJECT_ROOT}/Resources/StatusBarIcon.imageset" ]]; then
    cp -R "${PROJECT_ROOT}/Resources/StatusBarIcon.imageset" "${APP_BUNDLE}/Contents/Resources/"
    log_info "Status bar icons copied"
fi

# Step 5: Verify bundle
log_info "Verifying bundle structure..."
if [[ -x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" ]]; then
    log_info "✓ Binary is executable"
else
    log_error "✗ Binary is not executable"
    exit 1
fi

if [[ -f "${APP_BUNDLE}/Contents/Info.plist" ]]; then
    log_info "✓ Info.plist exists"
else
    log_error "✗ Info.plist missing"
    exit 1
fi

log_info "App bundle created at: ${APP_BUNDLE}"

# Step 6: Create .dmg if requested
if [[ "$BUILD_DMG" == true ]]; then
    DMG_NAME="${PACKAGE_DIR}/${APP_NAME}-1.0.0.dmg"
    TEMP_DMG_DIR="${PACKAGE_DIR}/.dmg_staging"

    log_info "Creating DMG..."
    rm -rf "${TEMP_DMG_DIR}" "${DMG_NAME}"
    mkdir -p "${TEMP_DMG_DIR}"

    # Copy app bundle to staging
    cp -R "${APP_BUNDLE}" "${TEMP_DMG_DIR}/"

    # Create a symlink to /Applications for drag-and-drop install
    ln -s /Applications "${TEMP_DMG_DIR}/Applications"

    # Create the DMG
    hdiutil create \
        -srcfolder "${TEMP_DMG_DIR}" \
        -volname "${APP_NAME}" \
        -fs HFS+ \
        -format UDZO \
        -o "${DMG_NAME}" \
        2>&1 | tee "${BUILD_DIR}/dmg.log"

    # Clean up staging
    rm -rf "${TEMP_DMG_DIR}"

    if [[ -f "${DMG_NAME}" ]]; then
        log_info "DMG created at: ${DMG_NAME}"
    else
        log_error "DMG creation failed"
        exit 1
    fi
fi

# Step 7: Create .pkg installer if requested
if [[ "$BUILD_PKG" == true ]]; then
    PKG_NAME="${PACKAGE_DIR}/${APP_NAME}-1.0.0.pkg"
    PKG_ROOT="${PACKAGE_DIR}/.pkg_root"

    log_info "Creating PKG installer..."
    rm -rf "${PKG_ROOT}" "${PKG_NAME}"
    mkdir -p "${PKG_ROOT}/Applications"

    # Copy app to pkg root
    cp -R "${APP_BUNDLE}" "${PKG_ROOT}/Applications/"

    # Build the package
    pkgbuild \
        --root "${PKG_ROOT}" \
        --identifier "${BUNDLE_ID}" \
        --version "1.0.0" \
        --install-location "/Applications" \
        "${PKG_NAME}" \
        2>&1 | tee "${BUILD_DIR}/pkg.log"

    # Clean up
    rm -rf "${PKG_ROOT}"

    if [[ -f "${PKG_NAME}" ]]; then
        log_info "PKG created at: ${PKG_NAME}"
    else
        log_error "PKG creation failed"
        exit 1
    fi
fi

# Summary
log_info "Packaging complete!"
echo ""
echo "Output files:"
find "${PACKAGE_DIR}" -maxdepth 1 -type f -o -maxdepth 1 -type d | sort | while read -r f; do
    if [[ "$f" != *.log ]]; then
        size=$(du -sh "$f" 2>/dev/null | cut -f1)
        echo "  $(basename "$f") (${size})"
    fi
done
