# エージェント向けプロファイル（Misaの個人開発の進め方）

このファイルの実体は `dotfiles-mac/coding-agent/profile/AGENTS.md`。インストーラで
`~/.claude/CLAUDE.md`（Claude Code）と `~/.codex/AGENTS.md`（Codex）に
シンボリックリンクされ、全プロジェクトで常時読み込まれる。
プロジェクト固有の知識はここに書かず、各リポジトリの CLAUDE.md / AGENTS.md / docs に書くこと。

## 背景

- 本業はiOS（Swift）/ Flutterのアプリ開発者
- Pythonとエージェントフレームワーク（LangGraph等）は学習中の新領域なので、その分野では前提の説明を少し厚めにする
- やり取りは日本語で行う

## 個人開発の方針

- 個人開発アプリは収益化が目標。バックエンドなし（完全オフライン）＋買い切りIAPが必須条件で、サーバー運用コストは持たない
- 無料枠・無料ツールを優先する

## 進め方の好み

- 途中確認を挟まず自律的に進めてよい（破壊的操作と外部への公開操作は除く）
- 動作検証はシミュレータより実機インストールを優先する
- PRのマージとApp Storeへのリリース作業はMisa自身が行う。エージェントは実施しない
- 公開リポジトリへの `git push` は、Misaが内容を確認してから自身で行う
- Misa自身もコードを直接編集する。コミット前に `git status` で未コミットの変更を確認し、Misaの変更をエージェントの変更と同じコミットに混ぜないこと

## 検証デバイス

- iOS実機: `MisaのiPhone`（iPhone 17）、`ミサのiPad`
- Android実機: HUAWEI nova lite 3（Android 9 / API 28）
  - adb接続には開発者向けオプションの「"充電のみ"モードでADBデバッグを許可」をONにし、ファイル転送モードにする必要がある
  - 検証中のスリープ抑止は `adb shell svc power stayon usb`
- iOS実機・シミュレータの詳細な手順やデバッグのコツは、install系スキル（`zzzmisa-install-iphone` 等）の references を参照
