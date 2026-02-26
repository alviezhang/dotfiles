.PHONY: brew cask

install: brew cask

brew:
	echo "Install brew packages"
	grep -vE '^$|[#;]' packages.list | xargs brew install

cask:
	echo "Install brew cask packages"
	grep -vE '^$|[#;]' casks.list | xargs brew install --cask

update:
	brew update
	brew upgrade
	brew upgrade --cask

config:
	cp -r karabiner $(HOME)/.config/karabiner

clean:
	brew cleanup --prune 1

uninstall:
	brew list | xargs brew uninstall
	brew list --cask | xargs brew uninstall --cask
