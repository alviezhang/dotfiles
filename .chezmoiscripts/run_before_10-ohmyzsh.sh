#!/bin/bash
set -e

command -v zsh >/dev/null 2>&1 || exit 0

OHMYZSH_DIR="$HOME/.oh-my-zsh"
OHMYZSH_SH="$OHMYZSH_DIR/oh-my-zsh.sh"

[ -s "$OHMYZSH_SH" ] && exit 0

command -v curl >/dev/null 2>&1 || { echo "curl not found"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git not found"; exit 1; }

# Handle a partial/broken install (directory exists, but main script missing).
if [ -d "$OHMYZSH_DIR" ]; then
  backup="${OHMYZSH_DIR}.bak.$(date +%s)"
  mv "$OHMYZSH_DIR" "$backup"
fi

install_script="$(mktemp)"
trap 'rm -f "$install_script"' EXIT
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$install_script"

RUNZSH=no CHSH=no KEEP_ZSHRC=yes ZSH="$OHMYZSH_DIR" sh "$install_script"
