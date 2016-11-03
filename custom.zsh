ZSH_THEME="bira"

UNAME=`uname`

if [ "$UNAME" = "Linux" ]; then
    plugins=(git autojump golang httpie)
elif [ "$UNAME" = "Darwin" ]; then
    plugins=(git osx autojump brew brew-cask golang httpie)
    export LANG=en_US.UTF-8
fi

# Go Settings
export GOPATH=~/code/go
mkdir -p $GOPATH

# End

export PATH=$PATH:$GOPATH/bin

# Proxy Settings

function proxy() {
    export http_proxy=http://localhost:8118;export https_proxy=http://localhost:8118
}

function direct() {
    unset http_proxy;
    unset https_proxy;
}

# End

# Python Settings

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# virtualenv wrapper

VIRTUALENVWRAPPER_BIN=virtualenvwrapper.sh
export WORKON_HOME=$HOME/.virtualenvs
mkdir -p $WORKON_HOME

if which $VIRTUALENVWRAPPER_BIN; then
    source $VIRTUALENVWRAPPER_BIN
fi

# End
