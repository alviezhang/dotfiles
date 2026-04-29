# 密码管理重设计

**日期**：2026-04-29
**状态**：草稿（已 codex review，已采纳大部分反馈，待用户最终确认）

## 问题陈述

当前 age 私钥（`key.txt.age`）的密码处理有 4 个问题：

1. **状态污染**：`~/.config/chezmoi/password` 和 chezmoi 自动管理的状态文件（`chezmoi.toml`、`key.txt`）共目录，把用户手管的 secret 和工具自动生成的状态混在一起，所有权语义不清。
2. **Lookup 链过长**：三层文件 fallback（`~/.config/chezmoi/password` → `$SOURCE_DIR/.password` → 交互式）多于必要。其中 source-dir `.password` 位于 git working tree，仅靠 `.gitignore` 保护，较脆弱。
3. **macOS 上没 Keychain 集成**：密码只能明文存盘。macOS 用户错过了 native credential store 和潜在的 iCloud Keychain 跨机 sync。
4. **每台机器手动 provision**：新机器必须先手动创建 / 拷贝密码文件，chezmoi 才能解密任何东西。`~/.config/` 默认不被 Dropbox 或任何 sync 机制覆盖。

## 设计决定

| | |
|---|---|
| 砍掉 `~/.config/chezmoi/password` | 是 |
| 砍掉 `$SOURCE_DIR/.password` | 是 |
| 新文件路径 | `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/passphrase` |
| macOS Keychain 后端 | 加 |
| Linux secret-tool 后端 | 不加（用户 Linux 机器是 headless server，无 desktop session） |
| Bitwarden / 外部密码管理器 | 不加（保持依赖最小） |
| 自动迁移脚本 | 不加（一次性手动步骤可接受） |
| 交互输入后自动存 Keychain | 不加（保持解密脚本边界纯净；用户首次输完显式跑 `rotate-password`） |

## Lookup 链（新）

```
$CHEZMOI_AGE_PASSWORD          # env 覆盖（仅 CI/ephemeral 场景推荐）
  → macOS Keychain             # darwin only
  → ~/.config/dotfiles/passphrase
  → 交互式输入
```

### Fall-through 规则

每层 lookup 必须区分这几种情况：

| 状态 | 行为 |
|---|---|
| **源未找到** | env unset / Keychain 无 entry / 文件不存在 → 安静跳到下一层 |
| **源找到但内容为空** | `security -w` 返回空串、文件为 0 字节 → 视为未找到 + warning，跳下一层 |
| **源访问失败** | `security` 非零退出（Keychain 锁定 / CLI 无权限） → warning，跳下一层 |
| **源读到密码，但 age 解密失败** | 密码错 → **报错退出**，不静默 fallthrough（否则一直走到交互式，混淆"密码错"和"没设密码"） |

### 安全注意

- **`CHEZMOI_AGE_PASSWORD` 在 same-user 进程间可见**（`ps`、`/proc/<pid>/environ` 或 macOS 等价机制）。仅推荐用于 CI / ephemeral / 一次性场景，**不作为稳态存储**。
- **文件 fallback 读取前必须 stat 检查权限**：非 `0600` 拒读 + warning，跳下一层。

## 文件路径：`~/.config/dotfiles/passphrase`

- 标准 XDG 布局：`${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/passphrase`
- `dotfiles` 命名空间独立，与 `~/.config/chezmoi/`（工具自身状态）平级、与工具名解耦
- 权限：目录 `0700`、文件 `0600`，owner only

## macOS Keychain

- **Service**: `dotfiles-passphrase`
- **Account**: `$USER`（单用户假设；若将来需要 isolate 多 profile 再加显式 account 区分）

| 操作 | 命令 |
|---|---|
| 读 | `security find-generic-password -s dotfiles-passphrase -a "$USER" -w` |
| 写 | `security add-generic-password -s dotfiles-passphrase -a "$USER" -w "$PW" -U` |

`-U` 让 entry 已存在时更新。

iCloud Keychain 是否同步这条 generic-password 取决于具体 keychain 配置和 macOS 版本——**并非保证**。下面"验收标准"按悲观假设描述实际收益。

## 涉及修改的文件

| 文件 | 改动 |
|---|---|
| `.chezmoiscripts/run_before_00-decrypt-private-key.sh.tmpl` | 替换 lookup 链（env → keychain → 新文件 → 交互式），按 fall-through 规则处理 empty / error / decrypt-fail；砍掉旧路径；文件读前 stat 检查 `0600` |
| `scripts/rotate-password` | macOS 默认写 Keychain（不再写文件）；Linux 默认写 `~/.config/dotfiles/passphrase`；新增 `--file [PATH]` 覆盖；砍掉 `--password-dir`、`--write-source-password` |
| `README.md` | 更新 "Secrets" 段：lookup 顺序、Keychain 说明、新文件路径、迁移与恢复步骤、env var 安全注释 |
| `DESIGN.md` | 更新 "Secret 管理" 段同步 |
| `.gitignore` 与 `.chezmoiignore.tmpl` | 保留 `.password` 忽略（防御，避免未来误用） |

## 迁移（一次性，用户驱动）

正常路径：

```bash
# 1. 写密码到新位置（macOS → Keychain，Linux → ~/.config/dotfiles/passphrase）
scripts/rotate-password

# 2. 清理旧路径
rm -f ~/.config/chezmoi/password
rm -f "$(chezmoi source-path)/.password"   # 如果存在
```

`run_before_00` 不再读旧路径，所以保留也无害——但建议清理。

## 恢复（broken state）

如果机器进入 **`key.txt` 丢失 + Keychain 没有/错误 + 旧 password 文件已删** 的状态，`scripts/rotate-password` 救不了（它要求 `key.txt` 已存在才能重新加密）。手动恢复：

```bash
# 1. 用密码（脑子里记得 / 从其他机器 / 1Password 等找回）
#    交互式解密 key.txt.age 到 chezmoi 期望位置
SOURCE_DIR="$(chezmoi source-path)"
mkdir -p ~/.config/chezmoi
age -d "$SOURCE_DIR/key.txt.age" > ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
# 上一步会提示输入密码

# 2. 把密码存到新的稳态位置
# macOS:
security add-generic-password -s dotfiles-passphrase -a "$USER" -w "<密码>" -U
# Linux:
mkdir -p ~/.config/dotfiles && chmod 700 ~/.config/dotfiles
umask 077 && printf '%s' '<密码>' > ~/.config/dotfiles/passphrase

# 3. 验证
chezmoi diff
```

## 不在范围内

- **Bitwarden CLI 后端**：可作为额外 lookup 步骤加入。这次不做——引入 `bw login`/unlock UX 成本，Linux 手动 provision 摩擦还不够痛。
- **Linux secret-tool / libsecret**：用户 Linux 机器是 headless server，无 desktop session。
- **自动迁移**：可写 `run_once_*-migrate-password.sh.tmpl` 检测旧路径自动搬。一次性事件用 `rotate-password` 显式更清楚。
- **交互输入后自动 store Keychain**：让 `run_before_00` 在用户首次输密码后顺便 store。UX 更顺，但偏离"解密脚本只解密"的边界。用户首次输完后**显式**跑 `scripts/rotate-password`。

## 验收标准

实现后：

- **新 macOS 机器**：
  - 最佳情况（iCloud Keychain 已同步该 entry）→ `chezmoi init` 零交互
  - 常见情况（未同步）→ 首次 init 走交互输入；之后跑 `scripts/rotate-password` 显式存进本机 Keychain；后续这台 Mac 自动检索
  - 相比现状（必须先 provision 密码文件）的实质改进：**从"先准备文件再 init"变为"边 init 边输 + 一次 rotate-password 存档"**
- **新 Linux remote**：`chezmoi init` 需要 `CHEZMOI_AGE_PASSWORD` env var，或预先放好 `~/.config/dotfiles/passphrase` 文件
- **现有机器迁移后**：chezmoi 命令照常工作；旧路径文件删除不影响
- **`~/.config/chezmoi/`** 只保留 chezmoi 自动管理的状态，不再有用户 provision 的密码
- **broken state** 有明确的手动恢复路径（见上）

## 测试要点（手动）

macOS 上：

1. **全新 init**：删除 `~/.config/chezmoi/key.txt` 和 Keychain entry，跑 `chezmoi apply` → 应交互式询问密码 → 输入后 `key.txt` 重生成
2. **Keychain 写入**：`scripts/rotate-password` → `security find-generic-password -s dotfiles-passphrase -a "$USER" -w` 返回新密码
3. **Keychain 读取**：删 `~/.config/chezmoi/key.txt`，跑 `chezmoi apply` → 静默成功
4. **env 覆盖 + 密码错**：`CHEZMOI_AGE_PASSWORD=wrong chezmoi apply` → **报解密失败**（验证 env 优先级 + "密码错则报错"规则）
5. **旧路径忽略**：写一个错的 `~/.config/chezmoi/password`，删 `key.txt`，跑 `chezmoi apply` → 应走 Keychain 成功（证明旧路径不再读）
6. **Keychain 锁定**：`security lock-keychain login.keychain` 后跑 `chezmoi apply` → warning + fallthrough 到文件 / 交互
7. **空 Keychain entry**：`security add-generic-password -s dotfiles-passphrase -a "$USER" -w "" -U` 后跑 → warning + fallthrough
8. **文件权限非 0600**：`chmod 644 ~/.config/dotfiles/passphrase` 后跑 → warning + fallthrough
9. **恢复路径**：手动制造 broken state（删 `key.txt`、`security delete-generic-password`），按"恢复"段恢复

Linux 上类似流程，跳过 Keychain，验证文件路径生效。
