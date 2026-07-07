#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# Homebrewインストール
source "$script_dir/install-homebrew.sh"

# Rosettaインストール
softwareupdate --install-rosetta

# Brewfile実行
printf "Press O for office use, press any key for private use :  "
read install_env
if [ "$install_env" = "O" ]; then
  brew bundle --file "$script_dir/BrewfileOffice"
else
  brew bundle --file "$script_dir/BrewfilePrivate"
fi

echo 👍 Homebrew setting is done!
