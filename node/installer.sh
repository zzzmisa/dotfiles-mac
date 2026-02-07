#!/usr/bin/env zsh
set -e

# Nodeのバージョンチェックとインストール/アップデート
sh node/set-nodenv.sh

# グローバルにインストールするパッケージ
npm install --global textlint snyk