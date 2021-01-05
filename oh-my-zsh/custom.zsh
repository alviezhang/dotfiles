#!/bin/zsh

ZSH_THEME="bira"

# macOS
function macOS() {
    export LANG=en_US.UTF-8
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
export PATH="~/.local/bin:$PATH"

# Go Settings
export GOPATH=~/code/go
mkdir -p $GOPATH
export PATH=$GOPATH/bin:$PATH
# End

# Proxy Settings
function proxy() {
    export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890
}

function direct() {
    unset https_proxy;
    unset http_proxy;
    unset all_proxy;
}

# File End
