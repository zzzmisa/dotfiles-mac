#!/usr/bin/env zsh

# --- 失敗した設定を記録する仕組み ---
failed_settings=()
safari_failed=false

# defaults コマンドを実行し、失敗したら failed_settings に記録して ❌ を表示する
apply_default() {
  local description="$1"
  shift
  if defaults "$@"; then
    return 0
  else
    failed_settings+=("$description")
    echo "❌ $description"
    return 1
  fi
}

# 実行中のプロセスだけを対象に killall する（"No matching processes" のノイズを抑制、失敗しても未達成扱いにしない）
safe_killall() {
  if pgrep -x "$1" >/dev/null 2>&1; then
    killall "$1" 2>/dev/null || true
  fi
}

# --- ControlCenterの設定 ---
apply_default "Bluetoothを常に表示" -currentHost write com.apple.controlcenter Bluetooth -int 18 # Bluetoothを常に表示
apply_default "サウンドを常に表示" -currentHost write com.apple.controlcenter Sound -int 18 # サウンドを常に表示
apply_default "バッテリーの割合を常に表示" -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true # バッテリーの割合を常に表示

# --- Finderの設定 ---
apply_default "すべてのファイル名拡張子を表示" write -g AppleShowAllExtensions -bool true # すべてのファイル名拡張子を表示（Finder > 環境設定 > 詳細 からも設定可）
apply_default "隠しファイルを表示" write com.apple.finder AppleShowAllFiles -bool true # 隠しファイルを表示
apply_default "デスクトップのアイコンを消す" write com.apple.finder CreateDesktop -bool false # デスクトップのアイコンを消す
apply_default "パスバーを表示" write com.apple.finder ShowPathbar -bool true # パスバーを表示

# --- Dockの設定 ---
apply_default "Dockを自動的に非表示にする" write com.apple.dock autohide -bool true # “自動的に非表示”をオン（Dockを右クリックでも設定可）

# --- Safariの設定 ---
apply_default "Safariの開発メニューを表示（SandboxBroker）" write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true || safari_failed=true # 開発メニューを表示
apply_default "Safariの開発メニューを表示（IncludeDevelopMenu）" write com.apple.Safari IncludeDevelopMenu -bool true || safari_failed=true # 同上
apply_default "SafariのWebデベロッパ用機能を有効化（WebKitDeveloperExtras）" write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true || safari_failed=true # 同上
apply_default "SafariのWebデベロッパ用機能を有効化（WebKit2DeveloperExtras）" write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true || safari_failed=true # 同上

# --- SystemUIServer（メニューバー）の設定 ---
apply_default "時計で日付を表示" write com.apple.menuextra.clock DateFormat -string 'EEE MMM d HH:mm' # 時計で日付を表示（例：9月20日(木) 23:00、メニューバー右上の時計からも設定可）

# --- SystemUIServer（スクリーンショット）の設定 ---
apply_default "スクリーンショットのドロップシャドウを付けない" write com.apple.screencapture disable-shadow -bool true # スクリーンショットのドロップシャドウを付けない
if ! mkdir -p ~/Desktop/Screenshots; then
  failed_settings+=("~/Desktop/Screenshots フォルダの作成")
  echo "❌ ~/Desktop/Screenshots フォルダの作成"
fi
apply_default "スクリーンショットの保存先を変更" write com.apple.screencapture location ~/Desktop/Screenshots # スクリーンショットの保存先をデスクトップのScreenshotsフォルダに変更

# ---　SystemUIServer（トラックパッド）の設定　---
apply_default "シングルタップでクリック（AppleMultitouchTrackpad）" write com.apple.AppleMultitouchTrackpad Clicking -bool true # シングルタップでクリック（再起動必要）
apply_default "シングルタップでクリック（AppleBluetoothMultitouchTrackpad）" write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
apply_default "タップでクリック（グローバル設定）" write -g com.apple.mouse.tapBehavior -int 1
apply_default "タップでクリック（ログイン画面にも反映）" -currentHost write -g com.apple.mouse.tapBehavior -int 1

# ---　TextEdit・テキスト関係の設定　---
apply_default "テキストエディットを標準テキストに変更" write com.apple.TextEdit RichText -bool false # テキストエディットをリッチテキストから標準テキストに変更（テキストエディットの環境設定からも設定可）
apply_default "自動で頭文字を大文字にしない" write -g NSAutomaticCapitalizationEnabled -bool false # 自動で頭文字を大文字にしない

# --- 反映のための再起動 ---
safe_killall ControlCenter
safe_killall Dock
safe_killall Finder
safe_killall Safari
safe_killall SystemUIServer
safe_killall TextEdit

# --- 結果表示 ---
if (( ${#failed_settings[@]} == 0 )); then
  echo 👍 MacOS setting is done, please reboot!
  exit 0
else
  echo "⚠️ MacOS setting is incomplete. 以下は手動で設定してください:"
  for item in "${failed_settings[@]}"; do
    echo "  - $item"
  done
  if [[ "$safari_failed" = true ]]; then
    echo "  - Safari → 設定 → 詳細 → 「Webデベロッパ用の機能を表示」をオンにする"
    echo "  - または ターミナルにフルディスクアクセスを許可して再実行する"
  fi
  exit 1
fi

# --- メモ ---
# -g=NSGlobalDomain, -currentHost=ログイン画面にも反映
