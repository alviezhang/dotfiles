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
- `CHEZMOI_INSTALL_GO`, `CHEZMOI_INSTALL_RUST`, `CHEZMOI_INSTALL_NODE`, `CHEZMOI_INSTALL_UV`:
  - set to `1` / `true` / `yes` / `on` to enable
  - set to `0` / `false` / `no` / `off` to disable
  - unset to follow `~/.config/chezmoi/chezmoi.toml`

For no-interactive init/apply, password lookup priority is:

1. `$CHEZMOI_AGE_PASSWORD`
2. `$HOME/.config/chezmoi/password` (recommended)
3. source dir `.password` (legacy; e.g. `~/.local/share/chezmoi/.password`)

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
| `installUv` | Python CLIs (pipx) | pipx (installed via Python) |

Rust uses XDG paths by default:
- `CARGO_HOME=$XDG_DATA_HOME/cargo`
- `RUSTUP_HOME=$XDG_DATA_HOME/rustup`

`.zshrc` auto-detects installed tools at runtime — manually installed tools also work.

## Global Packages

This repo manages "global" packages for each toolchain via list files under `packages/`:

- `packages/pipx.list` (includes `uv` by default)
- `packages/npm.list`
- `packages/cargo.list`

`pipx` is installed via Python (Linux: system `python3`, macOS: Homebrew `python3`).

After editing, run:

```bash
chezmoi apply
```

## Secrets

For no-interactive runs, password lookup priority is `$CHEZMOI_AGE_PASSWORD` > `$HOME/.config/chezmoi/password` > source dir `.password` (legacy). Current flow uses `expect`, no `rage` required.

无密码文件时 fallback 到手动输入密码。
如果误改了 `~/.config/chezmoi/key.txt`，执行 `chezmoi apply` 或 `chezmoi update` 会自动重新解密恢复。

```bash
# 编辑加密文件
scripts/edit-secret git-identity.toml.age

# 轮换密码（手动输入）
scripts/rotate-password

# 自动生成 A-Za-z0-9 密码（默认长度 32）
scripts/rotate-password --auto

# 写到指定文件（默认 ~/.config/chezmoi/password）
scripts/rotate-password --auto --password-file /path/to/password

# 兼容旧用法：同步到目录下的 .password
scripts/rotate-password --auto --password-dir /some/dir

# 可选：也写一份到 source dir .password（gitignored）
scripts/rotate-password --auto --write-source-password
```

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
