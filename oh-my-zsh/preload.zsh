#!/bin/zsh

_plugins=(git golang httpie python pyenv ripgrep)

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

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
# End Python
