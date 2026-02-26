# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository managed by [Chezmoi](https://www.chezmoi.io/), supporting macOS and Linux (Arch/Ubuntu/Debian). The repo root is the chezmoi source directory.

See [DESIGN.md](DESIGN.md) for requirements and design decisions.

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
- **Tool switches**: Rust, Node.js, uv — per-machine toggle

## Directory Structure

- **`dot_*` / `symlink_dot_*`** — Chezmoi-managed dotfiles (placed into `~/`)
- **`dot_oh-my-zsh/custom/`** — Oh My Zsh custom scripts (proxy, OS aliases)
- **`dot_config/`** — XDG config files (fontconfig for Linux)
- **`platform/`** — OS-specific package lists (not placed into `~/`)
  - `darwin/Brewfile` — Homebrew formulas and casks
  - `linux/apt.list` / `pacman.list` — Linux package lists
- **`.chezmoiscripts/`** — Install scripts (run by chezmoi)
  - Root level: cross-platform (ohmyzsh, vim plugins, uv, rust, fnm)
  - `darwin/`: Homebrew install + brew bundle
  - `linux/`: apt/pacman package install

## Key Files

- `.chezmoi.toml.tmpl` — Machine type, tool switches, Bitwarden config
- `.chezmoiexternal.toml.tmpl` — External deps (gpakosz/.tmux)
- `.chezmoiignore.tmpl` — Files excluded from `~/`
- `DESIGN.md` — Requirements and design decisions
