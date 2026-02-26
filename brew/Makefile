.PHONY: install brew pipx update clean uninstall

install: brew pipx

brew:
	brew bundle install

pipx:
	grep -vE '^$$|[#;]' pipx.list | xargs -I{} pipx install {}

update:
	brew bundle install
	brew upgrade
	brew upgrade --cask
	pipx upgrade-all

clean:
	brew cleanup --prune 1

uninstall:
	brew list --formula | xargs brew uninstall
	brew list --cask | xargs brew uninstall --cask
