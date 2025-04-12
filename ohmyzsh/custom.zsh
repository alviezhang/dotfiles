#!/bin/zsh

ZSH_THEME="bira"

# Language
export LANG=en_US.UTF-8
export LANGUAGE=en_US

# macOS
function macOS() {
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # export PATH="$HOME/Library/Python/3.11/bin:$PATH"
    export PATH=/opt/google-cloud-sdk/bin:$PATH

    # Macports extra flags
    export LDFLAGS=-L/opt/local/lib/
    export CPPFLAGS=-I/opt/local/include/
}

# Linux
function linux() {
    alias open=xdg-open
}

if [ "$OS" = "linux" ]; then
    linux
elif [ "$OS" = "macOS" ]; then
    macOS
fi

export PATH="$HOME/.local/bin:/usr/local/sbin:$PATH"

# export LEDGER_FILE=$HOME/onedrive/Docs/hledger/main.journal

# NVM
[[ -s "/opt/local/share/nvm/init-nvm.sh" ]] && source /opt/local/share/nvm/init-nvm.sh

# Begin go
export GOPATH=$HOME/.go
mkdir -p $GOPATH
export PATH=$GOPATH/bin:$PATH
# [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
# End go

# Begin pyenv
export PYENV_ROOT="$HOME/.pyenv"
if [ -s "$PYENV_ROOT/bin/pyenv" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi
# End pyenv

# Rustup
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
# End rustup

# Begin proxy
function proxy() {
    export PROXYHOST=10.0.10.20
    export http_proxy=http://$PROXYHOST:7890
    export https_proxy=http://$PROXYHOST:7890
    export all_proxy=socks5://$PROXYHOST:7891
}

function direct() {
    unset https_proxy;
    unset http_proxy;
    unset all_proxy;
}
# End proxy
