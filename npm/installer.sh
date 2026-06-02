#!/usr/bin/env zsh
set -e

SCRIPT_DIR="${0:A:h}"
MISE_DIR="$SCRIPT_DIR/../mise"

if ! type mise > /dev/null 2>&1; then
  echo "mise is not installed. Run homebrew/installer.sh and mise/installer.sh first."
  exit 1
fi

ln -sf "$SCRIPT_DIR/.npmrc" "$HOME/.npmrc"

echo "Installing node global packages"
mise exec -C "$MISE_DIR" -- npm install --global textlint snyk

echo "👍 npm setting is done!"
