#!/usr/bin/env python3
"""AivisSpeech の /audio_query で、各行の読み（カナ）とアクセント句の区切り・核を実測して表示する。

使い方:
  aivis-accent-report.py <原稿.txt>          … 1行1文。空行は無視
  aivis-accent-report.py -t "読ませたい一文"
  環境変数: AIVIS_BASE（既定 http://127.0.0.1:10101）、AIVIS_SPEAKER（既定 888753763）

表示: 各句を「カナ/アクセント核」で並べ、読点で区切られた句には「、」を付ける。
判定の目安: 製品名・複合語が2句以上に分割されていたら辞書登録で結合する。
"""
import argparse
import json
import os
import sys
import urllib.parse
import urllib.request

BASE = os.environ.get("AIVIS_BASE", "http://127.0.0.1:10101")
SPEAKER = int(os.environ.get("AIVIS_SPEAKER", "888753763"))


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
    ap.add_argument("file", nargs="?")
    ap.add_argument("-t", "--text")
    ap.add_argument("--speaker", type=int, default=SPEAKER)
    args = ap.parse_args()
    if args.text:
        lines = [args.text]
    elif args.file:
        lines = [l.strip() for l in open(args.file, encoding="utf-8") if l.strip()]
    else:
        ap.print_help()
        return 2
    try:
        for line in lines:
            print(line)
            print("   => " + " | ".join(phrases(line, args.speaker)))
    except urllib.error.URLError as e:
        print(f"NG: AivisSpeech に接続できない（{BASE}）。アプリを起動しているか確認: {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
