#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

ln -sf "$script_dir/.npmrc" "$HOME/.npmrc"

echo "👍 npm setting is done!"
