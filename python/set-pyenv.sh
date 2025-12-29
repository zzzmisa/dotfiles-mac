DESIRED_VERSION="3.14.2"

# pythonコマンドが存在する場合、バージョンをチェック
if type python > /dev/null 2>&1; then
  CURRENT_VERSION=$(python --version 2>&1 | awk '{print $2}')
  
  # バージョン比較（現在のバージョンが希望と同じか新しい場合）
  if [ "$(printf '%s\n' "$DESIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$DESIRED_VERSION" ] && [ "$CURRENT_VERSION" != "$DESIRED_VERSION" ]; then
    echo "Python is already up to date (v$CURRENT_VERSION)"
    exit 0
  elif [ "$CURRENT_VERSION" = "$DESIRED_VERSION" ]; then
    echo "Python is already at the desired version (v$CURRENT_VERSION)"
    exit 0
  else
    echo "Updating Python from v$CURRENT_VERSION to v$DESIRED_VERSION"
  fi
fi

pyenv install $DESIRED_VERSION
pyenv rehash
pyenv global $DESIRED_VERSION