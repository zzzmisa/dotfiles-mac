#!/usr/bin/env zsh

dotfiles_environment_file() {
  print -r -- "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-mac/environment"
}

resolve_dotfiles_environment() {
  local requested_environment="${1:-${DOTFILES_ENV:-}}"
  local environment_file
  environment_file="$(dotfiles_environment_file)"

  if [[ -z "$requested_environment" && -r "$environment_file" ]]; then
    IFS= read -r requested_environment < "$environment_file"
  fi

  if [[ -z "$requested_environment" ]]; then
    if [[ ! -t 0 ]]; then
      echo "Usage: zsh installer.sh private|office"
      return 1
    fi

    printf "Press O for office use, press P for private use :  "
    IFS= read -r requested_environment
  fi

  case "$requested_environment" in
    private|P|p)
      DOTFILES_ENV="private"
      ;;
    office|O|o)
      DOTFILES_ENV="office"
      ;;
    *)
      echo "Unknown environment: $requested_environment (expected private or office)"
      return 1
      ;;
  esac

  export DOTFILES_ENV
  mkdir -p "${environment_file:h}"
  print -r -- "$DOTFILES_ENV" > "$environment_file"
}
