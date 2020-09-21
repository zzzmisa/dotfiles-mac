# .vimrcの設置
ln -sf $PWD/vim/.vimrc ~/.vimrc

# Dein.vimインストール（プラグインインストールはVim上で :call dein#install() 実行）
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > dein.sh
sh ./dein.sh ~/.vim/dein
rm dein.sh

echo 👍 Vim setting is done!