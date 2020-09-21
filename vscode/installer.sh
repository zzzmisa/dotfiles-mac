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