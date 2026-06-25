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

## オリジナルシェル関数

App Store提出用の動画サイズに変換する。

```
app-preview-iphone "ScreenRecording_06-25-2026 08-43-06_1.MP4"
app-preview-ipad "ScreenRecording_06-25-2026 08-43-06_1.MP4"
```
