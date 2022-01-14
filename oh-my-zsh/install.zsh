#!/bin/zsh

if [ `uname` = "Darwin" ]; then
    echo "Patching macOS"
    sed -i '' "s|plugins=(git)|. $PWD/preload.zsh|g" ~/.zshrc
else
    echo "Patching Linux"
    sed -i "s|plugins=(git)|. $PWD/preload.zsh|g" ~/.zshrc
fi
