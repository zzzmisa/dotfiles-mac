#!/usr/bin/env zsh

# インストール済みのbrewの絶対パスを返す（PATHに通っていなくてもよい）。
# Apple Silicon優先、Intel Macも一応対応する
find_homebrew_binary() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      print -r -- "$candidate"
      return 0
    fi
  done
  return 1
}

# Homebrewがインストール済みなら、現在のプロセスに shellenv（PATH等）を反映する。
# 各installerは親から独立した zsh プロセスとして起動されるため、
# Homebrewインストール直後の shellenv は親や後続のプロセスに引き継がれない。
# そのため、brewを使うinstallerは処理の先頭でこの関数を呼ぶ。
# 未インストールなら何もせず 1 を返す（インストール自体は install-homebrew.sh が担当）。
ensure_homebrew_shellenv() {
  if type brew > /dev/null 2>&1; then
    return 0
  fi

  local brew_binary
  brew_binary="$(find_homebrew_binary)" || return 1
  eval "$("$brew_binary" shellenv)"
}
