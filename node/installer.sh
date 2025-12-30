#!/usr/bin/env zsh
set -e
# nodeコマンドがなければ
# Homebrew経由でnodenvをインストール
if ! type node > /dev/null 2>&1; then
  source homebrew/install-homebrew.sh
  brew install nodenv
fi

# Nodeのバージョンチェックとインストール/アップデート
sh node/set-nodenv.sh

# グローバルにインストールするパッケージ
npm install --global textlint