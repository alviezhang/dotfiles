#!/bin/bash
set -e
mkdir -p ~/.vim/bundle
[ -d ~/.vim/bundle/Vundle.vim ] || \
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
