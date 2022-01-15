# brewコマンドがない場合のみ
# Homebrewインストール
# cf. https://brew.sh/
if !(type brew > /dev/null 2>&1); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" # .zprofileにも記載済み
  sh zsh/installer.sh
fi