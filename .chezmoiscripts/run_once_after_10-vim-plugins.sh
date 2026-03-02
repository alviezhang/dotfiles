#!/bin/bash
set -e
plug_vim="$HOME/.vim/autoload/plug.vim"
[ -f "$plug_vim" ] || \
  curl -fLo "$plug_vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
if [ -t 0 ]; then
  vim +'PlugInstall --sync' +qa
else
  echo "No terminal available — run :PlugInstall in vim manually."
fi
