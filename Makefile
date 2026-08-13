PREFIX  ?= /usr/local
DESTDIR ?=
BIN_DIR = $(DESTDIR)$(PREFIX)/bin

.PHONY: test check install uninstall

test:
	prove -Ibin/lib -r tests

check: test

install:
	mkdir -p $(BIN_DIR)
	rm -rf $(BIN_DIR)/lib
	cp -p bin/tgph-* bin/pubtgph bin/yt2tg* $(BIN_DIR)/
	cp -rp bin/lib $(BIN_DIR)/

uninstall:
	rm -f $(BIN_DIR)/tgph-* $(BIN_DIR)/pubtgph $(BIN_DIR)/yt2tg*
	rm -rf $(BIN_DIR)/lib
