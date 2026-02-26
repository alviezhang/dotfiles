# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modular dotfiles repository supporting macOS and Linux (Arch/Ubuntu/Debian). Each tool has its own subdirectory with a `Makefile` providing a consistent `install`/`uninstall` interface.

## Install & Uninstall

```bash
# Install one or more modules
./install.sh [module1] [module2] ...

# Uninstall one or more modules
./uninstall.sh [module1] [module2] ...

# Or directly via make
make -C <module> install
make -C <module> uninstall
```

Available modules: `brew`, `tmux`, `ohmyzsh`, `vim`, `git`, `pyenv`, `macports`, `archlinux`

### Typical setups

```bash
# macOS full setup
./install.sh brew macports tmux ohmyzsh vim git pyenv

# Linux (Arch) setup
./install.sh ohmyzsh vim git pyenv archlinux
```

## Module Architecture

Each module follows the same pattern:

- A `Makefile` with at minimum `install` and `uninstall` targets
- Config files that get either symlinked or copied to `~` or `~/.config/`

Key modules:

- **brew/** — Homebrew package lists (`packages.list`, `casks.list`, `essentials.list`) and Karabiner config
- **tmux/** — Based on [gpakosz/.tmux](https://github.com/gpakosz/.tmux); local overrides live in `tmux/tmux.conf.local` which gets copied to `~/.tmux.conf.local`
- **ohmyzsh/** — Patches `~/.zshrc` to source `preload.zsh`; platform-specific config in `macos.zsh` / `linux.zsh`; dev tooling (NVM, Go, pyenv, Rust) in `dev.zsh`
- **vim/** — Uses Vundle; `vimrc` is copied to `~/.vimrc` and plugins are auto-installed
- **git/** — `gitconfig` copied to `~/.gitconfig` (includes SSH-over-HTTPS redirect for GitHub)
- **archlinux/fontconfig/** — Symlinks `.conf` files into `~/.config/fontconfig/conf.d/`
- **macports/** — Runs `sudo port install` for each entry in `ports.txt`

## ohmyzsh Patching Mechanism

`ohmyzsh/install.zsh` inserts a `source preload.zsh` block into `~/.zshrc` immediately after the `plugins=()` line. `preload.zsh` selects plugins based on the current OS. To reapply after changes:

```bash
make -C ohmyzsh repatch
```

## tmux Local Config

`tmux/tmux.conf.local` is the only file you should edit for tmux customizations — it is copied (not symlinked) to `~/.tmux.conf.local`. After editing, copy it manually or run `make -C tmux install` again.

## Proxy Helper (ohmyzsh/dev.zsh)

The shell provides `proxy` and `direct` functions for toggling HTTP/HTTPS/SOCKS proxy settings. The proxy host can be customized via environment variables.
