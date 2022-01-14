.PHONY: install download update uninstall


ZSH_CONF_NAME=${USER}.zsh


install: download update

download:
	curl -Lo /tmp/install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
	sh /tmp/install.sh

update:
	zsh install.zsh
	ln -sf $(CURDIR)/custom.zsh ~/.oh-my-zsh/custom/${ZSH_CONF_NAME}

uninstall:
	echo y | uninstall_oh_my_zsh
