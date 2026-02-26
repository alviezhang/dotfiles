# dotfiles

Managed by [Chezmoi](https://www.chezmoi.io/). Supports macOS and Linux (Arch/Ubuntu/Debian).

## Install

```bash
# Personal macOS
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=personal

# Work macOS
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=work

# Remote Linux server
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang --promptString machineType=remote
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
| Go | ✓ | ✓ | — |
| Rust (rustup) | ✓ | — | — |
| Node.js (fnm) | ✓ | ✓ | — |
| uv (via pipx) | ✓ | ✓ | — |
| tmux (gpakosz theme) | ✓ | ✓ | minimal |
| oh-my-zsh | ✓ | ✓ | ✓ |
| vim + plugins | ✓ | ✓ | ✓ |
| Git identity | age encrypted | age encrypted | age encrypted |

## Configuration

All options are derived from machine type, no interactive prompts except the age passphrase.

| Option | personal | work | remote | Source |
|--------|:---:|:---:|:---:|--------|
| `installGo` | true | true | false | auto |
| `installRust` | true | false | false | auto |
| `installNode` | true | true | false | auto |
| `installUv` | true | true | false | auto |
| Git name/email | — | — | — | `git-identity.json.age` |

To override tool flags after init, edit `~/.config/chezmoi/chezmoi.toml` and run `chezmoi apply`.

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
