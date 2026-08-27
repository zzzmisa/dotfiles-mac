#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
source "$script_dir/../../lib/environment.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

common_skill_names=(
  misa-gh-issue
  misa-gh-pr
  misa-merge-cleanup
  zzzmisa-slide-compress
)
private_skill_names=(
  zzzmisa-install-ios
  zzzmisa-ios-release
  zzzmisa-new-app
  zzzmisa-shorts-video
  zzzmisa-sns-post
  zzzmisa-store-assets
)
link_skill() {
  local skill_source="$1"
  local destination_root="$2"
  local skill_name="${skill_source:t}"
  local destination="$destination_root/$skill_name"

  mkdir -p "$destination_root"

  if [[ -L "$destination" ]]; then
    ln -sfn "$skill_source" "$destination"
    return
  fi

  if [[ -e "$destination" ]]; then
    local backup="${destination}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$destination" "$backup"
    echo "Moved existing $destination to $backup"
  fi

  ln -s "$skill_source" "$destination"
}

linked_count=0

skill_names=("${common_skill_names[@]}")
if [[ "$DOTFILES_ENV" = "private" ]]; then
  skill_names+=("${private_skill_names[@]}")
fi

for skill_name in "${skill_names[@]}"; do
  skill_source="$script_dir/$skill_name"
  if [[ ! -f "$skill_source/SKILL.md" ]]; then
    echo "Skipped missing skill: $skill_source"
    continue
  fi

  link_skill "$skill_source" "$HOME/.agents/skills"
  link_skill "$skill_source" "$HOME/.claude/skills"
  linked_count=$((linked_count + 1))
done

if [[ "$linked_count" -eq 0 ]]; then
  echo "No agent skills found under $script_dir"
  exit 1
fi

echo "👍 Agent Skills setup is done! Linked $linked_count skill(s)."
