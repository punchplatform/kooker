CC=gcc
CFLAGS=

all: install-realpath

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

realpath: realpath.o  ## Build the executable realpath
	$(CC) -o $@ $^ $(CFLAGS)

install-realpath: realpath ## Copy the realpath executable to the /usr/local/bin directory
	cp $(PWD)/realpath /usr/local/bin/realpath

clean: ## Remove object files
	rm -rf *.o

fclean: clean ## Remove object files, executable and uninstall realpath
	rm -f /usr/local/bin/realpath
	rm -f realpath

help:
	@-$(HELPER)
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m\n"} /^[0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)