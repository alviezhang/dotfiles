# dotfiles

Managed by [Chezmoi](https://www.chezmoi.io/). Supports macOS and Linux (Arch/Ubuntu/Debian).

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
- Legacy rustup installs under `~/.cargo/bin` and `~/.rustup` are also detected for PATH setup and cargo package management.
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

> **Note**: `scripts/rotate-password` invokes `security add-generic-password -w "$PW"`
> on macOS. The password is briefly visible via `ps`/argv during the security call —
> macOS `security` CLI offers no stdin alternative. Acceptable for single-user
> machines; if you need stricter handling, use `--file` to bypass the Keychain path.

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
