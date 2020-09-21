# Gitがインストールされていない場合のみ
# homebrewとgitを先にインストール
if !(type git > /dev/null 2>&1); then
  sh homebrew/install-brew.sh
  brew install git
fi

# Gitの設定に必要なフォルダの作成
mkdir ~/.config && mkdir ~/.config/git

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