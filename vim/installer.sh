# .vimrcの設置
ln -sf $PWD/vim/.vimrc ~/.vimrc

# Dein.vimインストール（プラグインインストールはVim上で :call dein#install() 実行）
if [ ! -e ~/.vim/dein ]; then
  curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > dein.sh
  sh ./dein.sh ~/.vim/dein
  rm dein.sh
fi

echo 👍 Vim setting is done!