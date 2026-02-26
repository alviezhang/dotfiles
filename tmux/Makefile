install:
	[ -d .tmux ] || git clone https://github.com/gpakosz/.tmux.git
	ln -sf $(CURDIR)/.tmux/.tmux.conf ~
	ln -sf $(CURDIR)/tmux.conf.local ~/.tmux.conf.local

uninstall:
	-rm -rf .tmux ~/.tmux.conf*
