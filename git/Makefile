install:
	ln -sf $(CURDIR)/gitconfig ~/.gitconfig
	@[ -f ~/.gitconfig.local ] || (echo "⚠️  请创建 ~/.gitconfig.local 并填写 [user] 信息：\n  [user]\n    name = Your Name\n    email = you@example.com")

uninstall:
	rm ~/.gitconfig
