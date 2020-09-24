# codeコマンドがなければ
# Homebrew経由でVSCodeをインストール
if !(type code > /dev/null 2>&1); then
  sh homebrew/installer.sh
  brew cask install visual-studio-code
fi

# settings.jsonの設置
ln -sf $PWD/vscode/settings.json ~/Library/Application\ Support/Code/User/

# プラグインのインストール
pkglist=(
  dbaeumer.vscode-eslint 
  ms-ceintl.vscode-language-pack-ja # 日本語化
  octref.vetur # Vueの単一ファイルコンポーネントのシンタックスハイライトやスニペットなど
)

for i in ${pkglist[@]}; do
  code --install-extension $i
done

echo 👍 VSCode setting is done!