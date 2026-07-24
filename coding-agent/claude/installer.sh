#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# Claude Codeの設定ファイルの設置
# - keybindings.json: キーバインド（Enter=改行、Cmd+Enter=送信）
# - settings.json: 全般設定（テーマ、会話履歴の保持期間等）
mkdir -p "$HOME/.claude"

link_config() {
  local file_name="$1"
  local destination="$HOME/.claude/$file_name"

  # シンボリックリンク以外の既存ファイルがある場合はバックアップしてから置き換える
  if [[ -e "$destination" && ! -L "$destination" ]]; then
    local backup="${destination}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$destination" "$backup"
    echo "Moved existing $destination to $backup"
  fi

  ln -sfn "$script_dir/$file_name" "$destination"
}

link_config "keybindings.json"
link_config "settings.json"

echo 👍 Claude Code setting is done!
