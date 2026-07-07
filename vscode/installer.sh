#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"

# codeコマンドがなければ
# Homebrew経由でVSCodeをインストール
if ! type code > /dev/null 2>&1; then
  source "$script_dir/../homebrew/install-homebrew.sh"
  brew install --cask visual-studio-code
fi

# settings.jsonの設置
ln -sf "$script_dir/settings.json" ~/Library/Application\ Support/Code/User/

# プラグインのインストール
pkglist=(
  anthropic.claude-code # Claude Code for VS Code
  dbaeumer.vscode-eslint # ESLint
  dart-code.flutter # Flutter
  eamodio.gitlens # GitLens — Git supercharged
  esbenp.prettier-vscode # Prettier - Code formatter
  github.copilot # GitHub Copilot
  ms-ceintl.vscode-language-pack-ja # Japanese Language Pack for Visual Studio Code
  openai.chatgpt # Codex – OpenAI’s coding agent pre-release
  stylelint.vscode-stylelint # Stylelint
  yzane.markdown-pdf # Markdown to PDF
  # 3w36zj6.textlint # textlintコミュニティ版
  # github.vscode-github-actions
  # htmlhint.vscode-htmlhint
  # Vue.volar # Vue - Official（Veturの後継）
  # ritwickdey.liveserver # 最終更新が古いため必要になったら再検討
)

for i in "${pkglist[@]}"; do
  code --install-extension "$i"
done

echo 👍 VSCode setting is done!
