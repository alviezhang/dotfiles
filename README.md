# dotfiles

Managed by [Chezmoi](https://www.chezmoi.io/). Supports macOS and Linux (Arch/Ubuntu/Debian).

## Install

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply alviezhang
```

## Update

```bash
chezmoi update
```

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
