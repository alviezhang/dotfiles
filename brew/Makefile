.PHONY: brew cask

install: brew cask

brew:
	echo "Install brew packages"
	grep -vE '^$|[#;]' packages.list | xargs brew install

cask:
	echo "Install brew cask packages"
	grep -vE '^$|[#;]' casks.list | xargs brew cask install

update:
	brew update
	brew upgrade
	brew cask upgrade

config:
	cp -r karabiner /Users/alvie/.config/karabiner

clean:
	brew cleanup --prune 1

uninstall:
	brew list | xargs brew uninstall
	brew cask list | xargs brew cask uninstall
