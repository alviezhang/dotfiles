TARGETS=git tmux zsh vim

GIT=~/.gitconfig
TMUX=~/.tmux.conf
ZSH=~/.oh-my-zsh
VIM=~/.vimrc ~/.vim

all: $(TARGETS)

git: $(GIT)
tmux: $(TMUX)
zsh: $(ZSH_CONF)
vim: $(VIM)

$(GIT): gitconfig
	cp gitconfig $(GIT)

$(TMUX): tmux.conf
	cp tmux.conf $(TMUX)

$(ZSH):
	git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
	cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
	cp alvie.zsh $(ZSH_CONF)

$(VIM): vimrc
	rm -rf ~/.vimrc ~/.vim
	mkdir ~/.vim
	cp vimrc ~/.vimrc
	git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	vim +PluginInstall +qall

.PHONY:clean

clean:
	-rm $(GIT) $(TMUX)
