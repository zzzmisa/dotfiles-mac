# Homebrewインストール
source homebrew/install-homebrew.sh

# Rosettaインストール
softwareupdate --install-rosetta

# Brewfile実行
cd $PWD/homebrew
brew bundle
cd -

echo 👍 Homebrew setting is done!