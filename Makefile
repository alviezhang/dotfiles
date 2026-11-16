.PHONY: install apply update clean test

CHEZMOI := $(HOME)/.local/bin/chezmoi

# 安装 chezmoi（真实二进制，安装到 ~/.local/bin/）并首次应用
install: $(CHEZMOI)
	$(CHEZMOI) init --source="$(CURDIR)" --apply

$(CHEZMOI):
	@echo "Installing chezmoi to $(HOME)/.local/bin/..."
	sh -c "$$(curl --proto '=https' --tlsv1.2 -fsLS https://get.chezmoi.io)" -- -b "$(HOME)/.local/bin"

# 后续更新：重新应用所有 dotfiles
apply:
	$(CHEZMOI) apply --source="$(CURDIR)"

# 同步仓库变更并重新应用
update:
	git pull
	$(CHEZMOI) apply --source="$(CURDIR)"

# 清理 repo 内的本地杂项（不会影响已应用到 ~ 的配置）
clean:
	rm -rf .tmux .worktrees
	find . -name .DS_Store -delete || true

# 隔离 HOME 中的本地测试：密钥链路、端到端 apply、模板渲染、口令轮换
test:
	@set -e; for t in tests/*.sh; do echo "== $$t"; "$$t"; done
