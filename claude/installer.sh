#!/usr/bin/env zsh
set -e

# claudeコマンドがない場合のみインストール
# cf. https://code.claude.com/docs/ja/setup
if ! type claude > /dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo "👍 Claude CLI setup is done!"