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
CHEZMOI_INSTALL_UV=1 \
bash -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
  init --apply alviezhang
```

- `CHEZMOI_MACHINE_TYPE`: `personal` / `work` / `remote`
- `CHEZMOI_INSTALL_GO`, `CHEZMOI_INSTALL_RUST`, `CHEZMOI_INSTALL_NODE`, `CHEZMOI_INSTALL_UV`: set to non-empty value (e.g. `1`) to enable

For no-interactive init/apply, password lookup priority is:

1. source dir `.password` (default source: `~/.local/share/chezmoi/.password`)
2. `$HOME/.config/chezmoi/password`

You can configure the fallback file first:

```bash
mkdir -p ~/.config/chezmoi
echo -n "your-passphrase" > ~/.config/chezmoi/password
chmod 600 ~/.config/chezmoi/password
```

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
  installUv   = true
```

```bash
chezmoi apply
```

## Update

```bash
chezmoi update
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
| `installUv` | uv | pipx |

Rust uses XDG paths by default:
- `CARGO_HOME=$XDG_DATA_HOME/cargo`
- `RUSTUP_HOME=$XDG_DATA_HOME/rustup`

`.zshrc` auto-detects installed tools at runtime — manually installed tools also work.

## Secrets

For no-interactive runs, password lookup priority is source dir `.password` first, then `$HOME/.config/chezmoi/password`. Current flow uses `expect`, no `rage` required.

无 `.password` 时 fallback 到手动输入密码。
如果误改了 `~/.config/chezmoi/key.txt`，执行 `chezmoi apply` 或 `chezmoi update` 会自动重新解密恢复。

```bash
# 编辑加密文件
scripts/edit-secret git-identity.toml.age

# 轮换密码（手动输入）
scripts/rotate-password

# 自动生成 A-Za-z0-9 密码（默认长度 32）
scripts/rotate-password --auto

# 同步密码到指定文件（默认 ~/.config/chezmoi/password）
scripts/rotate-password --auto --password-file ~/.config/chezmoi/password
```

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
