install:
	grep -vE '^$|[#;]' packages.list | xargs brew install
	grep -vE '^$|[#;]' casks.list | xargs brew cask install

update:
	brew update
	brew upgrade
	brew cask upgrade

config:
	cp -r karabiner /Users/alvie/.config/karabiner

clean:
	brew clean

uninstall:
	brew list | xargs brew uninstall
	brew cask list | xargs brew cask uninstall
