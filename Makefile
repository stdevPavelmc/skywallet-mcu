.DEFAULT_GOAL := help
.PHONY: clean-lib clean
.PHONY: build-deps firmware-deps bootloader bootloader-mem-protect
.PHONY: firmware sign full-firmware-mem-protect full-firmware
.PHONY: emulator run-emulator st-flash
.PHONY: bootloader-clean bootloader-release bootloader-release-mem-protect
.PHONY: firmware-clean firmware-release
.PHONY: combined-release combined-release-mem-protect

UNAME_S ?= $(shell uname -s)

PYTHON   ?= /usr/bin/python
PIP      ?= pip
PIPARGS  ?=

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))

VERSION_FIRMWARE         ?= $(shell cat tiny-firmware/VERSION)
VERSION_FIRMWARE_MAJOR   ?= $(shell cat tiny-firmware/VERSION | cut -d. -f1)
VERSION_FIRMWARE_MINOR   ?= $(shell cat tiny-firmware/VERSION | cut -d. -f2)
VERSION_FIRMWARE_PATCH   ?= $(shell cat tiny-firmware/VERSION | cut -d. -f3)
VERSION_BOOTLOADER       ?= $(shell cat tiny-firmware/bootloader/VERSION)
VERSION_BOOTLOADER_MAJOR ?= $(shell cat tiny-firmware/bootloader/VERSION | cut -d. -f1)
VERSION_BOOTLOADER_MINOR ?= $(shell cat tiny-firmware/bootloader/VERSION | cut -d. -f2)
VERSION_BOOTLOADER_PATCH ?= $(shell cat tiny-firmware/bootloader/VERSION | cut -d. -f3)

ifeq ($(UNAME_S), Darwin)
	LD_VAR=DYLD_LIBRARY_PATH
else
	LD_VAR=LD_LIBRARY_PATH
endif

install-linters-Darwin:
	brew install yamllint

install-linters-Linux:
	$(PIP) install $(PIPARGS) yamllint

install-linters: install-linters-$(UNAME_S) ## Install code quality checking tools

lint: ## Check code quality
	yamllint -d relaxed .travis.yml

clean-lib: ## Delete all files generated by tiny-firmware library dependencies
	make -C tiny-firmware/vendor/libopencm3/ clean

clean: ## Delete all files generated by build
	make -C skycoin-api/ clean
	make -C tiny-firmware/bootloader/ clean
	make -C tiny-firmware/ clean
	make -C tiny-firmware/emulator/ clean
	make -C tiny-firmware/protob/ clean-c
	rm -f emulator.img emulator
	rm -f tiny-firmware/bootloader/combine/bl.bin
	rm -f tiny-firmware/bootloader/combine/fw.bin
	rm -f tiny-firmware/bootloader/combine/combined.bin
	rm -f tiny-firmware/bootloader/libskycoin-crypto.so
	rm -f bootloader-memory-protected.bin  bootloader-no-memory-protect.bin  full-firmware-no-mem-protect.bin full-firmware-memory-protected.bin
	# FIXME: Remove .d files
	rm -f $$(find . -type f -name '*.d')

build-deps: ## Build common dependencies (protob)
	make -C tiny-firmware/protob/ build-c

firmware-deps: build-deps ## Build firmware dependencies
	make -C tiny-firmware/vendor/libopencm3/

generate-bitmaps:
	( cd tiny-firmware/gen/bitmaps/ && python2 generate.py )

bootloader: firmware-deps ## Build bootloader (RDP level 0)
	rm -f tiny-firmware/memory.o tiny-firmware/gen/bitmaps.o # Force rebuild of these two files
	MEMORY_PROTECT=0 SIGNATURE_PROTECT=1 REVERSE_BUTTONS=1 make -C tiny-firmware/bootloader/ align
	mv tiny-firmware/bootloader/bootloader.bin bootloader-no-memory-protect.bin

bootloader-mem-protect: firmware-deps ## Build bootloader (RDP level 2)
	rm -f tiny-firmware/memory.o tiny-firmware/gen/bitmaps.o # Force rebuild of these two files
	MEMORY_PROTECT=1 SIGNATURE_PROTECT=1 REVERSE_BUTTONS=1 make -C tiny-firmware/bootloader/ align
	mv tiny-firmware/bootloader/bootloader.bin bootloader-memory-protected.bin

firmware: tiny-firmware/skycoin.bin ## Build wallet firmware

build-libc: tiny-firmware/bootloader/libskycoin-crypto.so ## Build the Skycoin cipher library for firmware

bootloader-clean:
	make -C tiny-firmware/bootloader/ clean

bootloader-release:
	if [ -z "$(shell echo $(VERSION_BOOTLOADER) | egrep '^[0-9]+\.[0-9]+\.[0-9]+$$' )" ]; then echo "Wrong firmware version format"; exit 1; fi
	VERSION_MAJOR=$(VERSION_FIRMWARE_MAJOR) VERSION_MINOR=$(VERSION_FIRMWARE_MINOR) VERSION_PATCH=$(VERSION_FIRMWARE_PATCH) make -C . bootloader ; \
	mv bootloader-no-memory-protect.bin bootloader-$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH)-no-memory-protect.bin

bootloader-release-mem-protect:
	if [ -z "$(shell echo $(VERSION_BOOTLOADER) | egrep '^[0-9]+\.[0-9]+\.[0-9]+$$' )" ]; then echo "Wrong firmware version format"; exit 1; fi
	VERSION_MAJOR=$(VERSION_BOOTLOADER_MAJOR) VERSION_MINOR=$(VERSION_BOOTLOADER_MINOR) VERSION_PATCH=$(VERSION_BOOTLOADER_PATCH) make -C . bootloader-mem-protect ; \
	mv bootloader-memory-protected.bin bootloader-$(VERSION_BOOTLOADER_MAJOR).$(VERSION_BOOTLOADER_MINOR).$(VERSION_BOOTLOADER_PATCH)-mem-protect.bin


firmware-clean:
	make -C tiny-firmware/ clean

firmware-release:
	if [ -z "$(shell echo $(VERSION_FIRMWARE) | egrep '^[0-9]+\.[0-9]+\.[0-9]+$$' )" ]; then echo "Wrong firmware version format"; exit 1; fi
	VERSION_MAJOR=$(VERSION_FIRMWARE_MAJOR) VERSION_MINOR=$(VERSION_FIRMWARE_MINOR) VERSION_PATCH=$(VERSION_FIRMWARE_PATCH) make -C . firmware ; \
	mv tiny-firmware/skycoin.bin skycoin-$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH).bin

combined-release:
	if [ -z "$(shell echo $(VERSION_BOOTLOADER) | egrep '^[0-9]+\.[0-9]+\.[0-9]+$$' )" ]; then echo "Wrong firmware version format"; exit 1; fi ; \
	make bootloader-release VERSION_BOOTLOADER=$(VERSION_BOOTLOADER_MAJOR).$(VERSION_BOOTLOADER_MINOR).$(VERSION_BOOTLOADER_PATCH) ; \
	cp bootloader-$(VERSION_BOOTLOADER_MAJOR).$(VERSION_BOOTLOADER_MINOR).$(VERSION_BOOTLOADER_PATCH)-no-memory-protect.bin tiny-firmware/bootloader/combine/bl.bin
	if [ -z "$(shell echo $(VERSION_FIRMWARE) | egrep '^[0-9]+\.[0-9]+\.[0-9]+$$' )" ]; then echo "Wrong firmware version format"; exit 1; fi ; \
	make firmware-release VERSION_FIRMWARE=$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH); \
	cp skycoin-$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH).bin tiny-firmware/bootloader/combine/fw.bin
	cd tiny-firmware/bootloader/combine/ ; $(PYTHON) prepare.py
	mv tiny-firmware/bootloader/combine/combined.bin bootloader-$(VERSION_BOOTLOADER_MAJOR).$(VERSION_BOOTLOADER_MINOR).$(VERSION_BOOTLOADER_PATCH)-firmware-$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH)-no-memory-protect.bin

combined-release-mem-protect:
	if [ -z "$(shell echo $(VERSION_BOOTLOADER) | egrep '^[0-9]+\.[0-9]+\.[0-9]+$$' )" ]; then echo "Wrong firmware version format"; exit 1; fi ; \
	make bootloader-release-mem-protect VERSION_BOOTLOADER=$(VERSION_BOOTLOADER_MAJOR).$(VERSION_BOOTLOADER_MINOR).$(VERSION_BOOTLOADER_PATCH) ; \
	cp bootloader-$(VERSION_BOOTLOADER_MAJOR).$(VERSION_BOOTLOADER_MINOR).$(VERSION_BOOTLOADER_PATCH)-mem-protect.bin tiny-firmware/bootloader/combine/bl.bin
	if [ -z "$(shell echo $(VERSION_FIRMWARE) | egrep '^[0-9]+\.[0-9]+\.[0-9]+$$' )" ]; then echo "Wrong firmware version format"; exit 1; fi ; \
	make firmware-release VERSION_FIRMWARE=$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH); \
	cp skycoin-$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH).bin tiny-firmware/bootloader/combine/fw.bin
	cd tiny-firmware/bootloader/combine/ ; $(PYTHON) prepare.py
	mv tiny-firmware/bootloader/combine/combined.bin bootloader-$(VERSION_BOOTLOADER_MAJOR).$(VERSION_BOOTLOADER_MINOR).$(VERSION_BOOTLOADER_PATCH)-firmware-$(VERSION_FIRMWARE_MAJOR).$(VERSION_FIRMWARE_MINOR).$(VERSION_FIRMWARE_PATCH)-mem-protect.bin


tiny-firmware/bootloader/libskycoin-crypto.so:
	make -C skycoin-api clean
	make -C skycoin-api libskycoin-crypto.so
	cp skycoin-api/libskycoin-crypto.so tiny-firmware/bootloader/
	make -C skycoin-api clean

tiny-firmware/skycoin.bin: firmware-deps
	rm -f tiny-firmware/memory.o tiny-firmware/gen/bitmaps.o # Force rebuild of these two files
	REVERSE_BUTTONS=1 make -C tiny-firmware/ sign

sign: tiny-firmware/bootloader/libskycoin-crypto.so tiny-firmware/skycoin.bin ## Sign wallet firmware
	tiny-firmware/bootloader/firmware_sign.py -s -f tiny-firmware/skycoin.bin

full-firmware-mem-protect: bootloader-mem-protect firmware ## Build full firmware (RDP level 2)
	cp bootloader-memory-protected.bin tiny-firmware/bootloader/combine/bl.bin
	cp tiny-firmware/skycoin.bin tiny-firmware/bootloader/combine/fw.bin
	cd tiny-firmware/bootloader/combine/ ; $(PYTHON) prepare.py
	mv tiny-firmware/bootloader/combine/combined.bin full-firmware-memory-protected.bin

full-firmware: bootloader firmware ## Build full firmware (RDP level 0)
	cp bootloader-no-memory-protect.bin tiny-firmware/bootloader/combine/bl.bin
	cp tiny-firmware/skycoin.bin tiny-firmware/bootloader/combine/fw.bin
	cd tiny-firmware/bootloader/combine/ ; $(PYTHON) prepare.py
	mv tiny-firmware/bootloader/combine/combined.bin full-firmware-no-mem-protect.bin

emulator: build-deps ## Build emulator
	EMULATOR=1 make -C tiny-firmware/emulator/
	EMULATOR=1 make -C tiny-firmware/
	mv tiny-firmware/skycoin-emulator emulator

run-emulator: emulator ## Run wallet emulator
	./emulator

test: ## Run all project test suites.
	export LIBRARY_PATH="$(MKFILE_DIR)/skycoin-api/:$$LIBRARY_PATH"
	export $(LD_VAR)="$(MKFILE_DIR)/skycoin-api/:$$$(LD_VAR)"
	make -C skycoin-api/ test
	make emulator
	EMULATOR=1 make -C tiny-firmware/ test

st-flash: ## Deploy (flash) firmware on physical wallet
	cd tiny-firmware/bootloader/combine/; st-flash write combined.bin 0x08000000

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
