#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# Claude Code のプロジェクト別メモリディレクトリ。
# 端末をまたいで引き継ぎたいメモリだけをこのフォルダで管理し、
# シンボリックリンクで配置する（一時的なメモリは端末側に直接置く）
memory_dir="$HOME/.claude/projects/-Users-zzzmisa-mySources/memory"
index_file="$memory_dir/MEMORY.md"

mkdir -p "$memory_dir"

if [[ ! -f "$index_file" ]]; then
  print -- "# Memory Index\n" > "$index_file"
fi

for source in "$script_dir"/*.md; do
  filename="${source:t}"

  ln -sfn "$source" "$memory_dir/$filename"

  # インデックス未登録ならfrontmatterのdescriptionを見出しにして追記する
  if ! grep -q "($filename)" "$index_file"; then
    description="$(sed -n 's/^description: //p' "$source" | head -1)"
    echo "- [${filename%.md}]($filename) — $description" >> "$index_file"
  fi
done

echo "👍 Agent memory setup is done!"
