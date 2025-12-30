#!/usr/bin/env zsh
set -e
# GitコマンドがなかったらHomebrewをインストール
if ! type git > /dev/null 2>&1; then
  source homebrew/install-homebrew.sh
fi

# Gitの設定に必要なフォルダの作成
mkdir -p ~/.config/git

# gitconfigの設置
echo Git user name : 
read git_name
echo Git user email: 
read git_email

cp -i $PWD/git/gitconfig $PWD/git/mygitconfig
sed -i '' -e 's/REPLACEME_GIT_NAME/'${git_name}'/g' $PWD/git/mygitconfig
sed -i '' -e 's/REPLACEME_GIT_EMAIL/'${git_email}'/g' $PWD/git/mygitconfig

ln -sf $PWD/git/mygitconfig ~/.config/git/config

# gitignoreの設置
# cf. https://git-scm.com/docs/gitignore
ln -sf $PWD/git/ignore ~/.config/git/ignore

echo 👍 Git setting is done!