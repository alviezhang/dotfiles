FONTCONFIG_DIR := $(HOME)/.config/fontconfig/conf.d

fontconfig:
	@mkdir -p "$(FONTCONFIG_DIR)"
	@for file in *.conf; do \
		if [ -f "$$file" ]; then \
			abs_file=$$(pwd)/$$file; \
			ln -sf "$$abs_file" "$(FONTCONFIG_DIR)/$$(basename "$$file")"; \
		fi; \
	done

clean:
	@if [ -d "$(FONTCONFIG_DIR)" ]; then \
		rm -rf "$(FONTCONFIG_DIR)"/*.conf; \
	fi

.PHONY: clean fontconfig
