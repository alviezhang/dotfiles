#!/bin/bash
command -v brew &>/dev/null && exit 0
set -e
/bin/bash -c "$(curl -fsSL \
  https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
