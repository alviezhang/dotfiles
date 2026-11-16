# dotfiles

My [Chezmoi](https://www.chezmoi.io/)-managed dotfiles for macOS and Linux. The repo keeps the base shell/editor setup portable, stores private material as age-encrypted files, and lets each machine opt into only the toolchains it needs.

## Highlights

- **One-command bootstrap** for a clean macOS or Linux account. The only prerequisite is `curl`, plus the Command Line Tools on macOS; decryption uses chezmoi's built-in age, so no `age` or `expect` binary is needed.
- **`personal` / `work` / `remote` profiles** with shared defaults and profile-specific tmux behavior.
- **age-encrypted secrets**: only ciphertext (`key.txt.age`, `git-identity.toml.age`) lives in the repo. Every apply checks the decrypted key against `age-recipient.txt` and rebuilds it only when it is missing or wrong.
- **macOS Keychain support** with **iCloud Keychain sync** between Macs using the same Apple ID. The bundled helper reads the passphrase from stdin (no argv leak); file and env-var fallbacks cover Linux and CI.
- **Opt-in language tools**: Go, Rust, Node.js, and pipx can be enabled per machine via TOML or env vars.

## Install

On macOS, install the Command Line Tools first. chezmoi clones with the system `git`, and until the Command Line Tools are installed `/usr/bin/git` is only a stub that opens their installer:

```bash
xcode-select --install
```

On Linux only `curl` is needed: without a `git` binary chezmoi clones with its built-in git, and `git` is then installed with the system packages.

```bash
# Personal
sh -c "$(curl --proto '=https' --tlsv1.2 -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=personal

# Work
sh -c "$(curl --proto '=https' --tlsv1.2 -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=work

# Remote server
sh -c "$(curl --proto '=https' --tlsv1.2 -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=remote
```

On a fresh Mac, run this from an administrator account: the Homebrew installer asks for your password.

You can also configure machine type and language tools via environment variables:

```bash
CHEZMOI_MACHINE_TYPE=work \
CHEZMOI_INSTALL_GO=1 \
CHEZMOI_INSTALL_RUST=1 \
CHEZMOI_INSTALL_NODE=1 \
CHEZMOI_INSTALL_PIPX=1 \
sh -c "$(curl --proto '=https' --tlsv1.2 -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang
```

- `CHEZMOI_MACHINE_TYPE`: `personal` / `work` / `remote`
- `CHEZMOI_INSTALL_GO`, `CHEZMOI_INSTALL_RUST`, `CHEZMOI_INSTALL_NODE`, `CHEZMOI_INSTALL_PIPX`:
  - `0` / `false` / `no` / `off` disables; any other non-empty value enables
  - unset to follow `~/.config/chezmoi/chezmoi.toml`

For non-interactive runs, see [Secrets](#secrets) below for password setup.

## What bootstrap does

`chezmoi apply` runs in three stages:

| Stage | What runs | On failure |
|---|---|---|
| Before files | Check `~/.config/chezmoi/key.txt`; decrypt `key.txt.age` only if the key is missing or does not match `age-recipient.txt` | Apply stops; nothing else is written |
| Files | Dotfiles are written to `~` | — |
| After files | Homebrew (macOS) or missing apt/pacman packages (Linux), oh-my-zsh, tmux theme, enabled language tools, pipx/cargo/npm packages, vim plugins, `brew bundle` (last) | Apply exits non-zero; dotfiles are already in place, and the failed step reruns on the next `chezmoi apply` |

Later steps depend on earlier ones (for example oh-my-zsh needs `git`), so a failure stops the remaining steps of that run. Fix the cause, or just rerun `chezmoi apply` after a network error.

vim plugins are installed only when `chezmoi apply` runs in a terminal; otherwise apply prints a reminder to run `:PlugInstall`.

On Linux, only packages that are not yet installed are passed to apt/pacman, so an already provisioned host does not need `sudo`. On distributions without apt or pacman the package step prints a warning and the rest of bootstrap continues; install the tools from `platform/linux/*.list` yourself. Locales are not generated: `.zshrc` uses `en_US.UTF-8` where it exists and glibc's built-in `C.UTF-8` otherwise.

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

## System Packages

Installed automatically by OS:

| OS | Package manager | Config |
|---|---|---|
| macOS | Homebrew | `platform/darwin/Brewfile` |
| Ubuntu/Debian | apt | `platform/linux/apt.list` |
| Arch | pacman | `platform/linux/pacman.list` |

## Language Tools

| Flag | Tool | Install method |
|------|------|---------------|
| `installGo` | Go | brew / apt / pacman |
| `installRust` | Rust | rustup (official installer) |
| `installNode` | Node.js | fnm (macOS: brew; Linux: official installer), then latest LTS |
| `installPipx` | Python CLIs (pipx) | pipx (brew / apt / pacman) |

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

`pipx` itself comes from the system package manager (macOS: `brew install pipx`; Linux: apt `pipx` / pacman `python-pipx`).

After editing, run:

```bash
chezmoi apply
```

## Secrets

Every apply first checks that `~/.config/chezmoi/key.txt` is the private key for `age-recipient.txt`. If it is, no passphrase is read at all. Only when the key is missing or wrong is the age passphrase for `key.txt.age` looked up, in this order:

1. `$CHEZMOI_AGE_PASSWORD` env var
   - **Use only for CI / ephemeral / one-shot scenarios.** Env vars are
     visible to other same-user processes via `ps` /
     `/proc/<pid>/environ` / macOS equivalents — not recommended as
     steady-state storage.
2. **macOS Keychain** (Darwin only): service `dotfiles-passphrase`,
   account `$USER`, read and written through the bundled
   [`dotfiles-keychain`](#bundled-keychain-helper) helper.
3. **File** at `~/.config/dotfiles/passphrase` (mode `0600`).
   - Falls through with a warning if perms are not `0600`.
4. Interactive prompt fallback.

If a source returns an empty value or fails (e.g., locked Keychain),
the script falls through with a warning. If a source returns a
password but decryption fails (i.e., wrong password), the script
exits with an error rather than continuing to the next source.

The key is decrypted to a `0600` temp file and checked against `age-recipient.txt` before it replaces `key.txt`. A failed or mismatched decrypt never deletes or overwrites the existing key.

### Bootstrap & rotation

```bash
# Set / rotate password (default platform target)
scripts/rotate-password               # macOS: Keychain   Linux: ~/.config/dotfiles/passphrase
scripts/rotate-password --auto        # auto-generate A-Za-z0-9 (default length 32)
scripts/rotate-password --auto --length 48
scripts/rotate-password --file        # force file storage at default path
scripts/rotate-password --file /custom/path
```

Rotation re-encrypts `key.txt.age`, verifies it decrypts with the new passphrase, stores the passphrase, and only then replaces `key.txt.age`. **Commit and push `key.txt.age` afterwards**, otherwise other machines are left with a passphrase that does not match their copy.

On macOS, `--file` also deletes the Keychain entry, because the Keychain takes precedence over the file. The deletion syncs to your other Macs.

### Bundled Keychain helper

`scripts/dotfiles-keychain` is a small Developer ID–signed Swift CLI
that the rotation script writes through, taking the passphrase on
**stdin** (no `ps` / argv leak). Source: `scripts/keychain-helper.swift`;
build configuration in `scripts/kc-config.swift`; rebuild with
`scripts/build-keychain-helper` (requires the Developer ID signing
identity and the provisioning profile).

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

If `~/.config/chezmoi/key.txt` is missing and the stored passphrase is
wrong (or gone), remove the stale source so apply falls back to the
interactive prompt, then type the passphrase in a terminal:

```bash
# macOS: remove a stale Keychain entry (syncs to your other Macs)
"$(chezmoi source-path)/scripts/dotfiles-keychain" delete dotfiles-passphrase "$USER"
# Linux / file storage: remove a stale passphrase file
rm -f ~/.config/dotfiles/passphrase

chezmoi apply   # prompts for the passphrase and restores key.txt
```

Then store the passphrase again so future recoveries are non-interactive:

```bash
SOURCE_DIR="$(chezmoi source-path)"
printf "Age passphrase: "; read -rs PW; echo
if [ "$(uname -s)" = "Darwin" ]; then
    printf '%s' "$PW" | "$SOURCE_DIR/scripts/dotfiles-keychain" set dotfiles-passphrase "$USER"
else
    mkdir -p ~/.config/dotfiles && chmod 700 ~/.config/dotfiles
    (umask 077 && printf '%s' "$PW" > ~/.config/dotfiles/passphrase)
fi
unset PW
```

## Development

```bash
make test
```

Runs `tests/*.sh` in an isolated `HOME` with throwaway keys and passphrases: key decryption and failure safety, an end-to-end `chezmoi init --apply` with stubbed installers, template rendering for every OS × machine type × tool toggle, and passphrase rotation. They never read your real key, Keychain, or passphrase file.

```bash
make test-linux
```

Bootstraps from scratch in `debian:stable`, `ubuntu:latest`, and `archlinux:latest` containers as a non-root user, for both `remote` and `personal`, with the real installers and throwaway keys. Needs Docker and network access.
