ZSH_CONF_NAME=${USER}.zsh

install:
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	ln -sf $(CURDIR)/custom.zsh ~/.oh-my-zsh/custom/${ZSH_CONF_NAME}

uninstall:
	uninstall_oh_my_zsh
	rm ~/.oh-my-zsh/custom/${ZSH_CONF_NAME}
