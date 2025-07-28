# --- ControlCenterの設定 ---
defaults -currentHost write com.apple.controlcenter Bluetooth -int 18 # Bluetoothを常に表示 
defaults -currentHost write com.apple.controlcenter Sound -int 18 # サウンドを常に表示
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true # バッテリーの割合を常に表示

# --- Finderの設定 ---
defaults write AppleShowAllExtensions -bool true # すべてのファイル名拡張子を表示（Finder > 環境設定 > 詳細 からも設定可）
defaults write com.apple.finder AppleShowAllFiles -bool true # 隠しファイルを表示
defaults write com.apple.finder CreateDesktop -bool false # デスクトップのアイコンを消す
defaults write conm.apple.finder showPathbar -bool true # パスバーを表示

# --- Dockの設定 ---
defaults write com.apple.dock autohide -bool true # “自動的に非表示”をオン（Dockを右クリックでも設定可）

# --- Safariの設定 ---
defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true # 開発メニューを表示
defaults write com.apple.Safari IncludeDevelopMenu -bool true # 同上
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true # 同上
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true # 同上

# --- SystemUIServer（メニューバー）の設定 ---
defaults write com.apple.menuextra.clock DateFormat -string 'EEE MMM d HH:mm' # 時計で日付を表示（例：9月20日(木) 23:00、メニューバー右上の時計からも設定可）

# ---　トラックパッドの設定　---
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true # シングルタップでクリック（再起動必要）
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1

# ---　テキスト関係の設定　---
defaults write com.apple.TextEdit RichText -bool false # テキストエディットをリッチテキストから標準テキストに変更（テキストエディットの環境設定からも設定可）
defaults write -g NSAutomaticCapitalizationEnabled -bool false # 自動で頭文字を大文字にしない

# ---　その他の設定　---
defaults write com.apple.screencapture disable-shadow -bool true # スクリーンショットのドロップシャドウを付けない

# --- 反映のための再起動 ---
killall ControlCenter
killall Dock
killall Finder
killall Safari
killall SystemUIServer
killall TextEdit

echo 👍 MacOS setting is done, please reboot!

# --- メモ ---
# -g=NSGlobalDomain, -currentHost=ログイン画面にも反映