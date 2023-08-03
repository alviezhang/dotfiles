#!/bin/zsh

ZSH_THEME="bira"

# Language
export LANG=en_US.UTF-8

# macOS
function macOS() {
    # export LANG=en_US.UTF-8
    # export PATH="$HOME/Library/Python/3.11/bin:$PATH"
}

# Linux
function linux() {
}

if [ "$OS" = "linux" ]; then
    linux
elif [ "$OS" = "macOS" ]; then
    macOS
fi

export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Go Settings
export GOPATH=$HOME/.go
mkdir -p $GOPATH
export PATH=$GOPATH/bin:$PATH
# export GOPRIVATE=github.com/AfterShip/*
# End

# Python
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init --path)"
eval "$(pyenv init -)"
# End Python

# Rustup
export PATH=$HOME/.cargo/bin:$PATH
# End rustup

# Proxy Settings
function proxy() {
    export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890
}

function direct() {
    unset https_proxy;
    unset http_proxy;
    unset all_proxy;
}

[[ -s "/home/alvie/.gvm/scripts/gvm" ]] && source "/home/alvie/.gvm/scripts/gvm"

# File End
