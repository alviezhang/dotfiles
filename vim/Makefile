install:
	mkdir -p ~/.vim/bundle
	ln -sf $(CURDIR)/vimrc ~/.vimrc
	[ -d ~/.vim/bundle/Vundle.vim ] || git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	vim +PluginInstall +qall

uninstall:
	-rm ~/.vimrc
	-rm -rf ~/.vim
