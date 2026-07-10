_app-preview() {
  local command_name="$1"
  local width="$2"
  local height="$3"
  local input="$4"

  if [ -z "$input" ]; then
    echo "Usage: ${command_name} input.mp4"
    return 1
  fi

  local base="${input%.*}"
  local output="${base}_app_preview_${width}x${height}.mp4"

  ffmpeg -i "$input" \
    -vf "scale=${width}:${height}:force_original_aspect_ratio=increase,crop=${width}:${height},fps=30" \
    -c:v libx264 \
    -pix_fmt yuv420p \
    -c:a aac \
    -b:a 192k \
    -movflags +faststart \
    "$output"
}

zzzmisa-resize-video-for-appstore-iphone() {
  _app-preview zzzmisa-resize-video-for-appstore-iphone 886 1920 "$1"
}

zzzmisa-resize-video-for-appstore-ipad() {
  _app-preview zzzmisa-resize-video-for-appstore-ipad 1200 1600 "$1"
}

zzzmisa-delete-merged-local-branches() {
  local base="${1:-main}"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: not inside a git repository"
    return 1
  fi

  if ! git rev-parse --verify --quiet "$base" >/dev/null; then
    echo "Error: base branch not found: $base"
    return 1
  fi

  git fetch --prune || return 1

  local current_branch
  current_branch="$(git branch --show-current)"

  local branch
  local found=0

  for branch in "${(@f)$(git branch --format='%(refname:short)' --merged "$base")}"; do
    [ -z "$branch" ] && continue

    case "$branch" in
      "$base"|"$current_branch"|main|master|develop|dev)
        continue
        ;;
    esac

    found=1
    echo "=== $branch ==="

    local wt_path
    wt_path="$(git worktree list --porcelain | awk -v b="$branch" '
      /^worktree / { path = substr($0, 10) }
      /^branch / && $2 == "refs/heads/" b { print path }
    ')"

    if [ -n "$wt_path" ]; then
      echo "Removing worktree: $wt_path"
      git worktree remove "$wt_path" || {
        echo "Skipped branch because worktree could not be removed: $branch"
        continue
      }
    fi

    echo "Deleting local branch: $branch"
    git branch -d "$branch"
  done

  if [ "$found" -eq 0 ]; then
    echo "No merged local branches to delete."
  fi
}
