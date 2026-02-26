.PHONY: install apply update

CHEZMOI := $(HOME)/.local/bin/chezmoi

# 安装 chezmoi（真实二进制，安装到 ~/.local/bin/）并首次应用
install: $(CHEZMOI)
	$(CHEZMOI) init --source="$(CURDIR)" --apply

$(CHEZMOI):
	@echo "Installing chezmoi to $(HOME)/.local/bin/..."
	sh -c "$$(curl -fsLS get.chezmoi.io)" -- -b "$(HOME)/.local/bin"

# 后续更新：重新应用所有 dotfiles
apply:
	$(CHEZMOI) apply --source="$(CURDIR)"

# 同步仓库变更并重新应用
update:
	git pull
	$(CHEZMOI) apply --source="$(CURDIR)"
