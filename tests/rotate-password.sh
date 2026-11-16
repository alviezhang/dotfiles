#!/bin/bash
# 在仓库副本和隔离 HOME 里测试 scripts/rotate-password 与 scripts/edit-secret。
# Keychain helper 换成把条目存进临时文件的替身，不触碰真实钥匙串。
# 用法：tests/rotate-password.sh [REPO]
set -u
REPO="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
CHEZMOI="${CHEZMOI:-$(command -v chezmoi)}"
T=$(mktemp -d "${TMPDIR:-/tmp}/rotate-test.XXXXXX")
trap 'rm -rf "$T"' EXIT
# 隔离：chezmoi 优先读 XDG_CONFIG_HOME，残留的真实路径会让测试写到用户自己的配置
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME CHEZMOI_AGE_PASSWORD CARGO_HOME RUSTUP_HOME
export HOME="$T/home"; mkdir -p "$HOME/.config/chezmoi"
export PATH="$(dirname "$CHEZMOI"):$PATH"

SRC="$T/src"; mkdir -p "$SRC/scripts"
cp "$REPO/scripts/rotate-password" "$REPO/scripts/edit-secret" "$SRC/scripts/"
KEY="$HOME/.config/chezmoi/key.txt"
"$CHEZMOI" age-keygen --output "$KEY" >/dev/null 2>&1; chmod 600 "$KEY"
REC=$("$CHEZMOI" age-keygen -y "$KEY"); echo "$REC" > "$SRC/age-recipient.txt"
OLD_PW="old-passphrase"
printf '%s\n%s\n' "$OLD_PW" "$OLD_PW" | "$CHEZMOI" --no-tty age encrypt --passphrase --output "$SRC/key.txt.age" "$KEY" >/dev/null 2>&1
printf 'encryption = "age"\nuseBuiltinAge = true\n[age]\n  identity = "%s"\n  recipient = "%s"\n' "$KEY" "$REC" > "$HOME/.config/chezmoi/chezmoi.toml"

KC_STORE="$T/keychain"; KC_LOG="$T/keychain.log"
cat > "$SRC/scripts/dotfiles-keychain" <<EOF
#!/bin/bash
echo "\$1 \$2 \$3" >> "$KC_LOG"
case "\$1" in
  get)    [ -f "$KC_STORE" ] || exit 44; cat "$KC_STORE" ;;
  set)    [ -f "$T/keychain.fail" ] && exit 1; IFS= read -r pw; printf '%s' "\$pw" > "$KC_STORE" ;;
  delete) rm -f "$KC_STORE" ;;
esac
EOF
chmod +x "$SRC/scripts/dotfiles-keychain"

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; sed 's/^/       | /' "$T/out"; fail=1; fi; }
decrypts_with() {
  printf '%s\n' "$1" | "$CHEZMOI" --no-tty age decrypt --passphrase --output "$T/dec" "$SRC/key.txt.age" >/dev/null 2>&1 \
    && cmp -s "$T/dec" "$KEY" && echo yes || echo no
}
leftovers() { find "$SRC" -maxdepth 1 -name '.rotate.*' | wc -l | tr -d ' '; }
rotate() { "$SRC/scripts/rotate-password" "$@" </dev/null >"$T/out" 2>&1; }
IS_MAC=$([ "$(uname -s)" = Darwin ] && echo yes || echo no)

rotate --auto --length 24
check "--auto rotation succeeds" "$?" "0"
if [ "$IS_MAC" = yes ]; then
  NEW_PW=$(cat "$KC_STORE")
  check "  passphrase stored in Keychain, length 24" "${#NEW_PW}" "24"
else
  NEW_PW=$(cat "$HOME/.config/dotfiles/passphrase")
  check "  passphrase stored in file, length 24" "${#NEW_PW}" "24"
fi
check "  key.txt.age decrypts with new passphrase" "$(decrypts_with "$NEW_PW")" "yes"
check "  key.txt.age no longer decrypts with old" "$(decrypts_with "$OLD_PW")" "no"
check "  key.txt.age mode 644" "$( [ "$IS_MAC" = yes ] && stat -f %Lp "$SRC/key.txt.age" || stat -c %a "$SRC/key.txt.age")" "644"
grep -q "$NEW_PW" "$T/out"; check "  new passphrase never printed" "$?" "1"
grep -q 'commit and push key.txt.age' "$T/out"; check "  reminds to commit and push" "$?" "0"
check "  no temp dirs left" "$(leftovers)" "0"

cp "$SRC/key.txt.age" "$T/before.age"
rotate --auto --file "$T/pw-file"
check "--file rotation succeeds" "$?" "0"
FILE_PW=$(cat "$T/pw-file")
check "  file mode 600" "$( [ "$IS_MAC" = yes ] && stat -f %Lp "$T/pw-file" || stat -c %a "$T/pw-file")" "600"
check "  key.txt.age decrypts with file passphrase" "$(decrypts_with "$FILE_PW")" "yes"
if [ "$IS_MAC" = yes ]; then
  check "  stale Keychain entry removed" "$([ -f "$KC_STORE" ] && echo present || echo gone)" "gone"
fi

if [ "$IS_MAC" = yes ]; then
  echo "seed" > "$KC_STORE"; touch "$T/keychain.fail"; cp "$SRC/key.txt.age" "$T/before.age"
  rotate --auto
  check "Keychain write failure: exits non-zero" "$?" "1"
  check "  key.txt.age unchanged" "$(cmp -s "$SRC/key.txt.age" "$T/before.age" && echo same)" "same"
  check "  no temp dirs left" "$(leftovers)" "0"
  rm -f "$T/keychain.fail"
fi

cp "$SRC/key.txt.age" "$T/before.age"; cp "$KEY" "$T/key.bak"
"$CHEZMOI" age-keygen --output "$T/other.txt" >/dev/null 2>&1; cp "$T/other.txt" "$KEY"
rotate --auto
check "key.txt not matching recipient: refuses" "$?" "1"
check "  key.txt.age unchanged" "$(cmp -s "$SRC/key.txt.age" "$T/before.age" && echo same)" "same"
grep -q 'does not match age-recipient' "$T/out"; check "  clear error" "$?" "0"
cp "$T/key.bak" "$KEY"

rotate --length abc
check "--length validation" "$?" "1"

printf 'name = "Before"\n' > "$T/ident.toml"
"$CHEZMOI" encrypt --output "$SRC/git-identity.toml.age" "$T/ident.toml"
printf '#!/bin/bash\nsed -i.bak "s/Before/After/" "$1"\n' > "$T/editor"; chmod +x "$T/editor"
EDITOR="$T/editor" "$SRC/scripts/edit-secret" git-identity.toml.age >"$T/out" 2>&1
check "edit-secret with a change: succeeds" "$?" "0"
check "  re-encrypted content updated" "$("$CHEZMOI" decrypt "$SRC/git-identity.toml.age")" 'name = "After"'
cp "$SRC/git-identity.toml.age" "$T/ident.before"
EDITOR=true "$SRC/scripts/edit-secret" git-identity.toml.age >"$T/out" 2>&1
check "edit-secret without a change: succeeds" "$?" "0"
check "  file untouched" "$(cmp -s "$SRC/git-identity.toml.age" "$T/ident.before" && echo same)" "same"
grep -q 'No changes' "$T/out"; check "  reports no changes" "$?" "0"

[ "$fail" -eq 0 ] && echo "ALL OK" || { echo "FAILURES"; exit 1; }
