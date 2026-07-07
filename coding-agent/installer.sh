#!/usr/bin/env zsh

# 配下の各フォルダ(profile, skills)の installer.sh を順に実行する

script_dir="${0:A:h}"

for dir in "$script_dir"/*; do
  [[ ! -d "$dir" ]] && continue

  installer="$dir/installer.sh"
  if [[ -f "$installer" ]]; then
    echo 📁 "$dir"
    (set +e; zsh "$installer")
  fi
done
