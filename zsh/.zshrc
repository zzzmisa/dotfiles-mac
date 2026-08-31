dotfiles_environment_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-mac/environment"
if [[ -r "$dotfiles_environment_file" ]]; then
  IFS= read -r DOTFILES_ENV < "$dotfiles_environment_file"
  export DOTFILES_ENV
fi

# mise setting
if type mise > /dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -f "$HOME/dotfiles-mac/zsh/functions.zsh" ]]; then
  source "$HOME/dotfiles-mac/zsh/functions.zsh"
fi

# dotfiles-macの共通コマンド
export PATH="$HOME/dotfiles-mac/bin/common:$PATH"

# uv tool installの実行ファイル置き場（photo-cleanup, osxphotos等）
export PATH="$HOME/.local/bin:$PATH"

if [[ "$DOTFILES_ENV" = "private" ]]; then
  [[ -f "$HOME/dotfiles-mac/zsh/private.zsh" ]] && source "$HOME/dotfiles-mac/zsh/private.zsh"
  [[ -f "$HOME/dotfiles-mac/zsh/functions.private.zsh" ]] && source "$HOME/dotfiles-mac/zsh/functions.private.zsh"
  export PATH="$HOME/dotfiles-mac/bin/private:$PATH"
fi

unset dotfiles_environment_file
