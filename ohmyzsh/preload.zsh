#!/bin/zsh

_plugins=(git golang httpie)
os_plugins=()

# Platform specific configurations
UNAME=$(uname)

if [ "$UNAME" = "Linux" ]; then
    export OS=linux
    if [ -f /etc/os-release ]; then
        . /etc/os-release

        # 标准化为小写处理，避免大小写问题
        distro_id=${ID:l}
        distro_like=${ID_LIKE:l}

        # 判断 Arch 系系列
        if [[ "$distro_id" == "arch" || "$distro_id" == "endeavouros" || "$distro_like" == *"arch"* ]]; then
            os_plugins+=(archlinux)
        fi

        # 可以按需扩展支持更多发行版
        case "$distro_id" in
            ubuntu)
                os_plugins+=(ubuntu)
                ;;
            debian)
                os_plugins+=(debian)
                ;;
        esac
    fi
elif [ "$UNAME" = "Darwin" ]; then
    export OS=macOS
    os_plugins=(macos brew)
fi

plugins=(${_plugins} ${os_plugins})

# Debug
# echo "OS: $OS"
# echo "Detected plugins: ${plugins[@]}"