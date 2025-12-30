DESIRED_VERSION="21.6.0"

# nodeコマンドが存在する場合、バージョンをチェック
if type node > /dev/null 2>&1; then
  # "node -v" は "v21.6.0" のような形式で出力されるので、
  # sedでvプレフィックスを削除してバージョン番号を抽出
  CURRENT_VERSION=$(node -v | sed 's/v//')
  
  # バージョン比較（現在のバージョンが希望と同じか新しい場合）
  if [ "$(printf '%s\n' "$DESIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$DESIRED_VERSION" ] && [ "$CURRENT_VERSION" != "$DESIRED_VERSION" ]; then
    echo "Node.js is already up to date (v$CURRENT_VERSION)"
    exit 0
  elif [ "$CURRENT_VERSION" = "$DESIRED_VERSION" ]; then
    echo "Node.js is already at the desired version (v$CURRENT_VERSION)"
    exit 0
  else
    echo "Updating Node.js from v$CURRENT_VERSION to v$DESIRED_VERSION"
  fi
fi

nodenv install $DESIRED_VERSION
nodenv rehash
nodenv global $DESIRED_VERSION