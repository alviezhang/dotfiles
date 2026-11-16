#!/bin/bash
# 在隔离的 HOME 里测试 run_before_00-decrypt-private-key：
# 生成一次性测试密钥和口令，不读取真实 key.txt、Keychain 或口令文件。
# 用法：tests/decrypt-key.sh [REPO]
set -u
REPO="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
CHEZMOI="${CHEZMOI:-$(command -v chezmoi)}"
T=$(mktemp -d "${TMPDIR:-/tmp}/decrypt-test.XXXXXX")
trap 'rm -rf "$T"' EXIT
# 隔离：chezmoi 优先读 XDG_CONFIG_HOME，残留的真实路径会让测试写到用户自己的配置
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME CHEZMOI_AGE_PASSWORD CARGO_HOME RUSTUP_HOME
export HOME="$T/home"; mkdir -p "$HOME"

# 测试用源目录：只替换密钥相关的三个文件
SRC="$T/src"; mkdir -p "$SRC/scripts"
cp "$REPO/.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl" "$T/decrypt.tmpl"
"$CHEZMOI" age-keygen --output "$T/id.txt" >/dev/null 2>&1
"$CHEZMOI" age-keygen -y "$T/id.txt" > "$SRC/age-recipient.txt"
"$CHEZMOI" age-keygen --output "$T/other.txt" >/dev/null 2>&1
PW="correct horse battery staple"
printf '%s\n%s\n' "$PW" "$PW" | "$CHEZMOI" --no-tty age encrypt --passphrase --output "$SRC/key.txt.age" "$T/id.txt" >/dev/null 2>&1
# Keychain helper 替身：返回固定退出码，避免触碰真实钥匙串
printf '#!/bin/bash\nexit 44\n' > "$SRC/scripts/dotfiles-keychain"; chmod +x "$SRC/scripts/dotfiles-keychain"

printf '[data]\n' > "$T/cfg.toml"
"$CHEZMOI" --config "$T/cfg.toml" --source "$SRC" execute-template < "$T/decrypt.tmpl" > "$T/decrypt.sh" || { echo "render failed"; exit 1; }

KEY="$HOME/.config/chezmoi/key.txt"; PWF="$HOME/.config/dotfiles/passphrase"
fail=0
run() { env CHEZMOI_EXECUTABLE="$CHEZMOI" "$@" bash "$T/decrypt.sh" </dev/null >"$T/out" 2>&1; }
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; sed 's/^/       | /' "$T/out"; fail=1; fi; }
key_ok() { cmp -s "$KEY" "$T/id.txt" && echo yes || echo no; }
leftovers() { find "$HOME/.config/chezmoi" -name 'key.txt.*' | wc -l | tr -d ' '; }
mode() { if [ "$(uname -s)" = Darwin ]; then stat -f '%Lp' "$1"; else stat -c '%a' "$1"; fi; }
reset() { rm -rf "$HOME"; mkdir -p "$HOME"; }

reset; run CHEZMOI_AGE_PASSWORD="$PW"
check "fresh HOME + env passphrase: exit 0" "$?" "0"; check "  key decrypted and matches" "$(key_ok)" "yes"; check "  key mode 600" "$(mode "$KEY")" "600"

run CHEZMOI_AGE_PASSWORD="wrong"
check "valid key: no passphrase needed even if source is wrong" "$?" "0"
grep -q 'decrypt:' "$T/out"; check "  valid key: silent, passphrase not used" "$?" "1"

reset; mkdir -p "$(dirname "$PWF")"; printf '%s\n' "$PW" > "$PWF"; chmod 600 "$PWF"; run
check "passphrase file 0600 (trailing newline): exit 0" "$?" "0"; check "  key matches" "$(key_ok)" "yes"
grep -q "from file" "$T/out"; check "  reports file as source" "$?" "0"

reset; mkdir -p "$(dirname "$PWF")"; printf '%s' "$PW" > "$PWF"; chmod 644 "$PWF"; run
check "passphrase file 0644: refused, falls to prompt and fails without tty" "$?" "1"
grep -q 'expected 600' "$T/out"; check "  warns about mode" "$?" "0"; check "  no key written" "$([ -e "$KEY" ] && echo yes || echo no)" "no"

reset; mkdir -p "$(dirname "$KEY")"; echo "garbage" > "$KEY"; run CHEZMOI_AGE_PASSWORD="wrong"
check "corrupt key + wrong passphrase: exit 1" "$?" "1"; check "  existing key file untouched" "$(cat "$KEY")" "garbage"
check "  no temp files left" "$(leftovers)" "0"; grep -q 'failed to decrypt' "$T/out"; check "  clear error" "$?" "0"
grep -q "$PW" "$T/out"; check "  correct passphrase never printed" "$?" "1"
grep -q "wrong" "$T/out"; check "  supplied passphrase never printed" "$?" "1"

reset; mkdir -p "$(dirname "$KEY")"; cp "$T/other.txt" "$KEY"; run CHEZMOI_AGE_PASSWORD="$PW"
check "key for a different recipient: replaced" "$?" "0"; check "  key now matches" "$(key_ok)" "yes"; check "  no temp files left" "$(leftovers)" "0"

reset; run CHEZMOI_AGE_PASSWORD=""
check "empty env var: warns, falls through, fails without tty" "$?" "1"; grep -q 'set but empty' "$T/out"; check "  warns" "$?" "0"

# key.txt.age 解出来的不是 age-recipient.txt 对应的私钥
cp "$SRC/key.txt.age" "$T/key.txt.age.good"
printf '%s\n%s\n' "$PW" "$PW" | "$CHEZMOI" --no-tty age encrypt --passphrase --output "$SRC/key.txt.age" "$T/other.txt" >/dev/null 2>&1
"$CHEZMOI" --config "$T/cfg.toml" --source "$SRC" execute-template < "$T/decrypt.tmpl" > "$T/decrypt.sh"
reset; mkdir -p "$(dirname "$KEY")"; echo "garbage" > "$KEY"; run CHEZMOI_AGE_PASSWORD="$PW"
check "key.txt.age/recipient mismatch: exit 1" "$?" "1"; check "  existing key file untouched" "$(cat "$KEY")" "garbage"
check "  no temp files left" "$(leftovers)" "0"; grep -q 'does not match age-recipient' "$T/out"; check "  clear error" "$?" "0"

[ "$fail" -eq 0 ] && echo "ALL OK" || { echo "FAILURES"; exit 1; }
