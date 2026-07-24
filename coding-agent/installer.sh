#!/usr/bin/env zsh

# 配下の各フォルダ(claude, memory, profile, skills)の installer.sh を順に実行する

# インストールするかどうかを先に確認
printf "Install coding-agent (claude, memory, profile, skills)? (y/n) :  "
IFS= read -r install_coding_agent
if [[ "$install_coding_agent" != "y" ]]; then
  echo "Skipped coding-agent installation."
  exit 0
fi

script_dir="${0:A:h}"

for dir in "$script_dir"/*; do
  [[ ! -d "$dir" ]] && continue

  installer="$dir/installer.sh"
  if [[ -f "$installer" ]]; then
    echo 📁 "$dir"
    (set +e; zsh "$installer")
  fi
done
