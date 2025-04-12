.PHONY: install download update uninstall repatch clean

ZSH_CUSTOM_DIR := $(HOME)/.oh-my-zsh/custom
ZSH_CONF_NAME := main.zsh  # 软链目标
PRELOAD_FILE := $(PWD)/preload.zsh

install: download update

download:
	curl -Lo /tmp/install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
	RUNZSH=no sh /tmp/install.sh

update: install.zsh
	zsh install.zsh
	echo $(PWD)/main.zsh $(ZSH_CUSTOM_DIR)/$(ZSH_CONF_NAME)
	ln -sf $(PWD)/main.zsh $(ZSH_CUSTOM_DIR)/$(ZSH_CONF_NAME)

uninstall:
	sed -i '' '/# >>> custom preload <<</,/# <<< custom preload >>>/d' ~/.zshrc || true
	rm -f $(ZSH_CUSTOM_DIR)/$(ZSH_CONF_NAME)
	echo "[✓] Uninstalled custom preload and config"

repatch: uninstall update

clean:
	rm -f /tmp/install.sh
