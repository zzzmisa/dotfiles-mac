---
name: zzzmisa-store-assets
description: Standard repository layout for App Store Connect assets (screenshots, preview videos, metadata) and YouTube promo video materials, recipes, and build scripts. Use when placing, moving, renaming, or 整理 store screenshots / プレビュー動画 / 販促動画の素材・レシピ・スクリプト, when setting up these directories in a repo, or when asked どこに置く / 置き場所 for store or promo assets.
---

# ストア素材・販促素材の置き場

App Storeに入稿するものと、それを作るための素材・レシピ・スクリプトの配置を、
Misaの全アプリリポジトリで揃えるための規約。2026-08-06に
animal-vision-explorer と chibireco の2本を移行して確立した。

## 2つの区画

| ディレクトリ | 何を置くか |
| --- | --- |
| `fastlane/` | **ASCへ入稿するデータだけ**（metadata / screenshots / previews） |
| `promo/` | それを作るための**原本・レシピ・スクリプト**＋ストア外の販促成果物 |

`fastlane/` はfastlaneの都合でリポジトリルート固定（Flutterでも `ios/` の下に置かない）。

```text
fastlane/
├── metadata/{ja,en-US,zh-Hans}/
├── screenshots/{locale}/       # NN_画面[_モード]_{iPhone14Plus|iPadPro13}.png
└── previews/{locale}/          # iphone.mp4 / ipad.mp4

promo/
├── README.md                   # 索引。ここを読めば全部の所在が分かる
├── originals/                  # 加工前の原本
│   ├── README.md               # 素材仕様表（解像度・fps・尺・撮影機種・撮影日）
│   ├── recordings/             # {iphone|ipad}_{locale}[_{内容}].mp4
│   ├── screenshots/{iphone|ipad}/{locale}/
│   └── materials/              # 収録用のデモ素材（必要なリポジトリのみ）
├── scripts/                    # 素材生成・動画合成スクリプト（Python / sh）
├── app-store/
│   ├── README.md               # ASCスクショ・プレビューの制作レシピ
│   └── notes.md                # シーン境界・クロップ値などの実測値（任意）
└── youtube-shorts/
    ├── README.md               # Shortsのレシピ（構成・秒数・原稿・クレジット）
    ├── {locale}.mp4            # 完成品
    ├── bgm/                    # 使用BGMの原本
    ├── narration/              # {locale}_{n}_{scene}.wav
    └── work/                   # 中間生成物（gitignore）
```

`.gitignore` に `promo/**/work/` を入れる。
`assets/`（Flutterのバンドルディレクトリ、Swiftならアプリ同梱リソースの原本）には
販促素材を置かない。**Flutterでは `assets/` にディレクトリ指定を1行書くだけで
数百MBの原本がIPAに入る**ため、原本は必ず `promo/originals/` に出す。

## 命名

- **ロケールは常にASCのロケール名**（`ja` / `en-US` / `zh-Hans`）。
  `_en` / `zh` のような短縮形を混ぜない。ディレクトリ名もファイル名も同じ表記にする
- **原本のデバイスは `iphone` / `ipad`**。機種名は入れない（機種は入れ替わる。
  実際の撮影機種は `promo/originals/README.md` の仕様表に書く）
- **`fastlane/screenshots/` のファイル名だけは撮影枠を末尾に付ける**
  （`iPhone14Plus` / `iPadPro13`）。先頭の連番はApp Storeでの表示順。
  ロケールはディレクトリで表すのでファイル名には入れない
- **`fastlane/previews/` は `iphone.mp4` / `ipad.mp4` 固定**。
  `upload_store_previews` レーンがこの名前でASCのプレビューセット種別に対応づける

例:

```text
fastlane/screenshots/ja/02_camera_honeybee_iPhone14Plus.png
fastlane/previews/zh-Hans/ipad.mp4
promo/originals/recordings/iphone_en-US.mp4
promo/originals/screenshots/ipad/ja/03_camera_frog.png
promo/youtube-shorts/narration/zh-Hans_1_bee.wav
```

## 原則

- **再取得が難しい原本はコミットする**。実機収録・実機スクショ・TTSナレーションが該当する。
  TTSはバージョン差で再生成しても同じ音にならないので、音声ファイルごと残す
- **スクリプトで再生成できる中間物はコミットしない**。キャプションPNG・パッチ・
  App Storeバッジ・エンドカード・パノラマは `work/` に吐いてignoreする
- **合成は編集ソフトではなくスクリプトとして残す**。ffmpegコマンドをMarkdownに貼るだけに
  せず、`promo/scripts/build_shorts.sh <locale>` のように引数で回せる形にする。
  1年後に文言をひとつ変えたいときに、引数を直して流すだけで済む状態にしておく
- **判断の理由はREADMEに、値はスクリプトに**。「なぜこの区間を選んだか」「なぜこの位置か」は
  README、切り出し秒数やナレーション位置はスクリプトの引数に書く
- **ライセンス素材は出所と制約をREADMEに書く**。CC BYのBGMは再配布禁止なので、
  「このリポジトリをpublic化する場合は削除すること」を必ず明記する
- **素材は巨大**（実績: 458MB / 301MB）。git-lfsは使っていないので、原本の差し替えを
  何度も上書きコミットしない
- 画像をコミットする前に `exiftool -gps:all -location:all` で位置情報がないことを確認する

## 既存リポジトリを移行するとき

1. すべて `git mv` で動かす（内容が変わらなければ新規blobは増えず、リポジトリは太らない）
2. 録画の撮って出し名（`ScreenRecording_*.mov` など）は、**中身をフレーム抽出して目視で
   確認してから**内容の分かる名前に付け替える。既存READMEの対応表も根拠になる
3. スクリプトが `os.path.dirname` を重ねてリポジトリルートを求めている場合、
   移動先の階層の深さが変わっていないか確認する
4. 参照の張り替え漏れを潰す:
   ```sh
   grep -rn "<旧パス>" --include='*.md' --include='*.py' --include='*.sh' --include='*.rb' .
   ```
5. **動画のビルドスクリプトを触ったら、出力が既存の完成品と一致することを確認する**。
   出力先を差し替えて（`SHORTS_OUT_DIR=/tmp/shorts`）ビルドし、
   映像は `ffmpeg -i new -i old -lavfi ssim -f null -`（全フレーム `All:1.000000`）、
   音声は `ffmpeg -i x -map 0:a -f md5 -` の一致で判定する。
   合わない場合は耳で詰めた値が導出式とズレていることが多いので、**導出をやめて
   実測値を引数に書く**（推測で作り直さない）

## 関連スキル

- Shorts販促動画の作り方: `zzzmisa-shorts-video`
- ASCへの入稿・リリース手順: `zzzmisa-ios-release`
- 新規アプリの雛形: `zzzmisa-new-app`

各リポジトリ側の実際の内容（シーン秒数・文言・機種）は、必ずそのリポジトリの
`promo/README.md` を読んで確認する。**このスキルには規約だけを書き、
アプリ固有の値は書かない。**
