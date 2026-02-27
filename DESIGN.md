# Dotfiles 设计文档

## 问题陈述

1. **多机器配置无法差异化**：个人机、公司机、远程服务器需要不同的工具集和 secret，没有机制区分
2. **Secret 需手动处理**：git 用户名和邮箱需要手动创建 `~/.gitconfig.local`，容易遗漏
3. **包列表变更无法自动重跑**：新增一个 brew 包后，已有机器不会自动安装
4. **跨 OS 流程不统一**：macOS 和 Linux 的安装流程完全分开，难以维护

## 两个正交维度

### 机器类型（控制行为差异）

| 机器类型 | 描述 |
|---------|------|
| **personal** | 个人机器（macOS 或 Linux） |
| **work** | 工作机器（macOS 或 Linux） |
| **remote** | 远程服务器（Linux），精简配置 |

### 操作系统（自动检测，控制包管理和平台配置）

| OS | 包管理器 |
|----|---------|
| macOS | Homebrew |
| Ubuntu/Debian | apt |
| Arch Linux | pacman |

机器类型和 OS 独立——personal/work 可以是 macOS 也可以是 Linux，系统包按 OS 自动安装。

## 需要管理的内容

### 配置文件

| 配置 | 目标路径 | 差异化 |
|------|---------|--------|
| Git 配置 | `~/.gitconfig` | 用户名/邮箱从 age 加密文件读取 |
| Vim 配置 | `~/.vimrc` | 无差异 |
| Tmux 配置 | `~/.tmux.conf` | 非 remote：symlink 到 `$XDG_DATA_HOME/tmux/gpakosz-tmux/.tmux.conf`；remote：精简配置 |
| Tmux 本地配置 | `~/.config/tmux/tmux.conf.local` | 非 remote 才部署（会创建 `~/.tmux.conf.local` symlink 兼容主题） |
| Zsh 配置 | `~/.zshrc` | chezmoi 完全接管；plugins 按 OS 自动选择 |
| Zsh 自定义 | `~/.oh-my-zsh/custom/` | proxy 配置、OS 特定设置 |
| Fontconfig | `~/.config/fontconfig/conf.d/` | 仅 Linux |

### 系统包

按 OS 自动检测，所有机器类型均安装：

| 平台 | 格式 | 说明 |
|------|------|------|
| macOS | Brewfile（brew bundle） | formulas + casks，单文件 |
| Ubuntu/Debian | apt.list | 每行一个包名 |
| Arch Linux | pacman.list | 每行一个包名 |

包列表变更时自动重新安装（chezmoi `run_onchange_` + 内容 hash）。

### 语言工具

默认不安装，通过 `--promptBool` 或编辑 `~/.config/chezmoi/chezmoi.toml` 启用：

| 工具 | 安装方式 | 安装位置 |
|------|---------|---------|
| Go | brew / apt / pacman | 系统路径 |
| uv | pipx install | ~/.local/bin/ |
| Rust | rustup（curl） | `$XDG_DATA_HOME/rustup` + `$XDG_DATA_HOME/cargo/bin` |
| Node.js | fnm（curl） | `$XDG_DATA_HOME/fnm` |

**工具环境加载原则**：`.zshrc` 按运行时存在性检测加载（装了就用），不依赖 chezmoi 配置。即使选了不自动安装，手动装上后下次开 shell 也能自动生效。

### Secret 管理

使用 **age 加密 + 密码保护**：
- 加密后的私钥（`key.txt.age`）存在仓库中，用密码保护
- 密码读取优先级：source 目录 `.password`（gitignored）> `~/.config/chezmoi/password`，配合 `expect + age` 实现非交互解密
- 无密码文件或 `expect` 时 fallback 到手动输入密码
- Git 用户名/邮箱存在 `git-identity.toml.age`，模板自动解密读取，无需 prompt
- 其他敏感文件通过 `chezmoi add --encrypt` 加入仓库
- 密码轮换：`scripts/rotate-password`（只影响 key.txt.age，其他 .age 文件用公钥加密，不受影响）

## 关键约束

1. **幂等性**：多次运行结果一致，工具已安装则跳过
2. **包列表变更可追踪**：Brewfile / apt.list / pacman.list 变化时自动重跑安装
3. **无需 sudo 安装语言工具**：uv/fnm/rustup 均安装到用户目录
4. **单命令引导**：新机器一行 curl 命令完成安装
5. **无交互 prompt**：除 age 密码外，所有配置通过命令行参数或配置文件指定
6. **PATH 集中配置**：所有 PATH 设置在 `.zshrc` 一处完成，按工具存在性条件加载

## 不在范围内

- SSH 密钥管理（未来可扩展）
- 字体安装
- macOS 系统偏好设置（Defaults）
