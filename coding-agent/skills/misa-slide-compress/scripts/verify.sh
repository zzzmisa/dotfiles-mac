#!/bin/bash
# 原本(バックアップ)と処理後を突き合わせて検証する。
#
#   verify.sh <backup_root> <work_root>
#
# .key : ZIP整合性 / Keynoteで開けるか / スライド数の一致
# .pdf : ページ数 / 抽出テキストの文字多重集合 / 埋め込みフォント
set -u
BAK="${1:?usage: verify.sh <backup_root> <work_root>}"
WORK="${2:?usage: verify.sh <backup_root> <work_root>}"

echo "=== PDF ==="
printf '%-44s %5s %5s %-10s %s\n' "file" "頁前" "頁後" "埋込font" "判定"
find "$WORK" -name "*.pdf" ! -name "._*" | sort | while IFS= read -r b; do
  rel="${b#$WORK/}"; a="$BAK/$rel"
  [ -f "$a" ] || { printf '%-44s %s\n' "$(basename "$rel")" "バックアップなし"; continue; }
  p1=$(pdfinfo "$a" 2>/dev/null | awk '/^Pages:/{print $2}')
  p2=$(pdfinfo "$b" 2>/dev/null | awk '/^Pages:/{print $2}')
  # pdffonts の列は可変長（"Type 3" は2語、フォント名が [none] のこともある）。
  # $(NF-3) で数えると sub 列を emb 列と取り違えて誤報になる。ヘッダの桁位置で見る。
  fr=$(pdffonts "$b" 2>/dev/null | awk '
    /^name /{c=index($0,"emb"); next}
    /^-----/{next}
    NF && c { t++; if (substr($0,c,3) ~ /no/) e++ }
    END { print t+0, e+0 }')
  nf=${fr% *}; ne=${fr#* }
  txt=$(python3 - "$a" "$b" <<'PY'
import subprocess, sys, collections
def chars(p):
    t = subprocess.run(["pdftotext", p, "-"], capture_output=True).stdout.decode("utf-8", "replace")
    return collections.Counter(c for c in t if not c.isspace())
a, b = chars(sys.argv[1]), chars(sys.argv[2])
lost, added = a - b, b - a
print("OK" if not lost and not added else "文字差 -%s +%s" % (dict(lost), dict(added)))
PY
)
  v="OK"
  [ "$p1" != "$p2" ] && v="ページ数不一致!"
  [ "$ne" != "0" ] && v="$v 未埋込フォント${ne}件!"
  [ "$txt" != "OK" ] && v="$v $txt"
  printf '%-44s %5s %5s %-10s %s\n' "$(basename "$rel")" "$p1" "$p2" "$((nf-ne))/$nf" "$v"
done

echo
echo "=== Keynote ==="
printf '%-44s %6s %6s %s\n' "file" "枚前" "枚後" "ZIP"
slides() {
  osascript -e "tell application id \"com.apple.Keynote\" to open (POSIX file \"$1\")" >/dev/null 2>&1
  local n=""
  for _ in $(seq 1 60); do
    n=$(osascript -e 'tell application id "com.apple.Keynote" to get count of slides of document 1' 2>/dev/null)
    [ -n "$n" ] && break
    sleep 1
  done
  osascript -e 'tell application id "com.apple.Keynote" to close every document saving no' >/dev/null 2>&1
  sleep 2
  echo "${n:-OPEN_FAILED}"
}
find "$WORK" -name "*.key" ! -name "._*" | sort > /tmp/_vk.txt
# 原本は一時領域にコピーして開く（バックアップをKeynoteの自動保存で書き換えないため）
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
while IFS= read -r b; do
  rel="${b#$WORK/}"; a="$BAK/$rel"
  [ -f "$a" ] || { printf '%-44s %s\n' "$(basename "$rel")" "バックアップなし"; continue; }
  z=$(unzip -t "$b" 2>&1 | tail -1 | grep -q "No errors" && echo OK || echo NG!)
  cp "$a" "$TMP/orig.key"
  printf '%-44s %6s %6s %s\n' "$(basename "$rel")" "$(slides "$TMP/orig.key")" "$(slides "$b")" "$z"
done < /tmp/_vk.txt
