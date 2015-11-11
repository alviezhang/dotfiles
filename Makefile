TARGETS=git tmux zsh

GIT=~/.gitconfig
TMUX=~/.tmux.conf
ZSH=~/.oh-my-zsh
ZSH_CONF=~/.oh-my-zsh/custom/alvie.zsh

all: $(TARGETS)

git: $(GIT)
tmux: $(TMUX)
zsh: $(ZSH_CONF)

$(GIT): gitconfig
	cp gitconfig $(GIT)

$(TMUX): tmux.conf
	cp tmux.conf $(TMUX)

$(ZSH):
	git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
	cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

$(ZSH_CONF): $(ZSH) alvie.zsh
	cp alvie.zsh $(ZSH_CONF)

.PHONY:clean

clean:
	-rm $(GIT) $(TMUX)
