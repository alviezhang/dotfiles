ZSH_THEME="bira"

# export VIRTUAL_ENV_DISABLE_PROMPT=True
# source ~/.virtualenv/python2/bin/activate

UNAME=`uname`

if [ "$UNAME" = "Linux" ]; then
    plugins=(git autojump golang httpie)
elif [ "$UNAME" = "Darwin" ]; then
    plugins=(git osx autojump brew brew-cask golang httpie)
    export LANG=en_US.UTF-8
fi

export GOPATH=~/code/go
mkdir -p $GOPATH

export PATH=$PATH:$GOPATH/bin

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

function proxy() {
    export http_proxy=http://localhost:8118;export https_proxy=http://localhost:8118
}

function direct() {
    unset http_proxy;
    unset https_proxy;
}

