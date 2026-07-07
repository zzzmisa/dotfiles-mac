#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# .vimrcの設置
ln -sf "$script_dir/.vimrc" ~/.vimrc

echo 👍 Vim setting is done!
