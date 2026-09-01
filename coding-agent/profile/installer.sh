#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
source "$script_dir/../../lib/environment.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

# Private用プロファイル（AGENTS.md）とメモリは非公開のdotfiles-mac-privateから入れる
if [[ "$DOTFILES_ENV" != "office" ]]; then
  echo "Skipped agent profile: install it from dotfiles-mac-private in the private environment."
  exit 0
fi

profile_source="$script_dir/AGENTS.office.md"

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
