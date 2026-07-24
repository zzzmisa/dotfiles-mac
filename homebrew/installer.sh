#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# Xcodeライセンスが未同意だとbrew/flutter/cocoapods等が失敗するため、同意を促す。
# 同意後、初回起動時の追加コンポーネント（実機通信用のMobileDevice等）もインストールする
accept_xcode_license() {
  # 参照先がCLTのままでXcode.appがある場合（mas経由の新規インストール直後など）は切り替える
  if xcodebuild -version 2>&1 | grep -q "requires Xcode" && [ -d /Applications/Xcode.app ]; then
    echo "開発ツールの参照先をXcode.appに切り替えます（パスワード入力が必要）"
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  fi
  if xcodebuild -version 2>&1 | grep -q "license"; then
    echo "Xcodeライセンスが未同意です。同意します（パスワード入力が必要）"
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch
  fi
}

# Homebrewインストール
source "$script_dir/install-homebrew.sh"

# Rosettaインストール
softwareupdate --install-rosetta

# Brewfile実行前: 既存Xcodeのライセンス未同意でbrew bundleが途中で止まるのを防ぐ
accept_xcode_license

# Brewfile実行
printf "Press O for office use, press any key for private use :  "
read install_env
if [ "$install_env" = "O" ]; then
  brew bundle --file "$script_dir/BrewfileOffice"
else
  brew bundle --file "$script_dir/BrewfilePrivate"
fi

# Brewfile実行後: masでXcodeが新規インストールされた場合に備えて再チェック
accept_xcode_license

echo 👍 Homebrew setting is done!
