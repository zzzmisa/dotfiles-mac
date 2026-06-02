#!/usr/bin/env bash
set -e

# Uninstall nodenv, pyenv, rbenv managed by Homebrew

echo "Uninstalling nodenv, pyenv, rbenv..."

# Remove Homebrew packages
brew uninstall nodenv
brew uninstall pyenv
brew uninstall rbenv

# Clean up cache files
echo "Cleaning up cache directories..."
rm -rf ~/.nodenv
rm -rf ~/.pyenv
rm -rf ~/.rbenv

echo "✅ Uninstall complete"
