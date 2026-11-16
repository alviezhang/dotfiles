#!/bin/bash
# 按 darwin/linux × personal/remote × 工具开关全开/全关渲染每个安装脚本，
# 检查渲染结果要么为空（被 chezmoi 跳过），要么以 #!/bin/bash 开头且通过 bash -n。
# 用法：tests/render-scripts.sh [REPO]
set -u
REPO="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
T=$(mktemp -d "${TMPDIR:-/tmp}/render.XXXXXX"); trap 'rm -rf "$T"' EXIT
# 隔离：chezmoi 优先读 XDG_CONFIG_HOME，残留的真实路径会让测试写到用户自己的配置
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME CHEZMOI_AGE_PASSWORD CARGO_HOME RUSTUP_HOME
export HOME="$T/home"; mkdir -p "$HOME"
fail=0
for os in darwin linux; do
  for mt in personal remote; do
    for tools in false true; do
      cfg="$T/cfg-$os-$mt-$tools.toml"
      printf '[data]\n  machineType = "%s"\n  personal = %s\n  work = false\n  remote = %s\n  installGo = %s\n  installRust = %s\n  installNode = %s\n  installPipx = %s\n' \
        "$mt" "$([ $mt = personal ] && echo true || echo false)" "$([ $mt = remote ] && echo true || echo false)" $tools $tools $tools $tools > "$cfg"
      for f in "$REPO"/.chezmoiscripts/*.tmpl; do
        name=$(basename "$f")
        { printf '{{- $os := "%s" -}}' "$os"; sed 's/\.chezmoi\.os/$os/g' "$f"; } > "$T/in.tmpl"
        out="$T/out-$os-$mt-$tools-$name.sh"
        if ! chezmoi --config "$cfg" --source "$REPO" execute-template < "$T/in.tmpl" > "$out" 2>"$T/err"; then
          echo "RENDER FAIL [$os/$mt/tools=$tools] $name: $(head -c 200 "$T/err")"; fail=1; continue
        fi
        if [ -z "$(tr -d '[:space:]' < "$out")" ]; then continue; fi
        first=$(head -n1 "$out")
        [ "$first" = "#!/bin/bash" ] || { echo "BAD SHEBANG [$os/$mt/tools=$tools] $name: first line=[$first]"; fail=1; }
        bash -n "$out" 2>"$T/err" || { echo "SYNTAX FAIL [$os/$mt/tools=$tools] $name: $(head -c 300 "$T/err")"; fail=1; }
      done
    done
  done
done
[ "$fail" -eq 0 ] && echo "ALL OK" || { echo "FAILURES"; exit 1; }
