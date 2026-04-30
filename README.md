# dotfiles

My [Chezmoi](https://www.chezmoi.io/)-managed dotfiles for macOS and Linux. The repo keeps the base shell/editor setup portable, stores private material as age-encrypted files, and lets each machine opt into only the toolchains it needs.

## Highlights

- **One-command bootstrap** for a clean macOS or Linux account.
- **`personal` / `work` / `remote` profiles** with shared defaults and profile-specific tmux behavior.
- **age-encrypted secrets**: only ciphertext (`key.txt.age`, `git-identity.toml.age`) lives in the repo, and the decrypted key is rebuilt on each apply/update.
- **macOS Keychain support** for non-interactive updates, with **iCloud Keychain sync** between Macs using the same Apple ID. The bundled helper reads the passphrase from stdin (no argv leak); file and env-var fallbacks cover Linux and CI.
- **Opt-in language tools**: Go, Rust, Node.js, and pipx can be enabled per machine via TOML or env vars.

## Install

```bash
# Personal
bash -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=personal

# Work
bash -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=work

# Remote server
bash -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=remote
```

You can also configure machine type and language tools via environment variables:

```bash
CHEZMOI_MACHINE_TYPE=work \
CHEZMOI_INSTALL_GO=1 \
CHEZMOI_INSTALL_RUST=1 \
CHEZMOI_INSTALL_NODE=1 \
CHEZMOI_INSTALL_PIPX=1 \
bash -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang
```

- `CHEZMOI_MACHINE_TYPE`: `personal` / `work` / `remote`
- `CHEZMOI_INSTALL_GO`, `CHEZMOI_INSTALL_RUST`, `CHEZMOI_INSTALL_NODE`, `CHEZMOI_INSTALL_PIPX`:
  - set to `1` / `true` / `yes` / `on` to enable
  - set to `0` / `false` / `no` / `off` to disable
  - unset to follow `~/.config/chezmoi/chezmoi.toml`

For non-interactive runs, see [Secrets](#secrets) below for password setup.

## Enable Language Tools

Language tools default to not installed. After init, edit config to enable:

```bash
vim ~/.config/chezmoi/chezmoi.toml
```

```toml
[data]
  installGo   = true
  installRust = true
  installNode = true
  installPipx = true
```

```bash
chezmoi apply
```

## Update

```bash
chezmoi update
```

## Local Cleanup

```bash
make clean
```

## Machine Types

Machine type and OS are independent dimensions. System packages auto-detect by OS.

|  | personal | work | remote |
|---|:---:|:---:|:---:|
| OS | macOS / Linux | macOS / Linux | Linux |
| tmux | gpakosz theme | gpakosz theme | minimal |
| oh-my-zsh | ✓ | ✓ | ✓ |
| vim + plugins | ✓ | ✓ | ✓ |
| Git identity | age encrypted | age encrypted | age encrypted |

## Tmux

- **personal/work**: clone `gpakosz/.tmux` into `$XDG_DATA_HOME/tmux/gpakosz-tmux`, then symlink `~/.tmux.conf` to its `.tmux.conf`.
- **remote**: write a minimal `~/.tmux.conf` (no theme).
- Chezmoi manages `~/.config/tmux/tmux.conf.local` and creates `~/.tmux.conf.local` symlink for the theme (skipped on `remote`).

**System packages** (auto by OS):

| OS | Package manager | Config |
|---|---|---|
| macOS | Homebrew | `platform/darwin/Brewfile` |
| Ubuntu/Debian | apt | `platform/linux/apt.list` |
| Arch | pacman | `platform/linux/pacman.list` |

## Language Tools

| Flag | Tool | Install method |
|------|------|---------------|
| `installGo` | Go | brew / apt / pacman |
| `installRust` | Rust | rustup (curl) |
| `installNode` | Node.js | fnm (curl) |
| `installPipx` | Python CLIs (pipx) | pipx (installed via Python) |

Rust uses XDG paths by default:
- `CARGO_HOME=$XDG_DATA_HOME/cargo`
- `RUSTUP_HOME=$XDG_DATA_HOME/rustup`
- Default Rust mirror is USTC. Override `RUSTUP_DIST_SERVER` and `RUSTUP_UPDATE_ROOT` if your network requires different endpoints.

`.zshrc` auto-detects installed tools at runtime — manually installed tools also work.

## Global Packages

This repo manages "global" packages for each toolchain via list files under `packages/`:

- `packages/pipx.list` (includes `uv` by default)
- `packages/npm.list`
- `packages/cargo.list`

`pipx` is installed via Python (Linux: system `python3`, macOS: Homebrew `python3`).

After editing, run:

```bash
chezmoi apply
```

## Secrets

For non-interactive runs, the age passphrase that decrypts `key.txt.age`
is looked up in this order:

1. `$CHEZMOI_AGE_PASSWORD` env var
   - **Use only for CI / ephemeral / one-shot scenarios.** Env vars are
     visible to other same-user processes via `ps` /
     `/proc/<pid>/environ` / macOS equivalents — not recommended as
     steady-state storage.
2. **macOS Keychain** (Darwin only): service `dotfiles-passphrase`,
   account `$USER`. `scripts/rotate-password` writes through the bundled
   [`dotfiles-keychain`](#bundled-keychain-helper) helper; bootstrap reads
   through the helper, or through `security` if the helper is unavailable.
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

> On macOS, `scripts/rotate-password` writes via the bundled
> `dotfiles-keychain` helper, which takes the password on **stdin** —
> the new passphrase never appears in `ps` / argv. Use `--file` if
> you'd rather store the password as a `0600` file on disk and skip
> the Keychain entirely.

### Bundled Keychain helper

`scripts/dotfiles-keychain` is a small Developer ID–signed Swift CLI
that the rotation script writes through, taking the passphrase on
**stdin** (no `ps` / argv leak). Source: `scripts/keychain-helper.swift`;
build configuration in `scripts/kc-config.swift`.

The passphrase is stored as a synchronizable Keychain item, so it
propagates between Macs sharing the same Apple ID with iCloud Keychain
enabled. Sync is best-effort and asynchronous: minutes, sometimes
longer. Until sync lands on a fresh Mac, use the file / env-var fallback
if you need immediate bootstrap.

If you'd rather skip Keychain entirely, use `scripts/rotate-password --file`
and sync `~/.config/dotfiles/passphrase` via 1Password / Bitwarden /
Syncthing / `scp`.

### Edit encrypted files

```bash
scripts/edit-secret git-identity.toml.age
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

printf "Age passphrase: "
read -rs PW
echo

# Store in the default platform location:
if [ "$(uname -s)" = "Darwin" ]; then
    printf '%s' "$PW" | "$SOURCE_DIR/scripts/dotfiles-keychain" \
        set dotfiles-passphrase "$USER"
else
    mkdir -p ~/.config/dotfiles && chmod 700 ~/.config/dotfiles
    umask 077 && printf '%s' "$PW" > ~/.config/dotfiles/passphrase
    chmod 600 ~/.config/dotfiles/passphrase
fi
unset PW

chezmoi diff   # verify
```
