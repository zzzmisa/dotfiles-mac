---
name: zzzmisa-shorts-video
description: Build or update YouTube Shorts promo videos for Misa's apps with ffmpeg — scene composition, captions inside the Shorts UI safe area, narration (AivisSpeech / Qwen3-TTS), BGM, endcard, and export settings. Use when asked to create, fix, or 作り直す a Shorts動画 / 販促動画 / プロモ動画, or to change its テロップ・ナレーション・BGM・音量.
---

# YouTube Shorts販促動画の制作

実機収録・App Storeプレビューの素材から、ffmpegでShorts用の動画を組み立てる。
1080×1920・20秒前後・ナレーション＋BGM＋エンドカード付きが標準形。

## Workflow

このスキルが持つ知識（`references/`）と、**環境**（`dotfiles-mac` 側）と、
**素材とレシピ**（**アプリ側のリポジトリ**）は置き場所が違う。以下、どちらのものかを【】で示す。

アプリ側の置き場所は `zzzmisa-store-assets` の規約に従う（`promo/originals/` に原本、
`promo/scripts/` にスクリプト、`promo/youtube-shorts/` に完成品とレシピ）。
**シーン秒数・文言・機種などアプリ固有の値は毎回そのリポジトリの `promo/README.md` で
確認する**（このスキルにアプリ固有の値を書かないこと）。規約に移行していない
リポジトリでは、従来どおりREADME・docsを探す。

1. **【アプリ側】素材を確認する**。使えるのは2種類。
   - **実機収録の生素材** — キャプションが焼き込まれていない。文言を変えるならこちらから組み直す
   - **App Storeプレビューなどの完成品** — キャプション焼き込み済み。合成したホーム画面など
     生素材に存在しないシーンは、こちらから切り出して焼き込み済みのキャプションをパッチで隠す

   規約どおりのリポジトリなら、生素材は `promo/originals/recordings/`、完成品は
   `fastlane/previews/{locale}/`。シーン境界の実測値が `promo/app-store/notes.md` や
   各READMEに記録されていることが多いので、それも探す。
2. **【このスキル】構成を決める**。`references/composition.md` の型に沿う。
   フック→説明→アプリ画面→エンドカード。
3. **【アプリ側 or 新規】キャプションとエンドカードを生成する**。アプリ側の
   `promo/scripts/` に生成スクリプトがあれば流用する（文言・フォント・色がアプリの
   デザインに合わせてある）。なければ `references/composition.md` の要件で新規に作り、
   **アプリ側の `promo/scripts/` に置く**。
4. **【dotfiles-mac】ナレーションを生成する**。日本語=AivisSpeech、英語・中国語=Qwen3-TTS。
   環境構築と使い方は `dotfiles-mac/tts/README.md`。
   **【このスキル】**原稿の作り方・整音・音量設計は `references/audio.md`。
5. **【このスキル】合成する**。`references/ffmpeg.md` のレシピと罠を必ず読んでから書く。
6. **【このスキル】検証する**。`references/ffmpeg.md` の検証コマンドを全部通す。
   数フレーム抜き出してタイル画像にし、**必ず目視で確認する**（キャプションの位置・
   パッチの当たり・シーンの切れ目）。
7. **【アプリ側】レシピをリポジトリに残す**。合成は **`promo/scripts/build_shorts.sh
   <locale>` のように引数で回せるスクリプトにする**（ffmpegコマンドをREADMEに貼るだけに
   しない）。`promo/youtube-shorts/README.md` には切り出し秒数・ナレーション原稿・
   構成の判断理由を書く。**ナレーション音声ファイルも `narration/` に保管する**
   （TTSのバージョン差で再生成しても同じ音にならないため）。
   置き場所と命名の規約は `zzzmisa-store-assets`。

## 絶対に外さない設定

| 項目 | 値 | 理由 |
| --- | --- | --- |
| `-pix_fmt yuv420p` | **必須** | 指定しないとPNG overlayの影響で4:4:4になり、再生できない環境が出る |
| ラウドネス | **-14 LUFS前後** | YouTubeの正規化目標。小さい動画は上げてもらえず、小さいまま再生される |
| キャプション位置 | 上部 y=256 が安全 | Shorts UIが下端から約380pxを覆う。ただし下部配置の方が初速が良かった実績もあるので断定しない（composition.md） |
| 冒頭キャプション | **1フレーム目から** | 最初のフレームがサムネイルになる |

詳細と根拠は各referenceに書いてある。

- `references/composition.md` — 構成の型、Shorts UIのセーフエリア実測値、キャプション、エンドカード
- `references/audio.md` — ナレーション原稿の作り方、BGM、音量設計、ライセンス
- `references/ffmpeg.md` — 合成レシピ、ffmpegの罠、検証コマンド

素材・スクリプト・完成品の置き場所と命名は `zzzmisa-store-assets` を参照。

## 原則

- **動画は再現可能にする**。手作業の編集ソフトを使わず、ffmpegコマンドとして残す。
  1年後に文言を1つ変えたくなったとき、コマンドを直して流すだけで済む状態にする。
- **YouTubeへの投稿・ドラフト差し替え・説明欄の編集はMisa自身が行う**。
  エージェントはビルドとコミットと動画ファイルの受け渡しまで。
- **公開後の差し替えは慎重に**。YouTubeは動画ファイルの差し替えができず、再アップすると
  再生数・コメントがリセットされる。「手元のファイルを直す」と「投稿し直す」は別の判断。
- 素材の使い回しは視聴者に気づかれる。同じ映像を2回使うなら、画角か内容を変える。
  それが難しければ**そのシーンを削る**方が結果的に良い。
