TARGETS=git vimrc tmux zsh python

GIT=~/.gitconfig
VIMRC=~/.vimrc
TMUX=~/.tmux.conf
ZSH=~/.oh-my-zsh
ZSH_CONF=~/.oh-my-zsh/custom/alvie.zsh
VIRTUALENV=~/.virtualenv/python2

all: $(TARGETS)

git: $(GIT)
vimrc: $(VIMRC)
tmux: $(TMUX)
zsh: $(ZSH_CONF)
python: $(VIRTUALENV)


$(GIT): git/gitconfig
	cp git/gitconfig $(GIT)

$(TMUX): tmux/tmux.conf
	cp tmux/tmux.conf $(TMUX)

$(VIMRC):
	cd vimrc
	git submodule init
	git submodule update
	make -C vimrc install

$(ZSH):
	git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
	cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

$(ZSH_CONF): $(ZSH) oh-my-zsh/alvie.zsh
	cp oh-my-zsh/alvie.zsh $(ZSH_CONF)

$(VIRTUALENV):
	mkdir -p ~/.virtualenv
	virtualenv ~/.virtualenv/python2

.PHONY:clean

clean:
	-rm $(GIT) $(TMUX)
	make -C vimrc clean
