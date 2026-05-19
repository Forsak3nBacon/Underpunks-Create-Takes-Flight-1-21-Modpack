#!/usr/bin/env bash
# Build modpack artifacts: <slug>-<version>.mrpack and <slug>-<version>-server-files.zip
# Outputs to ./build/. Identical to what CI produces.
#
# Requires: packwiz CLI, java 21, curl, zip on PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 not on PATH. $2" >&2; exit 1; }
}
require packwiz "Install with: go install github.com/packwiz/packwiz@latest"
require java    "Install Temurin 21: https://adoptium.net/temurin/releases/?version=21"
require curl    "curl is required"
require zip     "zip is required"

VERSION=$(grep '^version = ' pack.toml | sed 's/version = "\(.*\)"/\1/')
SLUG=$(grep '^name = ' pack.toml | sed 's/name = "\(.*\)"/\1/' \
  | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//')

BUILD_DIR="$REPO_ROOT/build"
SERVER_DIR="$BUILD_DIR/server-files"
BOOTSTRAP="$BUILD_DIR/packwiz-installer-bootstrap.jar"
MRPACK="$BUILD_DIR/${SLUG}-${VERSION}.mrpack"
SERVER_ZIP="$BUILD_DIR/${SLUG}-${VERSION}-server-files.zip"

echo ">> Cleaning $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$SERVER_DIR"

echo ">> packwiz refresh"
packwiz refresh

echo ">> Exporting .mrpack"
packwiz mr export -o "$MRPACK"

echo ">> Fetching packwiz-installer-bootstrap"
curl -fsSL -o "$BOOTSTRAP" \
  https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar

echo ">> Building server files (side=server, mods + config + kubejs)"
( cd "$SERVER_DIR" && java -jar "$BOOTSTRAP" -g -s server "$REPO_ROOT/pack.toml" )

# Strip installer bookkeeping so the zip is pure user-facing files.
# packwiz-installer-bootstrap downloads packwiz-installer.jar into CWD and
# writes packwiz.json as its local state — neither belongs on a server.
rm -f "$SERVER_DIR/packwiz.json" "$SERVER_DIR/packwiz-installer.jar"

echo ">> Zipping server files"
( cd "$SERVER_DIR" && zip -rq "$SERVER_ZIP" . )

SERVER_MODS=$(ls "$SERVER_DIR/mods" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Build complete:"
echo "  mrpack:        $MRPACK"
echo "  server zip:    $SERVER_ZIP"
echo "  server mods:   $SERVER_MODS"
