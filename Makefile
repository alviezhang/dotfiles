
ZSH_CONF_NAME=${USER}.zsh

GIT=~/.gitconfig
TMUX=~/.tmux.conf.local
ZSH=~/.oh-my-zsh
ZSH_CONF=~/.oh-my-zsh/custom/${ZSH_CONF_NAME}
VIM=~/.vimrc ~/.vim


git: $(GIT)
tmux: $(TMUX)
zsh: $(ZSH) $(ZSH_CONF)
vim: $(VIM)


$(GIT): gitconfig
	cp gitconfig $(GIT)

$(TMUX):
	rm -rf .tmux
	git clone https://github.com/gpakosz/.tmux.git
	ln -sf $(CURDIR)/.tmux/.tmux.conf ~
	ln -sf $(CURDIR)/tmux.conf $(TMUX)

$(ZSH):
	git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
	cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

$(ZSH_CONF): custom.zsh
	cp custom.zsh $(ZSH_CONF)

$(VIM): vimrc
	rm -rf ~/.vimrc ~/.vim
	mkdir ~/.vim
	cp vimrc ~/.vimrc
	git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	vim +PluginInstall +qall

.PHONY: clean

clean:
	-rm $(GIT)
	-rm -rf .tmux ~/.tmux.conf*
