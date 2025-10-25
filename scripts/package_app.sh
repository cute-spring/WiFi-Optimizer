#!/usr/bin/env bash
set -euo pipefail

# WiFi-Optimizer: package wifiopt-app into a .app bundle with Info.plist,
# reset Core Location consent, open Location Services settings, and launch the app.

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
APP_NAME="wifiopt-app"
BUILD_DIR="$ROOT_DIR/.build/debug"
BIN_PATH="$BUILD_DIR/$APP_NAME"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RES_DIR="$CONTENTS_DIR/Resources"
SRC_PLIST="$ROOT_DIR/Sources/wifiopt-app/Info.plist"

DEBUG_MODE="0"
if [[ "${1:-}" == "--debug" ]]; then
  DEBUG_MODE="1"
  echo "[0/6] Debug mode enabled (WIFIOPT_DEBUG=1)"
fi

echo "[1/6] Building $APP_NAME (debug) ..."
swift build -c debug

if [[ ! -x "$BIN_PATH" ]]; then
  echo "Error: built binary not found at $BIN_PATH" >&2
  exit 1
fi

echo "[2/6] Preparing .app bundle directories ..."
mkdir -p "$MACOS_DIR" "$RES_DIR"

echo "[3/6] Copying executable into .app bundle ..."
cp "$BIN_PATH" "$MACOS_DIR/"

# Read bundle id and usage description from source Info.plist if available
DEFAULT_BUNDLE_ID="com.gavinzhang.wifiopt-app"
DEFAULT_USAGE="Needed to analyze nearby Wi‑Fi networks."

read_plist_key() {
  local key=$1
  local file=$2
  /usr/libexec/PlistBuddy -c "Print ${key}" "$file" 2>/dev/null || true
}

BUNDLE_ID="${DEFAULT_BUNDLE_ID}"
USAGE_DESC="${DEFAULT_USAGE}"

if [[ -f "$SRC_PLIST" ]]; then
  BID_FROM_SRC="$(read_plist_key CFBundleIdentifier "$SRC_PLIST")"
  USAGE_FROM_SRC="$(read_plist_key NSLocationWhenInUseUsageDescription "$SRC_PLIST")"
  if [[ -n "${BID_FROM_SRC}" ]]; then BUNDLE_ID="${BID_FROM_SRC}"; fi
  if [[ -n "${USAGE_FROM_SRC}" ]]; then USAGE_DESC="${USAGE_FROM_SRC}"; fi
  APP_VERSION="$(read_plist_key CFBundleShortVersionString "$SRC_PLIST")"
  BUILD_NUMBER="$(read_plist_key CFBundleVersion "$SRC_PLIST")"
fi

echo "[4/6] Writing Info.plist into .app ..."
cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION:-1.0}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER:-1}</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>${USAGE_DESC}</string>
$(
  if [[ "$DEBUG_MODE" == "1" ]]; then
    cat <<DBG
  <key>LSEnvironment</key>
  <dict>
    <key>WIFIOPT_DEBUG</key>
    <string>1</string>
  </dict>
DBG
  fi
)
</dict>
</plist>
PLIST

plutil -convert xml1 "$CONTENTS_DIR/Info.plist"

echo "[5/6] Resetting Core Location consent for bundle id: ${BUNDLE_ID} ..."
if ! tccutil reset Location "$BUNDLE_ID"; then
  echo "Note: per-app reset failed; you can also run 'tccutil reset Location' for global reset." >&2
fi

echo "[6/6] Opening Location Services settings and launching the app ..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices" || true
open "$APP_BUNDLE"

echo "Done. If no prompt appears, ensure system-level Location Services is ON,\n\
and that the app calls requestWhenInUseAuthorization at runtime (see Sources/wifiopt-app/LocationPermission.swift)."