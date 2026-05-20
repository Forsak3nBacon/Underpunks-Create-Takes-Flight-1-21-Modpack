#!/usr/bin/env bash
# Build modpack artifacts: <slug>-<version>.mrpack and <slug>-<version>-server-files.zip
# Outputs to ./build/. Identical to what CI produces.
#
# Requires: packwiz CLI, java 21, curl, zip, rsync on PATH.

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
require rsync   "rsync is required"

VERSION=$(grep '^version = ' pack.toml | sed 's/version = "\(.*\)"/\1/')
SLUG=$(grep '^name = ' pack.toml | sed 's/name = "\(.*\)"/\1/' \
  | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//')

BUILD_DIR="$REPO_ROOT/build"
STAGING="$BUILD_DIR/pack-staging"
SERVER_DIR="$BUILD_DIR/server-files"
BOOTSTRAP="$BUILD_DIR/packwiz-installer-bootstrap.jar"
MRPACK="$BUILD_DIR/${SLUG}-${VERSION}.mrpack"
SERVER_ZIP="$BUILD_DIR/${SLUG}-${VERSION}-server-files.zip"

echo ">> Cleaning $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$SERVER_DIR" "$STAGING"

# Copy the pack into a staging dir so we can mutate .pw.toml sides for the
# build WITHOUT touching the repo. Future `packwiz update` runs against the
# real repo won't conflict with our build-time overrides.
echo ">> Staging pack copy"
rsync -a \
  --exclude='/build/' \
  --exclude='/.git/' \
  --exclude='/.claude/' \
  --exclude='/scripts/' \
  --exclude='/.github/' \
  --exclude='/.githooks/' \
  "$REPO_ROOT/" "$STAGING/"

# Singleplayer support: a client running singleplayer launches an integrated
# server in the same JVM, so it needs every mod that the dedicated server has.
# Flip side="server" -> side="both" in staging so the .mrpack marks those mods
# as required on the client. The dedicated server build still gets them
# (packwiz-installer -s server includes side=server AND side=both).
# side="client" is left alone: those mods crash on a dedicated server.
echo ">> Flipping side=server -> side=both in staging (client install gets everything)"
FLIPPED=$(grep -lE '^side = "server"$' "$STAGING/mods"/*.pw.toml 2>/dev/null | wc -l | tr -d ' ')
find "$STAGING/mods" -name "*.pw.toml" -print0 \
  | xargs -0 sed -i.bak 's/^side = "server"$/side = "both"/'
find "$STAGING/mods" -name "*.pw.toml.bak" -delete
echo "   flipped $FLIPPED mods"

echo ">> packwiz refresh (in staging)"
( cd "$STAGING" && packwiz refresh )

echo ">> Exporting .mrpack from staging"
( cd "$STAGING" && packwiz mr export -o "$MRPACK" )

echo ">> Fetching packwiz-installer-bootstrap"
curl -fsSL -o "$BOOTSTRAP" \
  https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar

echo ">> Building server files from staging (side=server, mods + config + kubejs)"
( cd "$SERVER_DIR" && java -jar "$BOOTSTRAP" -g -s server "$STAGING/pack.toml" )

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
