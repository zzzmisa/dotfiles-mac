DESIRED_VERSION="3.3.0"

# rubyコマンドが存在する場合、バージョンをチェック
if type ruby > /dev/null 2>&1; then
  # "ruby --version" は "ruby 3.3.0 (2023-12-25 revision xx) [arm64-darwin23]" のような形式で出力されるので、
  # awkで2番目フィールド（バージョン番号）を抽出
  CURRENT_VERSION=$(ruby --version | awk '{print $2}')
  
  # バージョン比較（現在のバージョンが希望と同じか新しい場合）
  if [ "$(printf '%s\n' "$DESIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$DESIRED_VERSION" ] && [ "$CURRENT_VERSION" != "$DESIRED_VERSION" ]; then
    echo "Ruby is already up to date (v$CURRENT_VERSION)"
    exit 0
  elif [ "$CURRENT_VERSION" = "$DESIRED_VERSION" ]; then
    echo "Ruby is already at the desired version (v$CURRENT_VERSION)"
    exit 0
  else
    echo "Updating Ruby from v$CURRENT_VERSION to v$DESIRED_VERSION"
  fi
fi

rbenv install $DESIRED_VERSION
rbenv rehash
rbenv global $DESIRED_VERSION
