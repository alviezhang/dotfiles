#!/bin/bash
[ -d "$HOME/.oh-my-zsh" ] && exit 0
set -e
curl -Lo /tmp/install.sh \
  https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
RUNZSH=no sh /tmp/install.sh
