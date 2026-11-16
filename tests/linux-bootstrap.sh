#!/bin/bash
# 在干净的 Linux 容器里从零 bootstrap，走真实安装器（apt/pacman、oh-my-zsh、tmux 主题）。
# 用一次性测试密钥替换仓库里的三个密文，真实口令不进容器。
# 需要 docker 和网络；不在 `make test` 里，单独运行：
#   tests/linux-bootstrap.sh                      # 全部组合
#   tests/linux-bootstrap.sh debian:stable remote # 单个组合
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
command -v docker >/dev/null 2>&1 || { echo "docker not found" >&2; exit 2; }

IMAGES=(debian:stable ubuntu:latest archlinux:latest)
TYPES=(remote personal)
if [ $# -ge 1 ]; then IMAGES=("$1"); fi
if [ $# -ge 2 ]; then TYPES=("$2"); fi

# 容器内执行：准备非 root 用户和测试夹具，然后按 README 的方式 bootstrap
read -r -d '' INNER <<'INNER_EOF' || true
set -euo pipefail
MT="$1"
if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -q >/dev/null && apt-get install -y -q curl sudo ca-certificates rsync >/dev/null
else
  pacman -Sy --noconfirm --needed curl sudo rsync >/dev/null
fi
useradd -m -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester

su - tester -c "bash -s '$MT'" <<'USER_EOF'
set -euo pipefail
MT="$1"
sh -c "$(curl --proto '=https' --tlsv1.2 -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null
CZ="$HOME/.local/bin/chezmoi"

SRC="$HOME/src"; mkdir -p "$SRC"
rsync -a --exclude .git --exclude tmux --exclude .tmux --exclude .DS_Store /repo/ "$SRC/"
FIX="$(mktemp -d)"
"$CZ" age-keygen --output "$FIX/id.txt" >/dev/null 2>&1
REC=$("$CZ" age-keygen -y "$FIX/id.txt"); echo "$REC" > "$SRC/age-recipient.txt"
PW="linux-bootstrap-test"
printf '%s\n%s\n' "$PW" "$PW" | "$CZ" --no-tty age encrypt --passphrase --output "$SRC/key.txt.age" "$FIX/id.txt" >/dev/null 2>&1
printf 'name = "Linux Tester"\nemail = "t@example.invalid"\n' > "$FIX/ident.toml"
printf 'encryption = "age"\n[age]\n  recipient = "%s"\n' "$REC" > "$FIX/enc.toml"
"$CZ" --config "$FIX/enc.toml" encrypt --output "$SRC/git-identity.toml.age" "$FIX/ident.toml"

fail=0
check() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2] want [$3]"; fail=1; fi; }

CHEZMOI_AGE_PASSWORD="$PW" "$CZ" --no-tty init --source "$SRC" --apply --promptString machineType="$MT" > "$FIX/apply1.log" 2>&1 \
  && rc=0 || rc=$?
check "init --apply exit status" "$rc" "0"
[ "$rc" -eq 0 ] || tail -40 "$FIX/apply1.log"
check "key.txt matches recipient" "$("$CZ" age-keygen -y "$HOME/.config/chezmoi/key.txt" 2>/dev/null)" "$REC"
check ".gitconfig has decrypted identity" "$(grep -c 'Linux Tester' "$HOME/.gitconfig" 2>/dev/null)" "1"
for bin in zsh git tmux vim rg jq unzip; do
  check "package installed: $bin" "$(command -v "$bin" >/dev/null && echo yes || echo no)" "yes"
done
check "oh-my-zsh installed" "$([ -s "$HOME/.oh-my-zsh/oh-my-zsh.sh" ] && echo yes || echo no)" "yes"
if [ "$MT" = remote ]; then
  check "remote: plain ~/.tmux.conf" "$([ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ] && echo yes || echo no)" "yes"
  check "remote: no tmux.conf.local" "$([ -e "$HOME/.config/tmux/tmux.conf.local" ] && echo present || echo absent)" "absent"
else
  check "personal: ~/.tmux.conf -> theme" "$(readlink "$HOME/.tmux.conf" 2>/dev/null | grep -c gpakosz-tmux)" "1"
  check "personal: ~/.tmux.conf.local link" "$([ -L "$HOME/.tmux.conf.local" ] && echo yes || echo no)" "yes"
fi
check "fontconfig deployed on Linux" "$([ -d "$HOME/.config/fontconfig" ] && echo yes || echo no)" "yes"
check "zsh loads .zshrc cleanly" "$(zsh -i -c 'exit 0' >/dev/null 2>&1 && echo yes || echo no)" "yes"

# 二次 apply：不给任何口令源，不应提示、不应出错、不应有差异
"$CZ" --no-tty --source "$SRC" apply > "$FIX/apply2.log" 2>&1 && rc=0 || rc=$?
check "second apply without passphrase" "$rc" "0"
[ "$rc" -eq 0 ] || tail -20 "$FIX/apply2.log"
check "no pending diff" "$("$CZ" --no-tty --source "$SRC" diff --exclude scripts 2>&1)" ""

[ "$fail" -eq 0 ] && echo "ALL OK" || { echo "FAILURES"; exit 1; }
USER_EOF
INNER_EOF

overall=0
for image in "${IMAGES[@]}"; do
  for mt in "${TYPES[@]}"; do
    echo "=== $image / $mt"
    if docker run --rm -v "$REPO:/repo:ro" "$image" bash -c "$INNER" _ "$mt"; then
      echo "=== PASS $image / $mt"
    else
      echo "=== FAIL $image / $mt"; overall=1
    fi
  done
done
exit "$overall"
