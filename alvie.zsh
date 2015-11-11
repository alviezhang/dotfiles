ZSH_THEME="bira"

# export VIRTUAL_ENV_DISABLE_PROMPT=True
# source ~/.virtualenv/python2/bin/activate
export PATH=~/bin:$PATH:/usr/local/opt/go/libexec/bin

plugins=(git osx autojump brew brew-cask golang)

export GOPATH=~/.go

function proxy() {
    export http_proxy=http://localhost:8118;export https_proxy=http://localhost:8118
}

function direct() {
    unset http_proxy;
    unset https_proxy;
}

if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
