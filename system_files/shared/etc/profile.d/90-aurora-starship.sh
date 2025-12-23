# shellcheck shell=sh
command -v starship >/dev/null 2>&1 || return 0

if [ -n "$BASH_VERSION" ]; then
  eval "$(starship init bash)"
fi
