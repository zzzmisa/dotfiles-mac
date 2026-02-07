#!/usr/bin/env zsh
set -e

# Rubyのバージョンチェックとインストール/アップデート
sh ruby/set-rbenv.sh

# グローバルにインストールするパッケージ
# gem install package1 package2

echo 👍 Ruby setting is done!
