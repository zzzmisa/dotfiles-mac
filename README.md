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
