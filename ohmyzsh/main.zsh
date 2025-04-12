#!/bin/zsh

# 获取当前脚本所在目录
ZSH_CONFIG_DIR="${0:A:h}"

# ZSH Theme
ZSH_THEME="bira"

# Locale 设置
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 根据操作系统加载不同的配置
case "$(uname)" in
  Darwin)
    [[ -f "$ZSH_CONFIG_DIR/macos.zsh" ]] && source "$ZSH_CONFIG_DIR/macos.zsh"
    ;;
  Linux)
    [[ -f "$ZSH_CONFIG_DIR/linux.zsh" ]] && source "$ZSH_CONFIG_DIR/linux.zsh"
    ;;
esac

path_prepend() {
  [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}

# 加载开发环境相关配置
[[ -f "$ZSH_CONFIG_DIR/dev.zsh" ]] && source "$ZSH_CONFIG_DIR/dev.zsh"

# （可选）加载代理配置
[[ -f "$ZSH_CONFIG_DIR/proxy.zsh" ]] && source "$ZSH_CONFIG_DIR/proxy.zsh"

# 通用 PATH 配置（放在最后以确保优先级）
path_prepend "$HOME/.local/bin"
path_prepend "/usr/local/sbin"