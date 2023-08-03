#!/bin/zsh

ZSH_THEME="bira"

# Language
export LANG=en_US.UTF-8

# macOS
function macOS() {
    # export PATH="$HOME/Library/Python/3.11/bin:$PATH"
    export PATH=/opt/google-cloud-sdk/bin:$PATH

    # Macports extra flags
    export LDFLAGS=-L/opt/local/lib/
    export CPPFLAGS=-I/opt/local/include/
}

# Linux
function linux() {

}

if [ "$OS" = "linux" ]; then
    linux
elif [ "$OS" = "macOS" ]; then
    macOS
fi

export PATH="$HOME/.local/bin:/usr/local/sbin:$PATH"

# NVM
[[ -s "/opt/local/share/nvm/init-nvm.sh" ]] && source /opt/local/share/nvm/init-nvm.sh

# Begin go
export GOPATH=$HOME/.go
mkdir -p $GOPATH
export PATH=$GOPATH/bin:$PATH
# [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
# export GOPRIVATE=github.com/AfterShip/*
# End go

# Begin pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
# End pyenv

# Rustup
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
# End rustup

# Begin proxy
function proxy() {
    export https_proxy=http://127.0.0.1:7890
    export http_proxy=http://127.0.0.1:7890
    export all_proxy=socks5://127.0.0.1:7890
}

function direct() {
    unset https_proxy;
    unset http_proxy;
    unset all_proxy;
}
# End proxy
