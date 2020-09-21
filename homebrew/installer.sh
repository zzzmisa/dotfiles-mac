# Homebrewインストール
# cf. https://brew.sh/
if !(type brew > /dev/null 2>&1); then
  # brewコマンドがインストールされていない場合のみ実行
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Brewfile実行
cd $PWD/homebrew
brew bundle
cd -

echo 👍 Homebrew setting is done!