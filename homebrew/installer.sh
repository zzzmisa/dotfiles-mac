#!/usr/bin/env zsh
set -e
# Homebrewインストール
source homebrew/install-homebrew.sh

# Rosettaインストール
softwareupdate --install-rosetta

# Brewfile実行
printf "Press O for office use, press any key for private use :  "
read install_env
cd $PWD/homebrew
if [ "$install_env" = "O" ]; then
  brew bundle --file BrewfileOffice
else
  brew bundle --file BrewfilePrivate
fi
cd -

echo 👍 Homebrew setting is done!