TARGETS=git vimrc

GIT=~/.gitconfig
VIMRC=~/.vimrc

all: $(TARGETS)

git: $(GIT)
vimrc: $(VIMRC)


$(GIT): git/gitconfig
	cp git/gitconfig ~/.gitconfig

$(VIMRC):
	make -C vimrc install

.PHONY:clean

clean:
	-rm $(TARGETS)
	make -C vimrc clean
