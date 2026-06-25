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

app-preview-iphone() {
  _app-preview app-preview-iphone 886 1920 "$1"
}

app-preview-ipad() {
  _app-preview app-preview-ipad 1200 1600 "$1"
}
