#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# キーバインド設定（Enter=改行、Ctrl+J / Option+Enter / Cmd+Enter=送信）の設置
mkdir -p "$HOME/.claude"

destination="$HOME/.claude/keybindings.json"

# シンボリックリンク以外の既存ファイルがある場合はバックアップしてから置き換える
if [[ -e "$destination" && ! -L "$destination" ]]; then
  backup="${destination}.backup.$(date +%Y%m%d%H%M%S)"
  mv "$destination" "$backup"
  echo "Moved existing $destination to $backup"
fi

ln -sfn "$script_dir/keybindings.json" "$destination"

echo 👍 Claude Code keybindings setup is done!
