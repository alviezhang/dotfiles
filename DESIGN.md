# Dotfiles 设计文档

## 问题陈述

1. **多机器配置无法差异化**：个人机、公司机、远程服务器需要不同的工具集和 secret，没有机制区分
2. **Secret 需手动处理**：git 用户名和邮箱需要手动创建 `~/.gitconfig.local`，容易遗漏
3. **包列表变更无法自动重跑**：新增一个 brew 包后，已有机器不会自动安装
4. **跨 OS 流程不统一**：macOS 和 Linux 的安装流程完全分开，难以维护

## 需要支持的场景

### 机器类型

| 机器类型 | 描述 |
|---------|------|
| **personal** | 个人 macOS 机器 |
| **work** | 工作 macOS 机器 |
| **remote** | Linux 服务器，无 GUI，只需基础 CLI 工具 |

### 操作系统

| OS | 包管理器 |
|----|---------|
| macOS | Homebrew（remote 不会是 macOS） |
| Ubuntu/Debian | apt |
| Arch Linux | pacman |

## 需要管理的内容

### 配置文件

| 配置 | 目标路径 | 差异化 |
|------|---------|--------|
| Git 配置 | `~/.gitconfig` | 首次提示输入用户名/邮箱，缓存到 chezmoi state |
| Vim 配置 | `~/.vimrc` | 无差异 |
| Tmux 配置 | `~/.tmux.conf.local` | 无差异 |
| Tmux 配置 | `~/.tmux.conf` | 非 remote：source gpakosz/.tmux 主题；remote：精简配置 |
| Zsh 配置 | `~/.zshrc` | chezmoi 完全接管；plugins 按 OS 自动选择 |
| Zsh 自定义 | `~/.oh-my-zsh/custom/` | proxy 配置、OS 特定设置 |
| Fontconfig | `~/.config/fontconfig/conf.d/` | 仅 Linux |

### 系统包

| 平台 | 格式 | 说明 |
|------|------|------|
| macOS | Brewfile（brew bundle） | formulas + casks，单文件 |
| Ubuntu/Debian | apt.list | 每行一个包名 |
| Arch Linux | pacman.list | 每行一个包名 |

包列表变更时自动重新安装（chezmoi `run_onchange_` + 内容 hash）。

### 语言工具

通过 `chezmoi init` 提示开关控制是否**自动安装**：

| 工具 | 安装方式 | 安装位置 |
|------|---------|---------|
| uv | pipx install | ~/.local/bin/ |
| Rust | rustup（curl） | ~/.rustup/ + ~/.cargo/bin/ |
| Node.js | fnm（curl） | ~/.local/share/fnm/ |
| Go | 随系统包安装（brew/apt/pacman） | 系统路径 |

**工具环境加载原则**：`.zshrc` 按运行时存在性检测加载（装了就用），不依赖 chezmoi 配置。即使选了不自动安装，手动装上后下次开 shell 也能自动生效。

### Secret 管理

使用 **age 加密 + 密码保护**：
- 加密后的私钥（`key.txt.age`）存在仓库中，用密码保护
- 新机器 `chezmoi init` 时输入密码解密私钥，之后自动解密所有加密文件
- 敏感文件通过 `chezmoi add --encrypt` 加入仓库
- git 用户名/邮箱通过 `promptStringOnce` 首次提示输入（非 secret，不需要加密）

一次性设置步骤：
```bash
chezmoi cd
chezmoi age-keygen | chezmoi age encrypt --passphrase --output=key.txt.age
# 记录输出的 public key (age1...)，填入 .chezmoi.toml.tmpl 的 recipient
```

## 关键约束

1. **幂等性**：多次运行结果一致，工具已安装则跳过
2. **包列表变更可追踪**：Brewfile / apt.list / pacman.list 变化时自动重跑安装
3. **无需 sudo 安装语言工具**：uv/fnm/rustup 均安装到用户目录
4. **单命令引导**：新机器只需 `make install`
5. **PATH 集中配置**：所有 PATH 设置在 `.zshrc` 一处完成，按工具存在性条件加载

## 不在范围内

- SSH 密钥管理（未来可扩展）
- 字体安装
- macOS 系统偏好设置（Defaults）
