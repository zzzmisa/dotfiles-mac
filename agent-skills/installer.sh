#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

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

for skill_source in "$script_dir"/*; do
  [[ -d "$skill_source" ]] || continue
  [[ -f "$skill_source/SKILL.md" ]] || continue

  link_skill "$skill_source" "$HOME/.agents/skills"
  link_skill "$skill_source" "$HOME/.claude/skills"
  linked_count=$((linked_count + 1))
done

if [[ "$linked_count" -eq 0 ]]; then
  echo "No agent skills found under $script_dir"
  exit 1
fi

echo "👍 Agent Skills setup is done! Linked $linked_count skill(s)."
