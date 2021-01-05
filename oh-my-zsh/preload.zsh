#!/bin/zsh

_plugins=(git git-prune golang httpie python pyenv ripgrep)

# Platform specific configurations
UNAME=`uname`

if [ "$UNAME" = "Linux" ]; then
    export OS=linux
    os_plugins=()
elif [ "$UNAME" = "Darwin" ]; then
    export OS=macOS
    os_plugins=(osx macports)
fi

plugins=(${_plugins} ${os_plugins})
