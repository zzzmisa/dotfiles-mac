#!/usr/bin/env zsh
set -e

# AivisSpeechのユーザー辞書を操作する。アプリを起動した状態で使う。
#
#   ./aivisspeech-dict.sh list
#   ./aivisspeech-dict.sh add みえかた図鑑 ミエカタズカン 5
#   ./aivisspeech-dict.sh export   # このフォルダの user-dict.json に書き出す（バックアップ）
#   ./aivisspeech-dict.sh import   # user-dict.json の内容を登録する（新しいMacで復元）
#
# 辞書の実体は ~/Library/Application Support/AivisSpeech-Engine/user_dict.json にあり、
# dotfilesの管理外。PCを買い替えると失われるので、変更したら export してコミットする。
#
# アクセント型は「何モーラ目の直後で音が下がるか」。0＝平板。
# 例: ミエカタズカン(7モーラ)で5＝「ズ」の後で下がる。
# 固有名詞（アプリ名など）は登録しておかないと単語が分割され、別々の語のように読まれる。

script_dir="${0:A:h}"
backup="$script_dir/user-dict.json"
base="http://127.0.0.1:10101"

if ! curl -s -m 3 -o /dev/null "$base/version"; then
  echo "AivisSpeechのエンジンに接続できません。アプリを起動してください" >&2
  exit 1
fi

# 同じ内容が既にあればスキップする。APIは重複チェックをしないため、
# そのまま登録すると同じ語が何件でも増える
register() {
  python3 - "$base" "$1" "$2" "$3" <<'PY'
import json, sys, urllib.parse, urllib.request
base, surface, pronunciation, accent = sys.argv[1:5]
current = json.loads(urllib.request.urlopen(f"{base}/user_dict", timeout=30).read())
if any(v["surface"] == surface and v["pronunciation"] == pronunciation
       and str(v["accent_type"]) == accent for v in current.values()):
    print(f"skipped (登録済み): {surface}")
    sys.exit()
url = (f"{base}/user_dict_word?surface={urllib.parse.quote(surface)}"
       f"&pronunciation={urllib.parse.quote(pronunciation)}"
       f"&accent_type={accent}&word_type={urllib.parse.quote('PROPER_NOUN')}")
urllib.request.urlopen(urllib.request.Request(url, method="POST"), timeout=60).read()
print(f"registered: {surface} / {pronunciation} / accent={accent}")
PY
}

case "${1:-list}" in
  list)
    curl -s "$base/user_dict" | python3 -c '
import json, sys
for v in json.load(sys.stdin).values():
    print(v["surface"], v["pronunciation"], "accent=" + str(v["accent_type"]), sep="\t")
'
    ;;

  add)
    [[ -n "$2" && -n "$3" ]] || { echo "usage: $0 add <表記> <カタカナ読み> <アクセント型>" >&2; exit 1; }
    register "$2" "$3" "${4:-0}"
    ;;

  export)
    curl -s "$base/user_dict" | python3 -c '
import json, sys
words = [{"surface": v["surface"], "pronunciation": v["pronunciation"],
          "accent_type": v["accent_type"]} for v in json.load(sys.stdin).values()]
words.sort(key=lambda w: w["surface"])
json.dump(words, open(sys.argv[1], "w"), ensure_ascii=False, indent=2)
open(sys.argv[1], "a").write("\n")
print(f"exported {len(words)} word(s) -> {sys.argv[1]}")
' "$backup"
    ;;

  import)
    [[ -f "$backup" ]] || { echo "$backup がありません" >&2; exit 1; }
    python3 -c '
import json, sys
for w in json.load(open(sys.argv[1])):
    print(w["surface"], w["pronunciation"], w["accent_type"], sep="\t")
' "$backup" | while IFS=$'\t' read -r surface pronunciation accent; do
      register "$surface" "$pronunciation" "$accent"
    done
    ;;

  *)
    echo "usage: $0 [list|add|export|import]" >&2; exit 1
    ;;
esac
