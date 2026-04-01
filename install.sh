#!/usr/bin/env bash
set -e

# ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

TARGET_PATH='export PATH="$HOME/.local/bin:$PATH"'

# detect shell config file (macOS defaults to zsh)
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
  RC_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
  RC_FILE="$HOME/.bashrc"
else
  RC_FILE="$HOME/.profile"
fi

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo "$TARGET_PATH" >> "$RC_FILE"
  echo "Added ~/.local/bin to PATH in $RC_FILE"
fi

# apply
export PATH="$HOME/.local/bin:$PATH"

# finally, install tool 
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
