# 安装脚本公共前导，由 .chezmoiscripts 下的模板以 template "lib.sh" 引入。
# 每个脚本是独立进程且不读 .zshrc，这里补齐 bootstrap 过程中可能刚装好的工具路径。

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
FNM_DIR="${FNM_DIR:-$XDG_DATA_HOME/fnm}"
export XDG_DATA_HOME XDG_STATE_HOME CARGO_HOME RUSTUP_HOME FNM_DIR

path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

# 依次前插，越靠后优先级越高，与 .zshrc 一致：~/.local/bin > cargo > fnm > Homebrew
for _dir in /usr/local/bin /opt/homebrew/bin "$FNM_DIR" "$HOME/.cargo/bin" "$CARGO_HOME/bin" "$HOME/.local/bin"; do
  path_prepend "$_dir"
done
unset _dir
export PATH

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "error: root required for '$*', and sudo is not installed" >&2
    return 1
  fi
}

# 只走 HTTPS；先下载到临时文件再改名，网络中断不会留下半截文件。
# 自行重试：TLS 握手被重置这类错误不在 curl --retry 的范围内
fetch() {
  local part="$2.part.$$" attempt
  for attempt in 1 2 3; do
    if curl --proto '=https' --tlsv1.2 -fsSL --connect-timeout 20 "$1" -o "$part"; then
      mv -f "$part" "$2"
      return 0
    fi
    [ "$attempt" -lt 3 ] && sleep $((attempt * 2))
  done
  rm -f "$part"
  echo "error: download failed after 3 attempts: $1" >&2
  return 1
}

# 输出清单条目：去掉首尾空白，跳过空行和以 # 或 ; 开头的行
list_items() {
  [ -f "$1" ] || { echo "error: list not found: $1" >&2; return 1; }
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    case "$line" in
      ""|\#*|\;*) continue ;;
    esac
    printf '%s\n' "$line"
  done < "$1"
}

# 定位 rustup 管理的工具链：优先 XDG 路径，兼容 ~/.cargo + ~/.rustup 的旧安装
use_rustup_home() {
  if [ -x "$CARGO_HOME/bin/rustup" ] && [ -d "$RUSTUP_HOME" ]; then
    :
  elif [ -x "$HOME/.cargo/bin/rustup" ] && [ -d "$HOME/.rustup" ]; then
    CARGO_HOME="$HOME/.cargo"
    RUSTUP_HOME="$HOME/.rustup"
  else
    return 1
  fi
  "$CARGO_HOME/bin/rustup" show active-toolchain >/dev/null 2>&1
}
