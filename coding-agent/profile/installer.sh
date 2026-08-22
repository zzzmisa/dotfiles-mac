#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
source "$script_dir/../../lib/environment.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

if [[ "$DOTFILES_ENV" = "office" ]]; then
  profile_source="$script_dir/AGENTS.office.md"
else
  profile_source="$script_dir/AGENTS.md"
fi

# 選択した環境のプロファイルを、各エージェントのグローバル設定としてリンクする
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
