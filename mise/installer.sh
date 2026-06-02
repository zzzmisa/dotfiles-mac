#!/usr/bin/env zsh
set -e

SCRIPT_DIR="${0:A:h}"
CONFIG_DIR="$HOME/.config/mise"
CONFIG_FILE="$CONFIG_DIR/config.toml"
MISE_TOML_FILE="$CONFIG_DIR/mise.toml"

if ! type mise > /dev/null 2>&1; then
  echo "mise is not installed. Run homebrew/installer.sh first."
  exit 1
fi

mkdir -p "$CONFIG_DIR"
ln -sf "$SCRIPT_DIR/mise.toml" "$CONFIG_FILE"
ln -sf "$SCRIPT_DIR/mise.toml" "$MISE_TOML_FILE"

echo "Trusting mise config"
mise trust "$SCRIPT_DIR/mise.toml"
mise trust "$CONFIG_FILE"
mise trust "$MISE_TOML_FILE"

echo "Installing mise tools"
mise install -C "$SCRIPT_DIR" -y

echo "👍 mise setting is done!"
