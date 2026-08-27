#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
source "$script_dir/../../lib/environment.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

common_skill_names=(
  misa-gh-issue
  misa-gh-pr
  misa-merge-cleanup
)
private_skill_names=(
  zzzmisa-install-ios
  zzzmisa-ios-release
  zzzmisa-new-app
  zzzmisa-shorts-video
  zzzmisa-slide-compress
  zzzmisa-sns-post
  zzzmisa-store-assets
)
external_skill_sources=(
  "$HOME/mySources/photo-cleanup/skills/zzzmisa-photo-cleanup"
)
obsolete_skill_names=(
  zzzmisa-gh-issue
  zzzmisa-gh-pr
  zzzmisa-merge-cleanup
  zzzmisa-install-ios-simulator
  zzzmisa-install-ipad
  zzzmisa-install-iphone
  zzzmisa-refactor-issue
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

remove_obsolete_link() {
  local destination_root="$1"
  local skill_name="$2"
  local destination="$destination_root/$skill_name"
  local expected_source="$script_dir/$skill_name"

  if [[ -L "$destination" && "$(readlink "$destination")" == "$expected_source" ]]; then
    unlink "$destination"
    echo "Removed obsolete skill link $destination"
  fi
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

if [[ "$DOTFILES_ENV" = "private" ]]; then
  for skill_source in "${external_skill_sources[@]}"; do
    if [[ ! -f "$skill_source/SKILL.md" ]]; then
      echo "Skipped missing external skill: $skill_source"
      continue
    fi

    link_skill "$skill_source" "$HOME/.agents/skills"
    link_skill "$skill_source" "$HOME/.claude/skills"
    linked_count=$((linked_count + 1))
  done
fi

for skill_name in "${obsolete_skill_names[@]}"; do
  remove_obsolete_link "$HOME/.agents/skills" "$skill_name"
  remove_obsolete_link "$HOME/.claude/skills" "$skill_name"
done

if [[ "$linked_count" -eq 0 ]]; then
  echo "No agent skills found under $script_dir"
  exit 1
fi

echo "👍 Agent Skills setup is done! Linked $linked_count skill(s)."
