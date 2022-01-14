# --- Finderの設定 ---
# 隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -boolean true

# すべてのファイル名拡張子を表示（Finder > 環境設定 > 詳細 からも設定可）
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

killall Finder

# --- Dockの設定 ---
# “自動的に非表示”をオン（Dockを右クリックでも設定可）
defaults write com.apple.dock autohide -bool true

killall Dock

# --- SystemUIServer関係の設定 ---
# 時計で日付を表示（例：9月20日(木) 23:00、メニューバー右上の時計からも設定可）
defaults write com.apple.menuextra.clock DateFormat -string 'EEE MMM d HH:mm'

# バッテリーの割合（%）を表示（メニューバー右上のバッテリーからも設定可）
defaults write com.apple.menuextra.battery ShowPercent YES

# スクリーンショットのドロップシャドウを付けない
defaults write com.apple.screencapture disable-shadow -boolean true
killall SystemUIServer

# ---　トラックパッドの設定　---
# シングルタップでクリック（再起動必要）
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -bool true

# ---　その他の設定　---
# テキストエディットをリッチテキストから標準テキストに変更（テキストエディットの環境設定からも設定可）
defaults write com.apple.TextEdit RichText -int 0
# 自動で頭文字を大文字にしない
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

echo 👍 MacOS setting is done, please reboot!
