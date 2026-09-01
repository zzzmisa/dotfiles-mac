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
2. フォルダ直下のインストーラを、利用環境を指定して実行する。
   ```
   zsh installer.sh private
   zsh installer.sh office
   ```
   選択した環境は `~/.config/dotfiles-mac/environment` に保存され、各インストーラと
   zsh設定で共通して使用される。引数を省略した場合は保存済みの環境を使用し、
   まだ保存されていなければ対話形式で選択する。
3. 各フォルダ内のインストーラのみ実行することもできる。
   ```
   zsh vscode/installer.sh office
   zsh vim/installer.sh
   ```
   各インストーラはスクリプト自身の位置を基準にパスを解決するため、どのディレクトリから実行してもよい。
4. Private環境では、続けて非公開リポジトリ `zzzmisa/dotfiles-mac-private` を並置でcloneし、
   そのインストーラを実行する（Private用エージェントプロファイル・`zzzmisa-` スキル・メモリはそちらにある）。

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

## Private / Office のインストール方針

両方の環境に、汎用的なコーディング・動画作成の設定を入れる。
iOSアプリ、Hugo、YouTubeチャンネル、個人データに関する設定はPrivateだけに入れる。
既存のOffice固有ツールはOfficeだけに入れる。

オリジナルコマンドとエージェントスキルのプレフィックスは、Private専用を
`zzzmisa-`、Private / Office共通を `misa-` とする。

主な分類は次のとおり。

| 対象 | Private / Office共通 | Privateのみ |
| --- | --- | --- |
| mise | Node.js、Python、Ruby、Snyk、uv | Flutter、Hugo、XcodeGen |
| VS Code | ESLint、Prettier、GitLens、Copilot、Claude、Codexなど | Flutter拡張 |
| 動画・音声 | ffmpeg、CapCut、ImageMagick、TTS | YouTube Shorts制作スキル |
| zsh | mise、共通コマンド | Antigravity、App Store Connect、App Preview変換 |
| エージェント | GitHub Issue・PR、マージ後の掃除 | iOS・App Store・SNS・写真整理・個人開発メモリ |

エージェントプロファイルは、Officeでは汎用的なコーディング方針だけを含む
`coding-agent/profile/AGENTS.office.md` を使用する。
Private用のプロファイル（AGENTS.md）、Private専用の `zzzmisa-` スキル、エージェントメモリは、
エージェントが公開審査なしで自由に書き込めるよう、非公開リポジトリ
`zzzmisa/dotfiles-mac-private` で管理する（`zzzmisa-slide-compress` は両環境共通のためこのリポジトリ）。

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
`tts/aivisspeech-dict.sh export` で `tts/user-dict.private.json` または
`tts/user-dict.office.json` に書き出してコミットしておく
（新しいMacでは `import` で復元する）。

この環境を使うエージェントスキル: `zzzmisa-shorts-video`
（YouTube Shorts販促動画の制作。dotfiles-mac-private の `coding-agent/skills/zzzmisa-shorts-video`）。

## オリジナルシェル関数

### App Preview動画の変換

App Store提出用の動画サイズに変換する。

```
zzzmisa-resize-video-for-appstore-iphone "ScreenRecording_06-25-2026 08-43-06_1.MP4"
zzzmisa-resize-video-for-appstore-ipad "ScreenRecording_06-25-2026 08-43-06_1.MP4"
```

## オリジナルコマンド（bin/）

`bin/common/` は両方の環境、`bin/private/` はPrivate環境だけで `.zshrc` のPATHに追加され、
ターミナルからそのまま実行できる。

### mainにマージ済みのローカルブランチとworktreeの削除

`git fetch --prune` を実行したあと、`main` にマージ済みのローカルブランチと、そのブランチに対応するworktreeを削除する。
`main`、`master`、`develop`、`dev`、現在のブランチは削除対象外。
リモートブランチは削除しない。

squashマージされたブランチはGitでは検出できないため削除されない。その補完も含めた掃除は
`misa-merge-cleanup` スキル（`coding-agent/skills/misa-merge-cleanup`）が
このコマンドを第一段階として呼び出す形で行う。

```
misa-delete-merged-local-branches
```

基準ブランチを指定する場合:

```
misa-delete-merged-local-branches develop
misa-delete-merged-local-branches origin/main
```

### Claude Code リモートコントロールの一括起動

Private環境だけで使用できる。

`~/mySources` 配下のプロジェクトごとに `claude remote-control` サーバーを起動する。
外出前にこれを1回実行しておけば、claude.ai/code やスマホアプリから各プロジェクトを操作できる。

起動済みのプロジェクトはスキップするため、何度実行しても二重起動しない。
セッション名にはプロジェクト名がプレフィックスとして付く（`--remote-control-session-name-prefix`）ので、
claude.ai/code 側でどのプロジェクトのセッションか判別できる。

引数なしで起動するプロジェクトはスクリプト冒頭の `default_projects` を編集する。

```
zzzmisa-remote-control                   # デフォルトのプロジェクトを起動
zzzmisa-remote-control chibireco cv      # 指定したプロジェクトだけ起動
zzzmisa-remote-control status            # 起動状況を表示
zzzmisa-remote-control stop              # すべて停止
zzzmisa-remote-control stop chibireco    # 指定したプロジェクトだけ停止
```

ログは `~/.local/state/zzzmisa/remote-control/<プロジェクト名>.log` に追記される。
