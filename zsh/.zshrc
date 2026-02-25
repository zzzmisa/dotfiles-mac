# nodenv setting
eval "$(nodenv init -)"

# pyenv setting
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
eval "$(pyenv init -)"

# rbenv setting
eval "$(rbenv init -)"
# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"