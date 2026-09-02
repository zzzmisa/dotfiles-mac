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

# 途中で失敗しても残りのコンポーネントは実行し、最後にまとめて報告する
failed_components=()
for component in "${components[@]}"; do
  dir="$script_dir/$component"

  installer="$dir/installer.sh"
  if [[ -f "$installer" ]]; then
    echo 📁 "$dir"
    if ! zsh "$installer" "$DOTFILES_ENV"; then
      failed_components+=("$component")
    fi
  fi
done

if (( ${#failed_components[@]} > 0 )); then
  echo "❌ Failed coding-agent components: ${failed_components[*]}"
  exit 1
fi
