#!/usr/bin/env zsh
set -e

script_dir="${0:A:h}"
source "$script_dir/../lib/environment.zsh"
resolve_dotfiles_environment "${1:-}" || exit 1

# codeコマンドがなければ
# Homebrew経由でVSCodeをインストール
if ! type code > /dev/null 2>&1; then
  source "$script_dir/../homebrew/install-homebrew.sh"
  brew install --cask visual-studio-code
fi

# settings.jsonの設置
ln -sf "$script_dir/settings.json" ~/Library/Application\ Support/Code/User/

# プラグインのインストール
common_extensions=(
  anthropic.claude-code # Claude Code for VS Code
  dbaeumer.vscode-eslint # ESLint
  eamodio.gitlens # GitLens — Git supercharged
  esbenp.prettier-vscode # Prettier - Code formatter
  github.copilot # GitHub Copilot
  ms-ceintl.vscode-language-pack-ja # Japanese Language Pack for Visual Studio Code
  openai.chatgpt # Codex – OpenAI’s coding agent pre-release
  stylelint.vscode-stylelint # Stylelint
  yzane.markdown-pdf # Markdown to PDF
  # github.vscode-github-actions
  # htmlhint.vscode-htmlhint
  # Vue.volar # Vue - Official（Veturの後継）
  # ritwickdey.liveserver # 最終更新が古いため必要になったら再検討
)

private_extensions=(
  dart-code.flutter # Flutter
)

extensions=("${common_extensions[@]}")
if [[ "$DOTFILES_ENV" = "private" ]]; then
  extensions+=("${private_extensions[@]}")
fi

for i in "${extensions[@]}"; do
  code --install-extension "$i"
done

echo 👍 VSCode setting is done!
