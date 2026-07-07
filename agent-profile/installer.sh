#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
profile_source="$script_dir/AGENTS.md"

# プロファイルの実体はリポジトリ内のAGENTS.md 1つで、
# 各エージェントのグローバル設定ファイルとしてシンボリックリンクする
link_profile() {
  local destination="$1"

  mkdir -p "${destination:h}"

  if [[ -L "$destination" ]]; then
    ln -sfn "$profile_source" "$destination"
    return
  fi

  if [[ -e "$destination" ]]; then
    local backup="${destination}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$destination" "$backup"
    echo "Moved existing $destination to $backup"
  fi

  ln -s "$profile_source" "$destination"
}

link_profile "$HOME/.claude/CLAUDE.md" # Claude Code のグローバルメモリ
link_profile "$HOME/.codex/AGENTS.md"  # Codex のグローバル指示

echo "👍 Agent profile setup is done!"
