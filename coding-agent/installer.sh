#!/usr/bin/env zsh

# 共通設定と、環境に応じた追加設定の installer.sh を順に実行する

# インストールするかどうかを先に確認
printf "Install coding-agent settings? (y/n) :  "
IFS= read -r install_coding_agent
if [[ "$install_coding_agent" != "y" ]]; then
  echo "Skipped coding-agent installation."
  exit 0
fi

script_dir="${0:A:h}"
source "$script_dir/../lib/environment.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

components=(claude profile skills)

for component in "${components[@]}"; do
  dir="$script_dir/$component"

  installer="$dir/installer.sh"
  if [[ -f "$installer" ]]; then
    echo 📁 "$dir"
    (set +e; zsh "$installer" "$DOTFILES_ENV")
  fi
done
