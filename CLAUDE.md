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

# Run the isolated test suite
make test
```

## Machine Types

On first `chezmoi init`, you'll be prompted for the **machine type** (personal / work / remote) unless `--promptString machineType=...` or `CHEZMOI_MACHINE_TYPE` is given. Tool switches (Go, Rust, Node.js, pipx) are not prompted: they default to off and are set via `CHEZMOI_INSTALL_*` env vars or `~/.config/chezmoi/chezmoi.toml`.

## Directory Structure

- **`dot_*`** — Chezmoi-managed dotfiles (placed into `~/`)
- **`dot_config/`** — XDG config files (fontconfig for Linux, tmux theme overrides)
- **`packages/`** — Global package lists (pipx / npm / cargo)
- **`platform/`** — OS-specific system package lists (not placed into `~/`)
  - `darwin/Brewfile` — Homebrew formulas and casks
  - `linux/apt.list` / `pacman.list` — Linux package lists
- **`scripts/`** — Maintenance helpers for encrypted files, passphrase rotation, and the Keychain helper
- **`.chezmoiscripts/`** — Install scripts, flat (no subdirectories: they sort after numeric names and break ordering)
  - `run_before_00-decrypt-private-key` is the only before-script
  - Everything else is `run_*after_NN-*`, ordered by `NN`; OS- or toggle-specific scripts wrap the whole file in a template condition and render empty when not applicable
- **`.chezmoitemplates/lib.sh`** — Shared prelude for install scripts: PATH for freshly installed tools, `run_as_root`, HTTPS-only `fetch`, `list_items`, `use_rustup_home`
- **`tests/`** — Isolated tests run by `make test`

## Key Files

- `.chezmoi.toml.tmpl` — Machine type, tool switches, age identity/recipient, `useBuiltinAge = true`
- `.chezmoiignore.tmpl` — Files excluded from `~/`; patterns match **target** paths (`.config/...`), not source paths (`dot_config/...`)
- `.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl` — Verifies `key.txt` against `age-recipient.txt`; decrypts `key.txt.age` only when missing or mismatched
- `scripts/rotate-password` — Rotate the `key.txt.age` passphrase and store it in Keychain or a `0600` file
- `scripts/edit-secret` — Edit age-encrypted files without committing plaintext
- `scripts/build-keychain-helper` — Rebuild and sign `scripts/dotfiles-keychain.app`

## Secrets

- Never commit decrypted `key.txt` or plaintext `git-identity.toml`.
- Passphrase lookup order is env var, macOS Keychain, `~/.config/dotfiles/passphrase`, then interactive prompt — and only when `key.txt` is missing or does not match the recipient.
- Passphrases go to chezmoi on stdin, never argv or exported env.
- The bundled Keychain helper writes synchronizable items into a `keychain-access-groups`-scoped slot, so passphrases sync between Macs sharing the same Apple ID with iCloud Keychain enabled. Sync is best-effort and asynchronous.
- Build-time access-group literal lives in `scripts/kc-config.swift`; public docs and comments should use generic `TEAMID.bundle.id`.

## Design Principles

- **Bootstrap depends only on chezmoi and curl**, plus the Command Line Tools on macOS (a stated prerequisite that provides `git`). Decryption and template `decrypt` use chezmoi's built-in age.
- **Dotfiles land before any installer runs**: installers are after-scripts, so a failed install never blocks config. Failures exit non-zero and chezmoi reruns them on the next apply.
- **Idempotent**: scripts run safely multiple times. Package lists re-run on content change via `run_onchange_` + content hash; every-run checks (`run_after_`) exit immediately when already satisfied.
- **No sudo for user-space tooling**: language toolchains (Rust, Node, pipx) install to `$XDG_DATA_HOME` / `~/.local`; only system package managers (brew/apt/pacman) need elevation, and Linux only asks for it when a package is actually missing.
- **PATH is centralized in `.zshrc`** with runtime existence checks — manually-installed tools work without re-running chezmoi. Install scripts get the same paths from `lib.sh`.
- **No interactive prompts post-bootstrap** once a passphrase source is configured. Machine type + tool toggles come from `--promptString` / env vars.
- **Out of scope**: SSH key management, font installation, macOS `defaults`.

## Testing

- Tests must `unset XDG_CONFIG_HOME` (and the other XDG vars) besides overriding `HOME`: chezmoi prefers `XDG_CONFIG_HOME`, so a test that only changes `HOME` writes to the user's real `~/.config/chezmoi/chezmoi.toml`.
- Use throwaway keys and passphrases and a stub `scripts/dotfiles-keychain`; never touch the real Keychain or `key.txt`.
- `make test` runs the isolated local tests; `make test-linux` (`tests/linux-bootstrap.sh`) needs Docker. macOS first-run can only be verified in a fresh user account or VM.
