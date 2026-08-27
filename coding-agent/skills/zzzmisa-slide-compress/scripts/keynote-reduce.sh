#!/bin/bash
# Keynoteの「ファイルサイズを減らす」を1ファイルに適用する（GUIスクリプティング）。
#
#   keynote-reduce.sh <file.key>
#
# 終了コード: 0=縮小して保存 / 2=縮小ボタンが無くスキップ / 3=Keynoteが開けなかった / 1=失敗
#
# 前提: システム設定 > プライバシーとセキュリティ > アクセシビリティ で
#       このスクリプトを起動するアプリ（Claude.app / ターミナル等）を許可しておくこと。
set -u

f="${1:?usage: keynote-reduce.sh <file.key>}"
[ -f "$f" ] || { echo "  FAIL: ファイルがありません: $f"; exit 1; }

osa() { osascript -e "$1" 2>&1; }
kn()  { osascript -e "tell application \"System Events\" to tell process \"Keynote\" to $1" 2>&1; }

# ファイルメニューはロケール非依存に index 3 で引く
FILE_MENU='menu 1 of menu bar item 3 of menu bar 1'

menu_item_name() {
  # 「ファイルサイズを減らす…」/「Reduce File Size…」のどちらでも拾う
  osascript 2>/dev/null <<EOF
tell application "System Events" to tell process "Keynote"
  repeat with mi in menu items of $FILE_MENU
    try
      set n to name of mi as text
      if n starts with "ファイルサイズを減らす" or n starts with "Reduce File Size" then return n
    end try
  end repeat
end tell
return ""
EOF
}

button_name() { # $1 = sheet index expression
  osascript 2>/dev/null <<EOF
tell application "System Events" to tell process "Keynote"
  repeat with b in buttons of sheet 1 of window 1
    set n to name of b as text
    if n is "このファイルを縮小" or n is "Reduce This File" then return n
  end repeat
end tell
return ""
EOF
}

cancel_name() {
  osascript 2>/dev/null <<'EOF'
tell application "System Events" to tell process "Keynote"
  repeat with b in buttons of window 1
    set n to name of b as text
    if n is "キャンセル" or n is "Cancel" then return n
  end repeat
end tell
return ""
EOF
}

# --- 事前条件: 画面がロックされていないこと -------------------------------------
# GUIスクリプティングはロック中のスクリーンでは動かない。ウインドウを取得できず
# 「開けませんでした」が延々と続くので、ここで止めて理由を明示する。
if /usr/sbin/ioreg -n Root -d1 -a 2>/dev/null | grep -q CGSSessionScreenIsLocked; then
  echo "  FAIL: 画面がロックされています。ロックを解除してから実行してください"
  exit 4
fi

# --- 事前条件: 開いている書類もウインドウも無いこと -----------------------------
# 注意: 書類はウインドウを持たずに残ることがある（縮小が途中で止まった場合など）。
#       count of windows だけを見ると「クリーン」と誤判定し、以降が全部失敗する。
docs_now() { osascript -e 'with timeout of 20 seconds
tell application id "com.apple.Keynote" to get count of documents
end timeout' 2>/dev/null; }

d=$(docs_now)
if [ "$d" != "0" ] || [ "$(kn 'count of windows')" != "0" ]; then
  echo "  FAIL: Keynoteに書類/ウインドウが残っています (documents=${d:-?} windows=$(kn 'count of windows'))"
  exit 1
fi

# どの経路で抜けても開いた書類を必ず閉じる（閉じ忘れがKeynoteを詰まらせる原因になる）
close_all() {
  osascript -e 'with timeout of 60 seconds
tell application id "com.apple.Keynote" to close every document saving no
end timeout' >/dev/null 2>&1
}
trap 'close_all' EXIT

# iCloudから実体をダウンロードさせてから触る（dataless対策）
cat "$f" > /dev/null 2>&1

open -b com.apple.Keynote "$f"

# ドキュメントウインドウ、もしくはエラーダイアログが出るまで待つ
# 非表示(hidden)で起動していると書類は開いてもウインドウが0のままになる。
# ウインドウ数を先に見ると永久に待つので、必ず書類の有無を先に判定する。
state=""
for _ in $(seq 1 90); do
  sleep 1
  if [ "$(docs_now)" = "1" ]; then state="doc"; break; fi
  [ "$(kn 'count of windows')" = "0" ] && continue
  if [ "$(kn 'get subrole of window 1')" = "AXDialog" ]; then state="dialog"; break; fi
done

# メニュー操作にはウインドウが要る。隠れていれば表に出す
if [ "$state" = "doc" ]; then
  kn 'set visible to true' >/dev/null 2>&1
  osa 'tell application id "com.apple.Keynote" to activate' >/dev/null 2>&1
  for _ in $(seq 1 30); do
    [ "$(kn 'count of windows')" != "0" ] && break
    sleep 1
  done
  [ "$(kn 'count of windows')" = "0" ] && { echo "  FAIL: ウインドウが出ませんでした"; exit 1; }
fi

if [ "$state" = "dialog" ]; then
  echo "  ERROR DIALOG: $(kn 'get value of static text 1 of window 1')"
  c=$(cancel_name); [ -n "$c" ] && kn "click button \"$c\" of window 1" >/dev/null
  sleep 2
  exit 3
fi
[ "$state" = "doc" ] || { echo "  FAIL: 開けませんでした"; exit 1; }

sleep 2
[ "$(kn 'count of sheets of window 1')" = "0" ] || {
  echo "  FAIL: 想定外のシートが出ています: $(kn 'name of every button of sheet 1 of window 1')"; exit 1; }

# --- メニュー操作 --------------------------------------------------------------
# 注意: メニューを開かずに menu item を click しても、enabled 状態がキャッシュのまま
#       false と判定されて無反応になる。必ずメニューバー項目を先に click して開き、
#       enabled が true になるまで待ってから menu item を click すること。
ok=0
for attempt in 1 2 3; do
  osa 'tell application id "com.apple.Keynote" to activate' >/dev/null; sleep 2
  kn 'set frontmost to true' >/dev/null; sleep 1
  kn 'click menu bar item 3 of menu bar 1' >/dev/null

  item=""
  for _ in $(seq 1 15); do
    sleep 1
    item=$(menu_item_name)
    [ -n "$item" ] && [ "$(kn "get enabled of menu item \"$item\" of $FILE_MENU")" = "true" ] && break
    item=""
  done
  if [ -z "$item" ]; then
    echo "  retry $attempt: ファイルメニューが開きませんでした"
    kn 'key code 53' >/dev/null; sleep 1; continue
  fi

  kn "click menu item \"$item\" of $FILE_MENU" >/dev/null
  for _ in $(seq 1 90); do
    sleep 1
    [ "$(kn 'count of sheets of window 1')" = "1" ] && { ok=1; break; }
  done
  [ "$ok" = "1" ] && break
  echo "  retry $attempt: ダイアログが出ませんでした"
  kn 'key code 53' >/dev/null; sleep 2
done
[ "$ok" = "1" ] || {
  echo "  FAIL: 「ファイルサイズを減らす」ダイアログが出ませんでした"
  osa 'tell application id "com.apple.Keynote" to close document 1 saving no' >/dev/null
  exit 1; }

sleep 2
echo "  dialog: $(kn 'get value of every static text of sheet 1 of window 1' | tr ',' '\n' | grep -E '現在のサイズ|Current size' | sed 's/^ *//')"

btn=$(button_name)
if [ -z "$btn" ]; then
  echo "  SKIP: 縮小ボタンがありません（buttons=$(kn 'name of every button of sheet 1 of window 1')）"
  kn 'click button 2 of sheet 1 of window 1' >/dev/null; sleep 2
  osa 'tell application id "com.apple.Keynote" to close document 1 saving no' >/dev/null
  exit 2
fi

kn "click button \"$btn\" of sheet 1 of window 1" >/dev/null
ok=0
for _ in $(seq 1 300); do
  sleep 1
  [ "$(kn 'count of sheets of window 1')" = "0" ] && { ok=1; break; }
done
[ "$ok" = "1" ] || { echo "  FAIL: 縮小が終わりませんでした"; exit 1; }   # trapで書類を閉じる
sleep 2

# --- 保存して閉じる ------------------------------------------------------------
osa 'with timeout of 300 seconds
tell application id "com.apple.Keynote" to save document 1
end timeout' >/dev/null
ok=0
for _ in $(seq 1 120); do
  [ "$(osa 'tell application id "com.apple.Keynote" to get modified of document 1')" = "false" ] && { ok=1; break; }
  sleep 1
done
[ "$ok" = "1" ] || { echo "  FAIL: 保存が完了しませんでした"; exit 1; }

osa 'tell application id "com.apple.Keynote" to close document 1' >/dev/null
for _ in $(seq 1 60); do
  [ "$(kn 'count of windows')" = "0" ] && break
  sleep 1
done
sleep 2
trap - EXIT
exit 0
