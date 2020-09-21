# brewコマンドがインストールされていない場合のみ
# Homebrewインストール
# cf. https://brew.sh/
if !(type brew > /dev/null 2>&1); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi