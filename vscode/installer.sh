# codeコマンドがなければ
# Homebrew経由でVSCodeをインストール
if !(type code > /dev/null 2>&1); then
  source homebrew/install-homebrew.sh
  brew install --cask visual-studio-code
fi

# settings.jsonの設置
ln -sf $PWD/vscode/settings.json ~/Library/Application\ Support/Code/User/

# プラグインのインストール
pkglist=(
  # ESLint
  dbaeumer.vscode-eslint 
  # GitLens — Git supercharged
  eamodio.gitlens
  # GitHub Copilot
  github.copilot-chat
  github.copilot
  # Japanese Language Pack for Visual Studio Code
  ms-ceintl.vscode-language-pack-ja 
  # Vetur
  octref.vetur
  # Prettier - Code formatter
  esbenp.prettier-vscode
)

for i in ${pkglist[@]}; do
  code --install-extension $i
done

echo 👍 VSCode setting is done!