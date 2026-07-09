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

## オリジナルシェル関数

### App Preview動画の変換

App Store提出用の動画サイズに変換する。

```
zzzmisa-resize-video-for-appstore-iphone "ScreenRecording_06-25-2026 08-43-06_1.MP4"
zzzmisa-resize-video-for-appstore-ipad "ScreenRecording_06-25-2026 08-43-06_1.MP4"
```

### mainにマージ済みのローカルブランチとworktreeの削除

`git fetch --prune` を実行したあと、`main` にマージ済みのローカルブランチと、そのブランチに対応するworktreeを削除する。
`main`、`master`、`develop`、`dev`、現在のブランチは削除対象外。
リモートブランチは削除しない。

```
zzzmisa-delete-merged-local-branches
```

基準ブランチを指定する場合:

```
zzzmisa-delete-merged-local-branches develop
zzzmisa-delete-merged-local-branches origin/main
```
