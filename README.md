# Dotfiles For Mac

## 最新の動作確認環境

- OS...macOS 26.1
- チップ...Apple M1
- シェル.../bin/zsh

## 使い方

1. `dotfiles-mac`フォルダ直下に移動
   ```
   cd dotfiles-mac
   ```
2. フォルダ直下のインストーラを実行すると、すべての設定がインストールされる。
   ```
   zsh installer.sh
   ```
3. 各フォルダ内のインストーラのみ実行することもできる。
   ```
   zsh vim/installer.sh
   ```
   各インストーラはスクリプト自身の位置を基準にパスを解決するため、どのディレクトリから実行してもよい。

## 開発ツールと依存関係の管理方針

ツールの管理元は、次の基準で使い分ける。

```text
Homebrew
├── mise自体
├── macOSアプリ
└── ffmpegなどのネイティブCLI

mise
├── Node.js / Python / Ruby / Flutter
├── Hugo / uv / XcodeGen
└── Snykなどの独立した開発CLI

プロジェクト内
├── uv：Python依存関係
├── npm / pnpm：JavaScript依存関係
└── Bundler：FastlaneなどのRuby依存関係
```

## 読み上げ音声の生成環境（tts/）

テキストから読み上げ音声を作る汎用環境。販促動画のナレーションに限らず、
デモ動画・解説動画の音声など用途は問わない。日本語は AivisSpeech
（GUIアプリ・手動インストール）、英語や中国語は Qwen3-TTS（`~/.venvs/qwen-tts`）。
どちらも商用利用可。

```
zsh tts/installer.sh
```

セットアップの詳細と使い方は [tts/README.md](tts/README.md)。
読み方・アクセント辞書はAivisSpeech側に保存されdotfilesの管理外なので、
`tts/aivisspeech-dict.sh export` で `tts/user-dict.json` に書き出してコミットしておく
（新しいMacでは `import` で復元する）。

この環境を使うエージェントスキル: `zzzmisa-shorts-video`
（`coding-agent/skills/zzzmisa-shorts-video`、YouTube Shorts販促動画の制作）。

## オリジナルシェル関数

### App Preview動画の変換

App Store提出用の動画サイズに変換する。

```
zzzmisa-resize-video-for-appstore-iphone "ScreenRecording_06-25-2026 08-43-06_1.MP4"
zzzmisa-resize-video-for-appstore-ipad "ScreenRecording_06-25-2026 08-43-06_1.MP4"
```

## オリジナルコマンド（bin/）

`bin/` 配下のスクリプトは `.zshrc` でPATHに追加され、ターミナルからそのまま実行できる。

### mainにマージ済みのローカルブランチとworktreeの削除

`git fetch --prune` を実行したあと、`main` にマージ済みのローカルブランチと、そのブランチに対応するworktreeを削除する。
`main`、`master`、`develop`、`dev`、現在のブランチは削除対象外。
リモートブランチは削除しない。

squashマージされたブランチはGitでは検出できないため削除されない。その補完も含めた掃除は
`zzzmisa-merge-cleanup` スキル（`coding-agent/skills/zzzmisa-merge-cleanup`）が
このコマンドを第一段階として呼び出す形で行う。

```
zzzmisa-delete-merged-local-branches
```

基準ブランチを指定する場合:

```
zzzmisa-delete-merged-local-branches develop
zzzmisa-delete-merged-local-branches origin/main
```
