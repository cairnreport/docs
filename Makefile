# Cairn Report documentation site. Site code: MIT (see LICENSE).
#
# Hugo and lychee are pinned and downloaded (checksum-verified) into .tools/
# on Linux amd64/arm64. Elsewhere, put the same versions on PATH and run
# `make HUGO=hugo LYCHEE=lychee ...`.

SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := build

# renovate: datasource=github-releases depName=gohugoio/hugo
HUGO_VERSION := v0.169.0
# renovate: datasource=github-releases depName=lycheeverse/lychee versioning=regex:^lychee-v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
LYCHEE_VERSION := lychee-v0.24.2

TOOLS := $(CURDIR)/.tools
PUBLIC := $(CURDIR)/public

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
  HUGO_ARCH := amd64
  LYCHEE_ARCH := x86_64
else ifneq ($(filter aarch64 arm64,$(UNAME_M)),)
  HUGO_ARCH := arm64
  LYCHEE_ARCH := aarch64
endif

HUGO_V := $(HUGO_VERSION:v%=%)
HUGO_ASSET := hugo_$(HUGO_V)_linux-$(HUGO_ARCH).tar.gz
HUGO_URL := https://github.com/gohugoio/hugo/releases/download/$(HUGO_VERSION)
LYCHEE_ASSET := lychee-$(LYCHEE_ARCH)-unknown-linux-gnu.tar.gz
LYCHEE_URL := https://github.com/lycheeverse/lychee/releases/download/$(LYCHEE_VERSION)

ifeq ($(UNAME_S)-$(if $(HUGO_ARCH),ok),Linux-ok)
  HUGO ?= $(TOOLS)/hugo-$(HUGO_V)/hugo
  LYCHEE ?= $(TOOLS)/$(LYCHEE_VERSION)/lychee
else
  HUGO ?= hugo
  LYCHEE ?= lychee
endif

LYCHEE_FLAGS := --no-progress --root-dir $(PUBLIC) --include-fragments

.PHONY: build serve check check-links check-links-external clean tools

## build: production build into public/ (minified)
build: $(HUGO)
	$(HUGO) --minify --gc --cleanDestinationDir --panicOnWarning --destination $(PUBLIC)

## serve: local preview at http://localhost:1313 with live reload
serve: $(HUGO)
	$(HUGO) server --buildDrafts --disableFastRender --bind 127.0.0.1

## check: build, audit the output (no scripts, only allowed external URLs),
## check internal links offline, and check the tool pins match the workflow
check: build check-links
	scripts/check-site.sh $(PUBLIC)
	scripts/check-pins.sh

check-links: $(LYCHEE)
	$(LYCHEE) $(LYCHEE_FLAGS) --offline '$(PUBLIC)/**/*.html'

## check-links-external: also check external links (network; cached for 1 day)
check-links-external: $(LYCHEE)
	$(LYCHEE) $(LYCHEE_FLAGS) --cache --max-cache-age 1d \
	  --exclude '^https://cairnreport\.dev' '$(PUBLIC)/**/*.html'

tools: $(HUGO) $(LYCHEE)

$(TOOLS)/hugo-$(HUGO_V)/hugo:
	rm -rf $(@D) && mkdir -p $(@D)
	cd $(@D) && curl -fsSLO $(HUGO_URL)/$(HUGO_ASSET) \
	  && curl -fsSL $(HUGO_URL)/hugo_$(HUGO_V)_checksums.txt | grep " $(HUGO_ASSET)$$" | sha256sum -c - \
	  && tar -xzf $(HUGO_ASSET) hugo && rm $(HUGO_ASSET)
	$@ version

$(TOOLS)/$(LYCHEE_VERSION)/lychee:
	rm -rf $(@D) && mkdir -p $(@D)
	cd $(@D) && curl -fsSLO $(LYCHEE_URL)/$(LYCHEE_ASSET) \
	  && curl -fsSL $(LYCHEE_URL)/$(LYCHEE_ASSET).sha256 | sha256sum -c - \
	  && tar -xzf $(LYCHEE_ASSET) && rm $(LYCHEE_ASSET) \
	  && { [ -f lychee ] || mv lychee-*/lychee . ; }
	$@ --version

clean:
	rm -rf $(PUBLIC) resources/_gen .hugo_build.lock .lycheecache
