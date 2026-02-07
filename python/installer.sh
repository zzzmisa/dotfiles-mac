#!/usr/bin/env zsh
set -e

# Pythonのバージョンチェックとインストール/アップデート
sh python/set-pyenv.sh

# グローバルにインストールするパッケージ
# pip install --global package1 package2