#!/bin/zsh

# NVM
[[ -s "/opt/local/share/nvm/init-nvm.sh" ]] && source /opt/local/share/nvm/init-nvm.sh


# Go
export GOPATH="$HOME/.go"
mkdir -p "$GOPATH"
path_prepend "$GOPATH/bin"


# pyenv
if [ -s "$HOME/.pyenv/bin/pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  path_prepend "$PYENV_ROOT/bin"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi


# Rust
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"


# 代理配置函数
# 检查是否存在 ~/.env 文件，如果存在则读取其中的环境变量
if [[ -f "$HOME/.config/proxy.sh" ]]; then
  . "$HOME/.config/proxy.sh"
fi


proxy() {
  export PROXYHOST=${PROXYHOST:-10.0.10.20}
  export http_proxy=http://$PROXYHOST:${PROXYHTTPPORT:-7890}
  export https_proxy=http://$PROXYHOST:${PROXYHTTPPORT:-7890}
  export all_proxy=socks5://$PROXYHOST:${PROXYSOCKSPORT:-7891}
  echo "✅ Proxy ON"
}

direct() {
  unset http_proxy https_proxy all_proxy
  echo "🚫 Proxy OFF"
}
