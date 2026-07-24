# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# mise setting
if type mise > /dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [ -f "$HOME/dotfiles-mac/zsh/functions.zsh" ]; then
  source "$HOME/dotfiles-mac/zsh/functions.zsh"
fi

# App Store Connect API credentials
[ -f "$HOME/.appstoreconnect/asc.env" ] && source "$HOME/.appstoreconnect/asc.env"
