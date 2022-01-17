# nodeコマンドがなければ
# Homebrew経由でnodenvをインストール
if !(type node > /dev/null 2>&1); then
  source homebrew/install-homebrew.sh
  brew install nodenv
  sh node/set-nodenv.sh
fi

# グローバルにインストールするパッケージ
npm install --global textlint