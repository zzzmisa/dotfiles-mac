#!/usr/bin/env python3
"""AivisSpeech の /audio_query で、各行の読み（カナ）とアクセント句の区切り・核を実測して表示する。

使い方:
  aivis-accent-report.py <原稿.txt>          … 1行1文。空行は無視
  aivis-accent-report.py -t "読ませたい一文"
  環境変数: AIVIS_BASE（既定 http://127.0.0.1:10101）、AIVIS_SPEAKER（既定 888753763）

表示: 各句を「カナ/アクセント核」で並べ、読点で区切られた句には「、」を付ける。
句分割は診断の手掛かり。意図した読みと異なる場合に辞書登録などで修正する。
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = os.environ.get("AIVIS_BASE", "http://127.0.0.1:10101").rstrip("/")
SPEAKER = os.environ.get("AIVIS_SPEAKER", "888753763")


def phrases(text: str, speaker: int) -> list[str]:
    url = f"{BASE}/audio_query?" + urllib.parse.urlencode({"text": text, "speaker": speaker})
    with urllib.request.urlopen(urllib.request.Request(url, method="POST"), timeout=60) as r:
        query = json.load(r)
    out = []
    for ap in query["accent_phrases"]:
        kana = "".join(m["text"] for m in ap["moras"])
        pause = "、" if ap.get("pause_mora") else ""
        out.append(f"{kana}/{ap['accent']}{pause}")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    source = ap.add_mutually_exclusive_group(required=True)
    source.add_argument("file", nargs="?")
    source.add_argument("-t", "--text")
    ap.add_argument("--speaker", type=int, default=SPEAKER)
    args = ap.parse_args()
    try:
        if args.text is not None:
            lines = [args.text.strip()] if args.text.strip() else []
        else:
            with open(args.file, encoding="utf-8") as f:
                lines = [line.strip() for line in f if line.strip()]
        if not lines:
            ap.error("原稿が空です")
        for line in lines:
            print(line)
            print("   => " + " | ".join(phrases(line, args.speaker)))
    except urllib.error.HTTPError as e:
        print(f"NG: audio_query が HTTP {e.code} を返しました。原稿と話者 ID を確認してください", file=sys.stderr)
        return 1
    except urllib.error.URLError as e:
        print(f"NG: AivisSpeech に接続できない（{BASE}）。アプリを起動しているか確認: {e}", file=sys.stderr)
        return 1
    except (OSError, ValueError, KeyError, TypeError) as e:
        print(f"NG: 原稿または API 応答を読み取れません: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
