# pythonコマンドがなければ
# Homebrew経由でpyenvをインストール
if !(type python > /dev/null 2>&1); then
  source homebrew/install-homebrew.sh
  brew install pyenv
  sh python/set-pyenv.sh
fi