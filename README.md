# dotfiles

Managed by [Chezmoi](https://www.chezmoi.io/). Supports macOS and Linux (Arch/Ubuntu/Debian).

## Install

```bash
# Personal macOS (full toolchain)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=personal \
  --promptBool installGo=true --promptBool installRust=true \
  --promptBool installNode=true --promptBool installUv=true

# Work macOS
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=work

# Remote Linux server
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=remote
```

Language tools default to **not installed**. Enable with `--promptBool`:

```bash
--promptBool installGo=true
--promptBool installRust=true
--promptBool installNode=true
--promptBool installUv=true
```

## Update

```bash
chezmoi update
```

## Machine Types

|  | personal | work | remote |
|---|:---:|:---:|:---:|
| OS | macOS | macOS | Linux |
| Homebrew + casks | ✓ | ✓ | — |
| apt / pacman | — | — | ✓ |
| tmux | gpakosz theme | gpakosz theme | minimal |
| oh-my-zsh | ✓ | ✓ | ✓ |
| vim + plugins | ✓ | ✓ | ✓ |
| Git identity | age encrypted | age encrypted | age encrypted |

## Language Tools

All default to false. Enable during install or change after.

| Flag | Tool | Install method |
|------|------|---------------|
| `installGo` | Go | brew / apt / pacman |
| `installRust` | Rust | rustup (curl) |
| `installNode` | Node.js | fnm (curl) |
| `installUv` | uv | pipx |

**Change after install:**

```bash
# Edit config
vim ~/.config/chezmoi/chezmoi.toml
# Re-apply
chezmoi apply
```

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
