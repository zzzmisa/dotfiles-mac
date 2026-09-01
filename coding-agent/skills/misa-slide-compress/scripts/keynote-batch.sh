#!/bin/bash
# .key をまとめて縮小する。1件ずつ keynote-reduce.sh を呼び、安全装置を挟む。
#
#   keynote-batch.sh <作業ルート> <バックアップルート> <ログ.tsv> [再起動間隔]
#
# バックアップルートは作業ルートと同じディレクトリ構造で原本を持っていること。
# 「増えたら戻す」ためにバックアップは必須。無い状態では実行しない。
set -u
BASE="${1:?usage: keynote-batch.sh <work_root> <backup_root> <log.tsv> [restart_every]}"
BAK="${2:?}"; LOG="${3:?}"; EVERY="${4:-8}"
RED="$(cd "$(dirname "$0")" && pwd)/keynote-reduce.sh"

locked() { /usr/sbin/ioreg -n Root -d1 -a 2>/dev/null | grep -q CGSSessionScreenIsLocked; }
docs()   { osascript -e 'with timeout of 20 seconds
tell application id "com.apple.Keynote" to get count of documents
end timeout' 2>/dev/null; }
wins()   { osascript -e 'tell application "System Events" to tell process "Keynote" to get count of windows' 2>/dev/null; }

# 書類を伴わずにKeynoteを起動すると「開く」パネルが出る。これは書類ではないので
# docs=0 / windows=1 になり、状態チェックが永久に通らなくなる。Escapeで閉じる。
dismiss_panels() {
  for _ in 1 2 3; do
    [ "$(docs)" = "0" ] || return 0          # 書類が開いているなら対象外
    [ "$(wins)" = "0" ] && return 0
    osascript -e 'tell application id "com.apple.Keynote" to activate' >/dev/null 2>&1
    sleep 1
    osascript -e 'tell application "System Events" to key code 53' >/dev/null 2>&1
    sleep 2
  done
}

restart_keynote() {
  pkill -x Keynote 2>/dev/null; sleep 6
  open -b com.apple.Keynote 2>/dev/null            # -j（隠して起動）は使わない。
  osascript -e 'tell application "System Events" to tell process "Keynote" to set visible to true' >/dev/null 2>&1
  for _ in $(seq 1 30); do
    sleep 1
    [ "$(docs)" = "0" ] && { dismiss_panels; return 0; }
  done
  return 1
}

# 書類はウインドウを持たずに残ることがある。必ず両方を見る。
ensure_clean() {
  [ "$(docs)" = "0" ] && [ "$(wins)" = "0" ] && return 0
  dismiss_panels
  [ "$(docs)" = "0" ] && [ "$(wins)" = "0" ] && return 0
  osascript -e 'with timeout of 60 seconds
tell application id "com.apple.Keynote" to close every document saving no
end timeout' >/dev/null 2>&1
  sleep 3
  dismiss_panels
  [ "$(docs)" = "0" ] && [ "$(wins)" = "0" ] && return 0
  restart_keynote
}

if locked; then echo "画面がロックされています。解除してから実行してください"; exit 4; fi
[ -d "$BAK" ] || { echo "バックアップ $BAK がありません。バックアップ無しでは実行しません"; exit 1; }

# 利用者の作業中の書類を巻き添えにしないため、開いている書類があれば止める。
# docs() が空文字を返すのは「無応答」であって「0件」ではない。取り違えない。
d=$(docs)
if [ -z "$d" ]; then
  echo "Keynoteが応答しません。再起動します"
  restart_keynote || { echo "Keynoteを起動できませんでした"; exit 1; }
  d=$(docs)
fi
if [ "$d" != "0" ]; then
  echo "Keynoteに書類が ${d} 件開かれています。閉じてから実行してください"
  echo "（close every document saving no は利用者の未保存の作業を捨てるので自動では行いません）"
  exit 1
fi

# バッチ中にディスプレイがスリープ->ロックするとGUI操作が全滅するので抑止する
caffeinate -d -w $$ &
CAFF=$!
trap 'kill $CAFF 2>/dev/null' EXIT

n=0
while IFS= read -r rel; do
  n=$((n+1))
  work="$BASE/$rel"; src="$BAK/$rel"
  [ -f "$src" ] || { printf '%s\tFAIL\t0\t0\tバックアップに原本が無い\n' "$rel" >> "$LOG"; continue; }
  if locked; then printf '%s\tABORT\t0\t0\t画面がロックされたため中断\n' "$rel" >> "$LOG"; break; fi
  before=$(stat -f%z "$src")

  # 状態の蓄積を防ぐため一定件数ごとに作り直す
  [ "$n" -gt 1 ] && [ $(( (n-1) % EVERY )) -eq 0 ] && restart_keynote >/dev/null
  ensure_clean || { printf '%s\tFAIL\t%s\t%s\tKeynoteをクリーンにできず\n' "$rel" "$before" "$before" >> "$LOG"; continue; }

  out=$("$RED" "$work" 2>&1); rc=$?
  after=$(stat -f%z "$work")
  case $rc in 0) st=OK ;; 2) st=SKIP ;; 3) st=DIALOG ;; 4) st=LOCKED ;; *) st=FAIL ;; esac

  # 失敗した / 増えた場合は必ず原本へ戻す（Keynoteの縮小でも増えることがある）
  if [ "$rc" != "0" ] || [ "$after" -ge "$before" ]; then
    cmp -s "$work" "$src" || { cp "$src" "$work"; [ "$rc" = "0" ] && st="REVERT(増加)"; }
    after=$(stat -f%z "$work")
  fi
  touch -r "$src" "$work"          # アーカイブでは原本の日時に価値がある
  printf '%s\t%s\t%s\t%s\t%s\n' "$rel" "$st" "$before" "$after" "$(echo "$out" | tr '\n' ' ')" >> "$LOG"
  ensure_clean >/dev/null
done
echo "__DONE__" >> "$LOG"
