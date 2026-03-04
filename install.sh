#!/usr/bin/env bash
set -e

echo "Installing path..."
SCRIPT_URL="https://raw.githubusercontent.com/sophb-ccjt/path-cli/main/path.sh"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/path"

mkdir -p "$INSTALL_DIR"

echo
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "path installed to $INSTALL_PATH"
echo "Make sure $INSTALL_DIR is in your PATH."
