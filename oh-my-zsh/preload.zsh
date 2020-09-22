#!/bin/zsh

_plugins=(git golang httpie python pyenv)

# Platform specific configurations
UNAME=`uname`

if [ "$UNAME" = "Linux" ]; then
    export OS=linux
    os_plugins=()
elif [ "$UNAME" = "Darwin" ]; then
    export OS=macOS
    os_plugins=(osx brew)
fi

plugins=(${_plugins} ${os_plugins})