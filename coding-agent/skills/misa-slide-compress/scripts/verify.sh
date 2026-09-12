#!/bin/bash
# 原本(バックアップ)と処理後を突き合わせて検証する。
#
#   verify.sh <backup_root> <work_root>
#
# .key : ZIP整合性 / Keynoteで開けるか / スライド数の一致
# .pdf : ページ数 / 抽出テキストの文字多重集合 / 埋め込みフォント
set -u
set -o pipefail
failed=0
BAK="${1:?usage: verify.sh <backup_root> <work_root>}"
WORK="${2:?usage: verify.sh <backup_root> <work_root>}"
[ -d "$BAK" ] && [ -d "$WORK" ] || { echo "バックアップと作業先のディレクトリが必要です" >&2; exit 1; }

echo "=== PDF ==="
printf '%-44s %5s %5s %-10s %s\n' "file" "頁前" "頁後" "埋込font" "判定"
while IFS= read -r b; do
  rel="${b#$WORK/}"; a="$BAK/$rel"
  [ -f "$a" ] || { printf '%-44s %s\n' "$(basename "$rel")" "バックアップなし"; failed=1; continue; }
  p1=$(pdfinfo "$a" 2>/dev/null | awk '/^Pages:/{print $2}')
  p2=$(pdfinfo "$b" 2>/dev/null | awk '/^Pages:/{print $2}')
  # pdffonts の列は可変長（"Type 3" は2語、フォント名が [none] のこともある）。
  # $(NF-3) で数えると sub 列を emb 列と取り違えて誤報になる。ヘッダの桁位置で見る。
  fr=$(pdffonts "$b" 2>/dev/null | awk '
    /^name /{c=index($0,"emb"); next}
    /^-----/{next}
    NF && c { t++; if (substr($0,c,3) ~ /no/) e++ }
    END { print t+0, e+0 }') || {
    printf '%-44s %s\n' "$(basename "$rel")" "フォント検証失敗"
    failed=1; continue
  }
  nf=${fr% *}; ne=${fr#* }
  txt=$(python3 - "$a" "$b" <<'PY'
import subprocess, sys, collections
def chars(p):
    t = subprocess.run(["pdftotext", p, "-"], capture_output=True, check=True).stdout.decode("utf-8", "replace")
    return collections.Counter(c for c in t if not c.isspace())
a, b = chars(sys.argv[1]), chars(sys.argv[2])
lost, added = a - b, b - a
print("OK" if not lost and not added else "文字差 -%s +%s" % (dict(lost), dict(added)))
PY
)
  v="OK"
  [ -n "$p1" ] && [ -n "$p2" ] && [ -n "$txt" ] || v="読み取り失敗!"
  [ "$p1" != "$p2" ] && v="ページ数不一致!"
  [ "$ne" != "0" ] && v="$v 未埋込フォント${ne}件!"
  [ "$txt" != "OK" ] && v="$v $txt"
  [ "$v" = "OK" ] || failed=1
  printf '%-44s %5s %5s %-10s %s\n' "$(basename "$rel")" "$p1" "$p2" "$((nf-ne))/$nf" "$v"
done < <(find "$WORK" -name "*.pdf" ! -name "._*" | sort)

echo
echo "=== Keynote ==="
printf '%-44s %6s %6s %s\n' "file" "枚前" "枚後" "ZIP"
slides() {
  osascript - "$1" 2>/dev/null <<'APPLESCRIPT'
on run argv
  tell application id "com.apple.Keynote"
    if (count of documents) is not 0 then error "既存の書類があるため検証を停止します"
    set targetDoc to open (POSIX file (item 1 of argv))
    try
      set slideCount to count of slides of targetDoc
      close targetDoc saving no
      return slideCount
    on error errMsg
      try
        close targetDoc saving no
      end try
      error errMsg
    end try
  end tell
end run
APPLESCRIPT
}
# 原本は一時領域にコピーして開く（バックアップをKeynoteの自動保存で書き換えないため）
TMP=$(mktemp -d) || exit 1
trap 'rm -rf "$TMP"' EXIT
while IFS= read -r b; do
  rel="${b#$WORK/}"; a="$BAK/$rel"
  [ -f "$a" ] || { printf '%-44s %s\n' "$(basename "$rel")" "バックアップなし"; failed=1; continue; }
  z=$(unzip -t "$b" 2>&1 | tail -1 | grep -q "No errors" && echo OK || echo NG!)
  cp "$a" "$TMP/orig.key" || { failed=1; continue; }
  # 処理後もコピーで開き、自動保存が検証対象を変えるのを防ぐ。
  cp "$b" "$TMP/work.key" || { failed=1; continue; }
  n1=$(slides "$TMP/orig.key"); n2=$(slides "$TMP/work.key")
  [ -n "$n1" ] && [ "$n1" = "$n2" ] && [ "$z" = "OK" ] || failed=1
  printf '%-44s %6s %6s %s\n' "$(basename "$rel")" "${n1:-FAIL}" "${n2:-FAIL}" "$z"
done < <(find "$WORK" -name "*.key" ! -name "._*" | sort)
exit "$failed"
