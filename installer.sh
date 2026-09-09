#!/usr/bin/env zsh

# 各フォルダ配下の installer.sh を順番に実行し、出力をそのままTerminalに流す。
# 途中で失敗しても残りは実行し、最後に未完了のフォルダをまとめて表示する

script_dir="${0:A:h}"
source "$script_dir/lib/environment.zsh"
source "$script_dir/lib/homebrew.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

echo "Install environment: $DOTFILES_ENV"

failed_installers=()
for dir in "$script_dir"/*; do
  # ディレクトリでない、または .git なら skip
  [[ ! -d "$dir" ]] && continue
  [[ "$(basename "$dir")" = ".git" ]] && continue

  installer="$dir/installer.sh"
  [[ -f "$installer" ]] || continue

  # 子プロセスで反映された shellenv はここには戻ってこないため、
  # Homebrewインストール後の installer（mise, vscode等）向けに毎回PATHへ反映し直す
  ensure_homebrew_shellenv || true

  echo 📁 "$dir"
  if ! zsh "$installer" "$DOTFILES_ENV"; then
    failed_installers+=("$(basename "$dir")")
  fi
done

echo
if (( ${#failed_installers[@]} > 0 )); then
  echo "⚠️ 未完了の項目があります。各フォルダの出力（❌ / ⚠️）を確認して手動で対応してください:"
  for name in "${failed_installers[@]}"; do
    echo "  - $name"
  done
else
  echo "👍 All installers are done!"
fi

# Macの再起動
printf "Reboot system? (y/n) :  "
IFS= read -r restart_env
if [[ "$restart_env" = "y" ]]; then
  sudo shutdown -r now
fi
