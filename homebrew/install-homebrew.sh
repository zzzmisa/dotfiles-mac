#!/usr/bin/env zsh

# このスクリプトは他のinstallerからsourceされるため、
# 呼び出し元の script_dir を上書きしない変数名を使う
install_homebrew_dir="${0:A:h}"
source "$install_homebrew_dir/../lib/homebrew.zsh"

# インストール済みなら再インストールせず、shellenv（PATH等）だけを現在のプロセスに反映する
if ensure_homebrew_shellenv; then
  return 0 2> /dev/null || exit 0
fi

# Homebrewインストール
# cf. https://brew.sh/
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

if ! ensure_homebrew_shellenv; then
  echo "❌ Homebrew installation failed: brew was not found after running the installer"
  return 1 2> /dev/null || exit 1
fi

# 新しいシェルでもbrewが使えるよう .zprofile（shellenv記載済み）を先に設置する
zsh "$install_homebrew_dir/../zsh/installer.sh"
