#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# .zprofileと.zshrcの設置
ln -sf "$script_dir/.zprofile" ~/.zprofile
ln -sf "$script_dir/.zshrc" ~/.zshrc

echo 👍 zsh setting is done!
