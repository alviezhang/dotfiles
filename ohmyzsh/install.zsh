#!/bin/zsh

PATCH_MARK="# >>> custom preload <<<"
PATCH_LINE=". \"$PWD/preload.zsh\""
ZSHRC="$HOME/.zshrc"

# 检查是否已插入过
if grep -q "$PATCH_MARK" "$ZSHRC"; then
  echo "[!] Already patched. Skipping."
  exit 0
fi

# 插入到 plugins=(...) 这一行后面
TMP_FILE=$(mktemp)

awk -v preload_mark="$PATCH_MARK" -v preload_line="$PATCH_LINE" '
  {
    print $0
    if ($0 ~ /^plugins=\(.*\)/) {
      print ""
      print preload_mark
      print preload_line
      print "# <<< custom preload >>>"
    }
  }
' "$ZSHRC" > "$TMP_FILE"

mv "$TMP_FILE" "$ZSHRC"

echo "[✓] preload.zsh has been patched after plugins=()"
