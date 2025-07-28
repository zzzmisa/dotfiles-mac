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
  dbaeumer.vscode-eslint # ESLint
  eamodio.gitlens # GitLens — Git supercharged
  esbenp.prettier-vscode # Prettier - Code formatter
  github.copilot-chat # GitHub Copilot
  github.copilot
  ms-ceintl.vscode-language-pack-ja # Japanese Language Pack for Visual Studio Code
  stylelint.vscode-stylelint # Stylelint
  yzane.markdown-pdf # Markdown to PDF
  # 3w36zj6.textlint # textlintコミュニティ版
  # github.vscode-github-actions
  # htmlhint.vscode-htmlhint
  # octref.vetur # Vetur（しばらく使わない）
  # ritwickdey.liveserver
)

for i in ${pkglist[@]}; do
  code --install-extension $i
done

echo 👍 VSCode setting is done!