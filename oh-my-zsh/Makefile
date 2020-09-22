ZSH_CONF_NAME=${USER}.zsh

install:
	curl -Lo /tmp/install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
	sh /tmp/install.sh
	zsh install.zsh
	ln -sf $(CURDIR)/custom.zsh ~/.oh-my-zsh/custom/${ZSH_CONF_NAME}

uninstall:
	uninstall_oh_my_zsh
	rm ~/.oh-my-zsh/custom/${ZSH_CONF_NAME}
