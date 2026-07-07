#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
mise_dir="$script_dir/../mise"

if ! type mise > /dev/null 2>&1; then
  echo "mise is not installed. Run homebrew/installer.sh and mise/installer.sh first."
  exit 1
fi

ln -sf "$script_dir/.npmrc" "$HOME/.npmrc"

echo "Installing node global packages"
mise exec -C "$mise_dir" -- npm install --global textlint snyk

echo "👍 npm setting is done!"
