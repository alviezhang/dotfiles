# dotfiles

Managed by [Chezmoi](https://www.chezmoi.io/). Supports macOS and Linux (Arch/Ubuntu/Debian).

## Install

```bash
# Personal (full toolchain)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=personal \
  --promptBool installGo=true --promptBool installRust=true \
  --promptBool installNode=true --promptBool installUv=true

# Work
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=work

# Remote server
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

Machine type and OS are **independent dimensions**. System packages are auto-detected by OS.

|  | personal | work | remote |
|---|:---:|:---:|:---:|
| OS | macOS / Linux | macOS / Linux | Linux |
| tmux | gpakosz theme | gpakosz theme | minimal |
| oh-my-zsh | ✓ | ✓ | ✓ |
| vim + plugins | ✓ | ✓ | ✓ |
| Git identity | age encrypted | age encrypted | age encrypted |

**System packages** (auto by OS, all machine types):

| OS | Package manager | Packages |
|---|---|---|
| macOS | Homebrew (brew bundle) | `platform/darwin/Brewfile` |
| Ubuntu/Debian | apt | `platform/linux/apt.list` |
| Arch | pacman | `platform/linux/pacman.list` |

## Language Tools

All default to false. Independent of machine type and OS.

| Flag | Tool | Install method |
|------|------|---------------|
| `installGo` | Go | brew / apt / pacman |
| `installRust` | Rust | rustup (curl) |
| `installNode` | Node.js | fnm (curl) |
| `installUv` | uv | pipx |

**Change after install:**

```bash
vim ~/.config/chezmoi/chezmoi.toml    # edit flags
chezmoi apply                         # re-apply
```

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
