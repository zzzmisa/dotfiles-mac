#!/usr/bin/env zsh
set -e

# 各フォルダ配下の installer.sh を順番に実行し、出力をそのままTerminalに流す
for dir in "$PWD"/*; do
  # ディレクトリでない、または .git なら skip
  [[ ! -d "$dir" ]] && continue
  [[ "$(basename "$dir")" = ".git" ]] && continue

  installer="$dir/installer.sh"
  if [[ -f "$installer" ]]; then
    echo 📁 "$dir"
    zsh "$installer"
  fi
done

# Macの再起動
printf "Reboot system? (y/n) :  "
IFS= read -r restart_env
if [[ "$restart_env" = "y" ]]; then
  sudo shutdown -r now
fi
