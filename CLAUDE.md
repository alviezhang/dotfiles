# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository managed by [Chezmoi](https://www.chezmoi.io/), supporting macOS and Linux (Arch/Ubuntu/Debian). The repo root is the chezmoi source directory.

## Quick Start

```bash
# New machine: install chezmoi + apply all dotfiles
make install

# Re-apply after editing source files
make apply

# Pull repo updates and re-apply
make update
```

## Machine Types

On first `chezmoi init`, you'll be prompted for:
- **Machine type**: personal / work / remote
- **Tool switches**: Go, Rust, Node.js, pipx (Python CLIs) — per-machine toggle

## Directory Structure

- **`dot_*` / `symlink_dot_*`** — Chezmoi-managed dotfiles (placed into `~/`)
- **`dot_config/`** — XDG config files (fontconfig for Linux)
- **`packages/`** — Global package lists (pipx / npm / cargo)
- **`platform/`** — OS-specific system package lists (not placed into `~/`)
  - `darwin/Brewfile` — Homebrew formulas and casks
  - `linux/apt.list` / `pacman.list` — Linux package lists
- **`scripts/`** — Maintenance helpers for encrypted files and passphrase rotation
- **`.chezmoiscripts/`** — Install scripts (run by chezmoi)
  - Root level: cross-platform (ohmyzsh, vim plugins, pipx packages, rust, fnm, tmux theme, global packages)
  - `darwin/`: Homebrew install + brew bundle
  - `linux/`: apt/pacman package install

## Key Files

- `.chezmoi.toml.tmpl` — Machine type, tool switches, age identity/recipient
- `.chezmoiignore.tmpl` — Files excluded from `~/`
- `.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl` — Passphrase lookup and age key regeneration
- `scripts/rotate-password` — Rotate the `key.txt.age` passphrase and store it in Keychain or a `0600` file
- `scripts/edit-secret` — Edit age-encrypted files without committing plaintext

## Secrets

- Never commit decrypted `key.txt` or plaintext `git-identity.toml`.
- Passphrase lookup order is env var, macOS Keychain, `~/.config/dotfiles/passphrase`, then interactive prompt.
- The bundled Keychain helper writes synchronizable items into a `keychain-access-groups`-scoped slot, so passphrases sync between Macs sharing the same Apple ID with iCloud Keychain enabled. Sync is best-effort and asynchronous.
- Build-time access-group literal lives in `scripts/kc-config.swift`; public docs and comments should use generic `TEAMID.bundle.id`.

## Design Principles

- **Idempotent**: scripts run safely multiple times. Package lists re-run on content change via `run_onchange_` + content hash.
- **No sudo for user-space tooling**: language toolchains (Rust, Node, pipx) install to `$XDG_DATA_HOME` / `~/.local`; only system package managers (brew/apt/pacman) need elevation.
- **PATH is centralized in `.zshrc`** with runtime existence checks — manually-installed tools work without re-running chezmoi.
- **No interactive prompts post-bootstrap** once a passphrase source is configured. Machine type + tool toggles come from `--promptString` / env vars.
- **Out of scope**: SSH key management, font installation, macOS `defaults`.
