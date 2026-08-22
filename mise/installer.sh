#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
source "$script_dir/../lib/environment.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

config_dir="$HOME/.config/mise"
conf_dir="$config_dir/conf.d"
config_file="$config_dir/config.toml"
environment_config_file="$conf_dir/environment.toml"
legacy_mise_toml_file="$config_dir/mise.toml"

if ! type mise > /dev/null 2>&1; then
  echo "mise is not installed. Run homebrew/installer.sh first."
  exit 1
fi

mkdir -p "$conf_dir"
ln -sf "$script_dir/mise.toml" "$config_file"

if [[ "$DOTFILES_ENV" = "office" ]]; then
  environment_config="$script_dir/mise.office.toml"
else
  environment_config="$script_dir/mise.private.toml"
fi
ln -sf "$environment_config" "$environment_config_file"

# 以前のインストーラが作成した重複リンクだけを削除する。
if [[ -L "$legacy_mise_toml_file" ]] &&
  [[ "$(readlink "$legacy_mise_toml_file")" = "$script_dir/mise.toml" ]]; then
  unlink "$legacy_mise_toml_file"
fi

echo "Trusting mise config"
mise trust "$script_dir/mise.toml"
mise trust "$environment_config"
mise trust "$config_file"
mise trust "$environment_config_file"

echo "Installing mise tools"
mise install -C "$HOME" -y

echo "👍 mise setting is done!"
