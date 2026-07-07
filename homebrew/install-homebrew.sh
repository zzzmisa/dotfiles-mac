#!/usr/bin/env zsh

# このスクリプトは他のinstallerからsourceされるため、
# 呼び出し元の script_dir を上書きしない変数名を使う
install_homebrew_dir="${0:A:h}"

# brewコマンドがない場合のみ
# Homebrewインストール
# cf. https://brew.sh/
if ! type brew > /dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" # .zprofileにも記載済み
  zsh "$install_homebrew_dir/../zsh/installer.sh"
fi
