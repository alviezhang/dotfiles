#!/bin/zsh

# 代理配置
proxy() {
  export PROXYHOST=${PROXYHOST:-10.0.10.20}
  export http_proxy=http://$PROXYHOST:${PROXYHTTPPORT:-7890}
  export https_proxy=http://$PROXYHOST:${PROXYHTTPPORT:-7890}
  export all_proxy=socks5://$PROXYHOST:${PROXYSOCKSPORT:-7891}
  echo "Proxy ON"
}

direct() {
  unset http_proxy https_proxy all_proxy
  echo "Proxy OFF"
}

if [[ -f "$HOME/.config/proxy.sh" ]]; then
  . "$HOME/.config/proxy.sh"
  proxy
fi
