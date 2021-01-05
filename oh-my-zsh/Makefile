ZSH_CONF_NAME=${USER}.zsh

install: download update git-prune

download:
	curl -Lo /tmp/install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
	sh /tmp/install.sh

update:
	zsh install.zsh
	ln -sf $(CURDIR)/custom.zsh ~/.oh-my-zsh/custom/${ZSH_CONF_NAME}

git-prune:
	git clone https://github.com/diazod/git-prune.git ~/.oh-my-zsh/plugins/git-prune

uninstall:
	uninstall_oh_my_zsh
	rm ~/.oh-my-zsh/custom/${ZSH_CONF_NAME}
