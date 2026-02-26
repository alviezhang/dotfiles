#!/bin/zsh

# 只在 open 未定义时创建 alias
if ! type open &>/dev/null; then
  alias open='xdg-open'
fi
