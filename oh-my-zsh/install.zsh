#!/bin/zsh

if [ `uname` = "Darwin" ]; then
    sed -i '' "s|plugins=(git)|. $PWD/preload.zsh|g" ~/.zshrc
else
    sed -i "s|plugins=(git)|. $PWD/preload.zsh|g" ~/.zshrc
fi
