#!/usr/bin/env bash

SCRIPT_URL="https://raw.githubusercontent.com/sophb-ccjt/path-cli/main/path.sh"
mkdir -p "$HOME/.local/bin"
curl -fsSL "$SCRIPT_URL" -o "$HOME/.local/bin/path" && chmod +x "$HOME/.local/bin/path"
echo "path CLI installed successfully!!"
echo "you can now use the 'path' command to manage your PATH environment variable."
