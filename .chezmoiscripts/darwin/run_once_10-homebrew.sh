#!/bin/bash

# Check common Homebrew locations before attempting install
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$b" ] && exit 0
done
command -v brew &>/dev/null && exit 0

set -e
/bin/bash -c "$(curl -fsSL \
  https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
