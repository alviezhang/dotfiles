#!/bin/bash
# 在隔离的 HOME 里端到端跑 chezmoi init --apply：
# 用一次性测试密钥替换仓库里的三个密文，安装脚本换成只记录名字的替身，
# 验证首次落地、二次 apply 无需口令且无差异、密钥损坏后自愈。
# 不读取真实 key.txt、Keychain 或口令文件。用法：tests/apply-e2e.sh [REPO]
set -u
REPO="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
CHEZMOI="${CHEZMOI:-$(command -v chezmoi)}"
T=$(mktemp -d "${TMPDIR:-/tmp}/apply-e2e.XXXXXX")
trap 'rm -rf "$T"' EXIT
# 隔离：chezmoi 优先读 XDG_CONFIG_HOME，残留的真实路径会让测试写到用户自己的配置
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME CHEZMOI_AGE_PASSWORD CARGO_HOME RUSTUP_HOME
export HOME="$T/home"; mkdir -p "$HOME"

SRC="$T/src"
rsync -a --exclude .git --exclude tmux --exclude .tmux --exclude .DS_Store --exclude tests "$REPO/" "$SRC/"
"$CHEZMOI" age-keygen --output "$T/id.txt" >/dev/null 2>&1
REC=$("$CHEZMOI" age-keygen -y "$T/id.txt")
echo "$REC" > "$SRC/age-recipient.txt"
PW="e2e-test-passphrase"
printf '%s\n%s\n' "$PW" "$PW" | "$CHEZMOI" --no-tty age encrypt --passphrase --output "$SRC/key.txt.age" "$T/id.txt" >/dev/null 2>&1
printf 'name = "E2E Tester"\nemail = "e2e@example.invalid"\n' > "$T/ident.toml"
printf 'encryption = "age"\n[age]\n  recipient = "%s"\n' "$REC" > "$T/enc.toml"
"$CHEZMOI" --config "$T/enc.toml" encrypt --output "$SRC/git-identity.toml.age" "$T/ident.toml"
# Keychain helper 替身：永远“未找到”，避免触碰真实钥匙串
printf '#!/bin/bash\nexit 44\n' > "$SRC/scripts/dotfiles-keychain"
for f in "$SRC"/.chezmoiscripts/*after*.tmpl; do
  printf '#!/bin/bash\necho "%s" >> "%s/ran.log"\n' "$(basename "$f")" "$T" > "$f"
done

KEY="$HOME/.config/chezmoi/key.txt"
CZ() { "$CHEZMOI" --no-tty "$@"; }
mode_of() { if [ "$(uname -s)" = Darwin ]; then stat -f %Lp "$1"; else stat -c %a "$1"; fi; }
fail=0
check() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; [ -f "$T/out" ] && sed 's/^/       | /' "$T/out"; fail=1; fi
}

CHEZMOI_AGE_PASSWORD="$PW" "$CHEZMOI" --no-tty \
  init --source "$SRC" --apply --promptString machineType=remote > "$T/out" 2>&1
check "fresh HOME: init --apply succeeds" "$?" "0"
check "  key decrypted and matches" "$(cmp -s "$KEY" "$T/id.txt" && echo yes)" "yes"
check "  key mode 600" "$(mode_of "$KEY")" "600"
check "  .gitconfig rendered from encrypted identity" "$(grep -c 'E2E Tester' "$HOME/.gitconfig")" "1"
check "  generated config uses builtin age" "$(grep -c '^useBuiltinAge = true' "$HOME/.config/chezmoi/chezmoi.toml")" "1"
check "  installers ran in order" "$(tr '\n' ' ' < "$T/ran.log")" \
  "run_once_after_00-homebrew.sh.tmpl run_onchange_after_00-linux-packages.sh.tmpl run_after_10-ohmyzsh.sh.tmpl run_onchange_after_20-tmux.sh.tmpl run_once_after_30-go.sh.tmpl run_once_after_31-rust.sh.tmpl run_once_after_32-node.sh.tmpl run_onchange_after_40-pipx.sh.tmpl run_onchange_after_41-cargo-packages.sh.tmpl run_onchange_after_42-npm-packages.sh.tmpl run_after_50-vim-plugins.sh.tmpl run_onchange_after_90-brew-bundle.sh.tmpl "

: > "$T/ran.log"
CZ --source "$SRC" apply > "$T/out" 2>&1
check "second apply with no passphrase source succeeds" "$?" "0"
check "  only every-run checks re-ran" "$(tr '\n' ' ' < "$T/ran.log")" "run_after_10-ohmyzsh.sh.tmpl run_after_50-vim-plugins.sh.tmpl "
check "  no pending diff" "$(CZ --source "$SRC" diff --exclude scripts 2>&1)" ""

echo garbage > "$KEY"
mkdir -p "$HOME/.config/dotfiles"
printf '%s' "$PW" > "$HOME/.config/dotfiles/passphrase"; chmod 600 "$HOME/.config/dotfiles/passphrase"
CZ --source "$SRC" apply > "$T/out" 2>&1
check "corrupt key + passphrase file: apply succeeds" "$?" "0"
check "  key self-healed" "$(cmp -s "$KEY" "$T/id.txt" && echo yes)" "yes"

[ "$fail" -eq 0 ] && echo "ALL OK" || { echo "FAILURES"; exit 1; }
