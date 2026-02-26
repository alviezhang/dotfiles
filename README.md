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

For no-interactive init/apply, configure `.password` first:

```bash
mkdir -p ~/.local/share/chezmoi
echo -n "your-passphrase" > ~/.local/share/chezmoi/.password
chmod 600 ~/.local/share/chezmoi/.password
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

`.zshrc` auto-detects installed tools at runtime — manually installed tools also work.

## Secrets

For no-interactive runs, prepare `.password` first (gitignored). Current flow uses `expect`, no `rage` required.

无 `.password` 时 fallback 到手动输入密码。

```bash
# 编辑加密文件
scripts/edit-secret git-identity.toml.age

# 轮换密码（手动输入）
scripts/rotate-password

# 自动生成 A-Za-z0-9 密码（默认长度 32）
scripts/rotate-password --auto

# 同步 .password 到指定目录
scripts/rotate-password --auto --password-dir ~/.local/share/chezmoi
```

See [DESIGN.md](DESIGN.md) for requirements and design decisions.
