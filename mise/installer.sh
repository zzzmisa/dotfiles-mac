#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
config_dir="$HOME/.config/mise"
config_file="$config_dir/config.toml"
mise_toml_file="$config_dir/mise.toml"

if ! type mise > /dev/null 2>&1; then
  echo "mise is not installed. Run homebrew/installer.sh first."
  exit 1
fi

mkdir -p "$config_dir"
ln -sf "$script_dir/mise.toml" "$config_file"
ln -sf "$script_dir/mise.toml" "$mise_toml_file"

echo "Trusting mise config"
mise trust "$script_dir/mise.toml"
mise trust "$config_file"
mise trust "$mise_toml_file"

echo "Installing mise tools"
mise install -C "$script_dir" -y

echo "👍 mise setting is done!"
