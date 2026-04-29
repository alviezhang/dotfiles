# Password Handling Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the chezmoi age-key password lookup chain with `env → macOS Keychain → ~/.config/dotfiles/passphrase → interactive`, with explicit fall-through rules for empty / error / decrypt-failure cases. Migrate `scripts/rotate-password` to write the new locations and update docs.

**Architecture:** Two shell-script changes — `.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl` (read path) and `scripts/rotate-password` (write path) — plus README + DESIGN.md doc updates. macOS uses `security` CLI for Keychain. Linux uses XDG-style file at `~/.config/dotfiles/passphrase` (mode `0600`). Fall-through rules are explicit: source-not-found stays silent, source-found-but-empty / source-access-fails warns and falls through, decrypt-fail propagates as an error (does not silently fall back to interactive).

**Tech stack:** bash, age, expect, chezmoi templates, `security` (macOS Keychain CLI).

**Spec:** `docs/superpowers/specs/2026-04-29-password-handling-design.md`

---

## File structure

| File | Responsibility | This plan |
|---|---|---|
| `.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl` | Resolve passphrase from any source; decrypt `key.txt.age` → `~/.config/chezmoi/key.txt` | Rewrite (Task 1) |
| `scripts/rotate-password` | Set / rotate passphrase; re-encrypt `key.txt.age`; store passphrase in Keychain or file | Rewrite (Task 2) |
| `README.md` | User-facing docs (Secrets section) | Replace section (Task 3) |
| `DESIGN.md` | Internal design (Secret 管理 section) | Replace section (Task 4) |
| `.gitignore`, `.chezmoiignore.tmpl` | Defensive ignores | No change — keep `.password` ignore as defensive |

---

## Task 1: Rewrite `run_before_00` lookup chain

**Files:**
- Modify: `.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl`

- [ ] **Step 1: Read current file**

```bash
cat .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl
```

Confirm the lookup chain is `env → ~/.config/chezmoi/password → $SOURCE_DIR/.password → interactive`.

- [ ] **Step 2: Replace file with the new content**

Overwrite `.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl` with **exactly**:

```bash
#!/bin/bash
# key.txt.age hash: {{ include "key.txt.age" | sha256sum }}
# Re-decrypt on every apply/update so accidental local key edits are self-healed.
set -euo pipefail

KEY_FILE="${HOME}/.config/chezmoi/key.txt"
SOURCE_DIR="{{ .chezmoi.sourceDir }}"
PW_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/passphrase"

mkdir -p "${HOME}/.config/chezmoi"

# 密码来源（按优先级）：
#   1. CHEZMOI_AGE_PASSWORD env var (CI / ephemeral；same-user 进程可见，不作稳态)
#   2. macOS Keychain (service=dotfiles-passphrase, account=$USER)
#   3. ~/.config/dotfiles/passphrase (mode 0600)
#   4. 交互式输入（chezmoi age decrypt 自身 prompt）
#
# Fall-through 规则：
#   - 源未找到：安静下一层
#   - 源找到但为空：warning + 下一层
#   - 源访问失败（keychain 锁/拒、文件 perm 错）：warning + 下一层
#   - 拿到密码但 age 解密失败：不 fallthrough，set -e 直接报错退出

PASSWORD=""

# 1. Env var
if [ -n "${CHEZMOI_AGE_PASSWORD-}" ]; then
    PASSWORD="$CHEZMOI_AGE_PASSWORD"
fi

# 2. macOS Keychain
if [ -z "$PASSWORD" ] && [ "$(uname -s)" = "Darwin" ] && command -v security &>/dev/null; then
    KC_RC=0
    KC_PW=$(security find-generic-password -s dotfiles-passphrase -a "$USER" -w 2>/dev/null) || KC_RC=$?
    if [ "$KC_RC" -eq 0 ] && [ -n "$KC_PW" ]; then
        PASSWORD="$KC_PW"
    elif [ "$KC_RC" -eq 0 ] && [ -z "$KC_PW" ]; then
        echo "warning: Keychain entry 'dotfiles-passphrase' is empty; falling through" >&2
    elif [ "$KC_RC" -ne 44 ]; then
        # rc=44 = item not found (silent); other rc = real failure (locked / access denied / etc.)
        echo "warning: 'security find-generic-password' exited with $KC_RC; falling through" >&2
    fi
fi

# 3. File fallback (~/.config/dotfiles/passphrase, must be 0600)
if [ -z "$PASSWORD" ] && [ -f "$PW_FILE" ]; then
    perms=$(stat -f "%A" "$PW_FILE" 2>/dev/null || stat -c "%a" "$PW_FILE" 2>/dev/null || echo "?")
    if [ "$perms" = "600" ]; then
        FILE_PW=$(sed 's/[[:space:]]*$//' "$PW_FILE")
        if [ -n "$FILE_PW" ]; then
            PASSWORD="$FILE_PW"
        else
            echo "warning: ${PW_FILE} is empty; falling through" >&2
        fi
    else
        echo "warning: ${PW_FILE} has perms ${perms}, expected 600; refusing to read" >&2
    fi
fi

# 4. Decrypt
if [ -n "$PASSWORD" ] && command -v expect &>/dev/null; then
    # 非交互：通过 env var 把密码喂给 age（避免命令行参数泄漏）
    AGE_PW="$PASSWORD" AGE_KEY="$KEY_FILE" AGE_SRC="$SOURCE_DIR/key.txt.age" \
    expect -c '
        log_user 0
        spawn age -d -o $env(AGE_KEY) $env(AGE_SRC)
        expect "Enter passphrase:"
        send "$env(AGE_PW)\r"
        expect eof
        catch wait result
        exit [lindex $result 3]
    '
else
    # 交互式
    chezmoi age decrypt --output "$KEY_FILE" --passphrase "$SOURCE_DIR/key.txt.age"
fi

chmod 600 "$KEY_FILE"
```

- [ ] **Step 3: Verify the template still renders**

```bash
chezmoi execute-template < .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl | head -10
```

Expected: lines 1–9 should contain literal text (no `{{ }}` markers). The hash on line 2 and the `SOURCE_DIR=` on line 7 should be substituted.

- [ ] **Step 4: Verify the rendered shell parses**

```bash
chezmoi execute-template < .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl > /tmp/rb00.sh
bash -n /tmp/rb00.sh && echo "OK"
rm /tmp/rb00.sh
```

Expected: `OK`. Anything else = syntax error, fix before continuing.

- [ ] **Step 5: Verify old paths are gone**

```bash
grep -E '\.config/chezmoi/password|SOURCE_DIR/\.password' .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl
```

Expected: empty (no matches).

- [ ] **Step 6: Commit**

```bash
git add .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl
git commit -m "$(cat <<'EOF'
feat: rewrite age password lookup chain with Keychain backend

New chain: env -> macOS Keychain -> ~/.config/dotfiles/passphrase
-> interactive. Drops legacy ~/.config/chezmoi/password and source
dir .password paths. Fall-through rules distinguish source-not-found
(silent), empty-or-error (warn + fall through), and decrypt-fail
(propagate). File reads enforce 0600 perms.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Rewrite `scripts/rotate-password`

**Files:**
- Modify: `scripts/rotate-password`

- [ ] **Step 1: Read current file**

```bash
cat scripts/rotate-password
```

Confirm legacy flags `--password-file`, `--password-dir`, `--write-source-password` are present and default destination is `$HOME/.config/chezmoi/password`.

- [ ] **Step 2: Replace file**

Overwrite `scripts/rotate-password` with **exactly**:

```bash
#!/bin/bash
set -euo pipefail

command -v age >/dev/null 2>&1 || { echo "age not found. Install with: brew install age" >&2; exit 1; }
command -v expect >/dev/null 2>&1 || { echo "expect not found. Install with: brew install expect" >&2; exit 1; }

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGE_KEY="$HOME/.config/chezmoi/key.txt"
KEY_AGE="$REPO_DIR/key.txt.age"

KEYCHAIN_SERVICE="dotfiles-passphrase"
DEFAULT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/passphrase"

AUTO_GENERATE=false
PASSWORD_LENGTH=32
USE_FILE=false
EXPLICIT_FILE=""

usage() {
  cat <<'EOF'
Usage: scripts/rotate-password [--auto] [--length N] [--file [PATH]]

Rotate the age passphrase that protects key.txt.age, and store it
in the platform-appropriate location:

  - macOS (default): macOS Keychain (service=dotfiles-passphrase, account=$USER)
  - Linux (default): ~/.config/dotfiles/passphrase (mode 0600)
  - --file [PATH]:   Force file storage (default path if PATH omitted)

Options:
  --auto           Auto-generate a new passphrase (A-Za-z0-9) via openssl.
  --length N       Password length for --auto. Default: 32.
  --file [PATH]    Write password to PATH instead of platform default.
                   PATH defaults to ~/.config/dotfiles/passphrase.
EOF
}

generate_password() {
  local out
  out=$(openssl rand -base64 $(( $1 * 2 )) | tr -dc 'A-Za-z0-9' | head -c "$1") || true
  printf '%s' "$out"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --auto)
      AUTO_GENERATE=true
      ;;
    --length)
      shift
      [ -z "${1:-}" ] && { echo "Error: --length requires a value." >&2; exit 1; }
      PASSWORD_LENGTH="$1"
      ;;
    --file)
      USE_FILE=true
      # Optional positional path for --file
      if [ -n "${2:-}" ] && [ "${2:0:2}" != "--" ]; then
        EXPLICIT_FILE="$2"
        shift
      fi
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if ! [[ "$PASSWORD_LENGTH" =~ ^[0-9]+$ ]] || [ "$PASSWORD_LENGTH" -le 0 ]; then
  echo "Error: --length must be a positive integer." >&2
  exit 1
fi

if [ ! -f "$AGE_KEY" ]; then
  echo "Age key not found: $AGE_KEY" >&2
  echo "Run 'chezmoi apply' first to decrypt the key, or follow the recovery section in" >&2
  echo "docs/superpowers/specs/2026-04-29-password-handling-design.md" >&2
  exit 1
fi

# Get new password
if [ "$AUTO_GENERATE" = true ]; then
  command -v openssl >/dev/null 2>&1 || { echo "openssl not found." >&2; exit 1; }
  NEW_PASSWORD="$(generate_password "$PASSWORD_LENGTH")"
  echo "Auto-generated a new passphrase (A-Za-z0-9, length=${PASSWORD_LENGTH})."
else
  printf "Enter new passphrase: "
  read -rs NEW_PASSWORD
  echo
  printf "Confirm new passphrase: "
  read -rs CONFIRM
  echo
  if [ "$NEW_PASSWORD" != "$CONFIRM" ]; then
    echo "Error: passphrases do not match." >&2
    exit 1
  fi
fi

if [ -z "$NEW_PASSWORD" ]; then
  echo "Error: passphrase must not be empty." >&2
  exit 1
fi

# Re-encrypt key.txt with new passphrase (atomic write)
TMPFILE=$(mktemp "$REPO_DIR/key.txt.age.XXXXXX")
trap 'rm -f "$TMPFILE"' EXIT

AGE_PW="$NEW_PASSWORD" AGE_KEY="$AGE_KEY" AGE_OUT="$TMPFILE" \
expect -c '
  log_user 0
  spawn age -p -o $env(AGE_OUT) $env(AGE_KEY)
  expect "Enter passphrase:"
  send "$env(AGE_PW)\r"
  expect "Confirm passphrase:"
  send "$env(AGE_PW)\r"
  expect eof
  catch wait result
  exit [lindex $result 3]
'

mv "$TMPFILE" "$KEY_AGE"
trap - EXIT

# Decide storage target
if [ "$USE_FILE" = true ]; then
  TARGET_FILE="${EXPLICIT_FILE:-$DEFAULT_FILE}"
  STORAGE="file"
elif [ "$(uname -s)" = "Darwin" ]; then
  STORAGE="keychain"
else
  TARGET_FILE="$DEFAULT_FILE"
  STORAGE="file"
fi

# Store password
case "$STORAGE" in
  keychain)
    if ! command -v security >/dev/null 2>&1; then
      echo "Error: 'security' command not found (macOS Keychain unavailable)." >&2
      exit 1
    fi
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" -w "$NEW_PASSWORD" -U
    echo "Stored password in macOS Keychain (service=$KEYCHAIN_SERVICE, account=$USER)."
    ;;
  file)
    mkdir -p "$(dirname "$TARGET_FILE")"
    chmod 700 "$(dirname "$TARGET_FILE")"
    umask 077
    printf "%s" "$NEW_PASSWORD" > "$TARGET_FILE"
    chmod 600 "$TARGET_FILE"
    echo "Wrote password file to: $TARGET_FILE"
    ;;
esac

echo "Password rotated. key.txt.age re-encrypted with new passphrase."
```

- [ ] **Step 3: Verify executable bit**

```bash
test -x scripts/rotate-password && echo "exec OK" || chmod +x scripts/rotate-password
```

- [ ] **Step 4: Verify shell syntax**

```bash
bash -n scripts/rotate-password && echo "syntax OK"
```

Expected: `syntax OK`.

- [ ] **Step 5: Verify --help shows new flags only**

```bash
scripts/rotate-password --help
```

Expected: usage block contains `--auto`, `--length`, `--file`. Does **not** mention `--password-dir` or `--write-source-password`.

- [ ] **Step 6: Verify legacy flags are gone**

```bash
grep -E 'password-dir|write-source-password|--password-file' scripts/rotate-password
```

Expected: empty.

- [ ] **Step 7: Commit**

```bash
git add scripts/rotate-password
git commit -m "$(cat <<'EOF'
feat: rotate-password writes to Keychain on macOS, XDG file on Linux

Default storage:
  macOS  -> macOS Keychain (service=dotfiles-passphrase, account=$USER)
  Linux  -> ~/.config/dotfiles/passphrase (mode 0600)

New flag --file [PATH] forces file storage. Drops --password-file,
--password-dir, --write-source-password (the source-dir .password
path is removed entirely).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Replace README.md `## Secrets` section

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Locate the section**

```bash
grep -n '^## Secrets' README.md
```

Confirm one match around line 144. The section runs from `## Secrets` to EOF.

- [ ] **Step 2: Replace the section**

Use Edit on `README.md`. The `old_string` is the entire current Secrets section + trailing line (lines 144 through EOF), starting from `## Secrets` and ending at `See [DESIGN.md](DESIGN.md) for requirements and design decisions.\n`.

The `new_string` is **exactly**:

````markdown
## Secrets

For non-interactive runs, the age passphrase that decrypts `key.txt.age`
is looked up in this order:

1. `$CHEZMOI_AGE_PASSWORD` env var
   - **Use only for CI / ephemeral / one-shot scenarios.** Env vars are
     visible to other same-user processes via `ps` /
     `/proc/<pid>/environ` / macOS equivalents — not recommended as
     steady-state storage.
2. **macOS Keychain** (Darwin only): service `dotfiles-passphrase`,
   account `$USER`.
   - May sync across your Macs via iCloud Keychain depending on your
     keychain configuration; not guaranteed.
3. **File** at `~/.config/dotfiles/passphrase` (mode `0600`).
   - Falls through with a warning if perms are not `0600`.
4. Interactive prompt fallback.

If a source returns an empty value or fails (e.g., locked Keychain),
the script falls through with a warning. If a source returns a
password but age decryption fails (i.e., wrong password), the script
exits with an error rather than continuing to the next source.

If you accidentally edit `~/.config/chezmoi/key.txt`, `chezmoi apply`
or `chezmoi update` re-decrypts it on every run and self-heals.

### Bootstrap & rotation

```bash
# Set / rotate password (default platform target)
scripts/rotate-password               # macOS: Keychain   Linux: ~/.config/dotfiles/passphrase
scripts/rotate-password --auto        # auto-generate A-Za-z0-9 (default length 32)
scripts/rotate-password --auto --length 48
scripts/rotate-password --file        # force file storage at default path
scripts/rotate-password --file /custom/path
```

### Edit encrypted files

```bash
scripts/edit-secret git-identity.toml.age
```

### Migrating from old password paths

The old paths (`~/.config/chezmoi/password` and source-dir `.password`)
are no longer read. To migrate:

```bash
scripts/rotate-password
rm -f ~/.config/chezmoi/password
rm -f "$(chezmoi source-path)/.password"   # if it exists
```

### Recovery (broken state)

If `~/.config/chezmoi/key.txt` is missing AND Keychain is empty / wrong
AND the password file is gone, `scripts/rotate-password` cannot help
(it requires the existing decrypted key). Recover manually:

```bash
SOURCE_DIR="$(chezmoi source-path)"
mkdir -p ~/.config/chezmoi
age -d "$SOURCE_DIR/key.txt.age" > ~/.config/chezmoi/key.txt   # prompts for password
chmod 600 ~/.config/chezmoi/key.txt

# macOS:
security add-generic-password -s dotfiles-passphrase -a "$USER" -w '<password>' -U
# Linux:
mkdir -p ~/.config/dotfiles && chmod 700 ~/.config/dotfiles
umask 077 && printf '%s' '<password>' > ~/.config/dotfiles/passphrase
chmod 600 ~/.config/dotfiles/passphrase

chezmoi diff   # verify
```

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
````

(Preserve the trailing newline at end of file.)

- [ ] **Step 3: Verify replacement**

```bash
grep -n '^## Secrets' README.md
grep -n 'dotfiles-passphrase' README.md
grep -n '\.config/chezmoi/password' README.md
```

Expected: `## Secrets` still present once. `dotfiles-passphrase` referenced multiple times. `.config/chezmoi/password` only present in the **migration step's `rm -f`** instruction (this is intentional, it's the cleanup line). Nothing else.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: update README Secrets section for new password handling

Documents the new lookup chain (env -> Keychain -> file -> interactive),
fall-through rules, migration steps from old paths, and recovery from
broken state.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Replace DESIGN.md `### Secret 管理` section

**Files:**
- Modify: `DESIGN.md`

- [ ] **Step 1: Locate the section**

```bash
grep -n '^### Secret 管理' DESIGN.md
grep -n '^## 关键约束' DESIGN.md
```

Confirm `### Secret 管理` exists. The section runs from that line to the line before `## 关键约束`.

- [ ] **Step 2: Replace the section**

Use Edit on `DESIGN.md`. `old_string` is the entire current `### Secret 管理` block (header line through the last bullet — `密码轮换：scripts/rotate-password ...`). Stop **before** the blank line that precedes `## 关键约束`.

`new_string` is **exactly**:

```markdown
### Secret 管理

使用 **age 加密 + 密码保护**：

- 加密后的私钥（`key.txt.age`）存仓库，由密码保护
- **密码 lookup 链（优先级从高到低）**：
  1. `$CHEZMOI_AGE_PASSWORD` env var（**仅 CI / ephemeral 推荐**；same-user 进程可见，不作稳态）
  2. macOS Keychain（仅 Darwin；service=`dotfiles-passphrase`, account=`$USER`）
  3. 文件 `~/.config/dotfiles/passphrase`（必须 `0600` 权限）
  4. 交互式输入（chezmoi age decrypt 自身 prompt）
- **Fall-through 规则**：源未找到 → 安静下一层；源空 / 访问失败 → warning + 下一层；密码错（age 解密失败）→ 报错退出（不继续 fallthrough）
- **密码轮换**：`scripts/rotate-password`（macOS 默认写 Keychain，Linux 写 `~/.config/dotfiles/passphrase`）。key.txt.age 用新密码重新加密；其他 .age 文件用 age 公钥加密，不受密码轮换影响
- Git 用户名 / 邮箱存在 `git-identity.toml.age`，模板自动解密读取，无需 prompt
- 其他敏感文件通过 `chezmoi add --encrypt` 加入仓库
- **Broken state 恢复**：见 README "Recovery" 段
```

- [ ] **Step 3: Verify**

```bash
grep -n 'dotfiles-passphrase\|dotfiles/passphrase' DESIGN.md
grep -n 'Fall-through' DESIGN.md
```

Expected: matches in DESIGN.md.

- [ ] **Step 4: Commit**

```bash
git add DESIGN.md
git commit -m "$(cat <<'EOF'
docs: update DESIGN.md Secret 管理 for new lookup chain

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Final verification

**Files:** none modified — read-only checks plus optional in-machine smoke test.

- [ ] **Step 1: All four files reference the new identifiers**

```bash
grep -l 'dotfiles-passphrase\|dotfiles/passphrase' \
  .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl \
  scripts/rotate-password \
  README.md \
  DESIGN.md
```

Expected: all four file paths printed.

- [ ] **Step 2: No file mentions legacy flags / paths**

```bash
grep -nE 'password-dir|write-source-password|--password-file' \
  scripts/rotate-password .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl
```

Expected: empty.

```bash
grep -nE '\$SOURCE_DIR/\.password' .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl
```

Expected: empty.

```bash
grep -nE '\.config/chezmoi/password' .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl scripts/rotate-password
```

Expected: empty (the only allowed remaining mention is in `README.md` under "Migrating", as part of the `rm -f` cleanup hint).

- [ ] **Step 3: Render run_before_00 end-to-end and confirm it parses**

```bash
chezmoi execute-template < .chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl > /tmp/rb00-final.sh
bash -n /tmp/rb00-final.sh && echo "render+parse OK"
rm /tmp/rb00-final.sh
```

Expected: `render+parse OK`.

- [ ] **Step 4: rotate-password help reflects new shape**

```bash
scripts/rotate-password --help | grep -E 'auto|length|file'
```

Expected: lines for `--auto`, `--length N`, `--file [PATH]`.

- [ ] **Step 5: Optional smoke test (only on a real machine with an existing setup)**

If this plan is being executed on a machine that already has a working chezmoi setup (i.e., `~/.config/chezmoi/key.txt` exists and is decryptable):

```bash
# Confirm chezmoi diff still works (should produce diff or empty, no errors)
chezmoi diff > /dev/null && echo "chezmoi diff OK"
```

Skip this step in CI / fresh-clone scenarios where chezmoi state is not initialized.

- [ ] **Step 6: Confirm the commit graph**

```bash
git log --oneline -5
```

Expected: recent commits include the four `feat:` / `docs:` commits from Tasks 1–4 plus this plan's earlier `docs: add password handling redesign spec`.

---

## Self-review

Run mentally before declaring complete:

1. **Spec coverage**:
   - 4-layer lookup chain (env → Keychain → file → interactive) → Task 1
   - Fall-through rules (4 cases: not-found / empty / access-fail / decrypt-fail) → Task 1
   - File 0600 enforcement on read → Task 1
   - File path `~/.config/dotfiles/passphrase` (XDG) → Tasks 1, 2, 3
   - Keychain service `dotfiles-passphrase`, account `$USER` → Tasks 1, 2
   - rotate-password macOS=Keychain default, Linux=file default → Task 2
   - `--file [PATH]` flag → Task 2
   - Drop legacy flags → Task 2
   - Migration docs → Task 3
   - Recovery docs → Task 3
   - DESIGN.md sync → Task 4
2. **Placeholder scan**: code blocks have full content. Recovery section uses `'<password>'` as a literal user-input template — intentional, **not** a TODO.
3. **Type / name consistency** across tasks:
   - Service name: `dotfiles-passphrase` (Tasks 1 keychain block, 2 KEYCHAIN_SERVICE, 3 README, 4 DESIGN)
   - Account: `$USER` (Tasks 1, 2, 3, 4)
   - Default file path: `~/.config/dotfiles/passphrase` literal in docs; `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/passphrase` in code (these are equivalent)
   - Lookup order matches between `run_before_00`, README, DESIGN.md
