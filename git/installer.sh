#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# GitコマンドがなかったらHomebrewをインストール
if ! type git > /dev/null 2>&1; then
  source "$script_dir/../homebrew/install-homebrew.sh"
fi

# Gitの設定に必要なフォルダの作成
mkdir -p ~/.config/git

# gitconfigの設置
echo Git user name :
read git_name
echo Git user email:
read git_email

cp -i "$script_dir/gitconfig" "$script_dir/mygitconfig"
sed -i '' -e 's/REPLACEME_GIT_NAME/'"${git_name}"'/g' "$script_dir/mygitconfig"
sed -i '' -e 's/REPLACEME_GIT_EMAIL/'"${git_email}"'/g' "$script_dir/mygitconfig"

ln -sf "$script_dir/mygitconfig" ~/.config/git/config

# gitignoreの設置
# cf. https://git-scm.com/docs/gitignore
ln -sf "$script_dir/ignore" ~/.config/git/ignore

echo 👍 Git setting is done!
