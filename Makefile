TARGETS=git vimrc tmux

GIT=~/.gitconfig
VIMRC=~/.vimrc
TMUX=~/.tmux.conf

all: $(TARGETS)

git: $(GIT)
vimrc: $(VIMRC)
tmux: $(TMUX)


$(GIT): git/gitconfig
	cp git/gitconfig $(GIT)

$(TMUX): tmux/tmux.conf
	cp tmux/tmux.conf $(TMUX)

$(VIMRC):
	cd vimrc
	git submodule init
	git submodule update
	make -C vimrc install

.PHONY:clean

clean:
	-rm $(GIT) $(TMUX)
	make -C vimrc clean
