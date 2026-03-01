# Makefile 使用文档
# https://www.gnu.org/software/make/manual/html_node/index.html

# include .envrc
SHELL = /bin/bash

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/n] ' && read ans && [ $${ans:-N} = y ]

.PHONY: title
title:
	@echo -e "\033[34m$(content)\033[0m"

.PHONY: rename
## rename: clone 后的模板，需要更新 module 名
rename:
	@if [ -z "$(name)" ]; then \
		echo "错误: 请提供 name 参数，例如: make rename name=github.com/name/project"; \
		exit 1; \
	fi
	@rm -rf domain/* pkg/*
	@echo "正在替换模块名为: $(name)"
	@find . -type f -name "*.go" -exec sed -i.bak 's|github\.com/ixugo/goddd/internal|$(name)/internal|g' {} \;
	@sed -i.bak 's|github\.com/ixugo/goddd|$(name)|g' go.mod
	@find . -name "*.bak" -delete
	@go mod tidy
	@echo -e "\n模块名替换完成"





# ==================================================================================== #
# VERSION
# ==================================================================================== #

# 版本号规则说明
# 1. 版本号使用 Git tag，格式为 v1.0.0。
# 2. 如果当前提交没有 tag，找到最近的 tag，计算从该 tag 到当前提交的提交次数。例如，最近的 tag 为 v1.0.1，当前提交距离它有 10 次提交，则版本号为 v1.0.11（v1.0.1 + 10 次提交）。
# 3. 如果没有任何 tag，则默认版本号为 v0.0.0，后续提交次数作为版本号的次版本号。

# Get the current module name
MODULE_NAME := $(shell pwd | awk -F "/" '{print $$NF}')
# Get the latest commit hash and date
HASH_AND_DATE := $(shell git log -n1 --pretty=format:"%h-%cd" --date=format:%y%m%d | awk '{print $1}')
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

# 如果想仅支持注释标签，可以去掉 --tags，否则会包含轻量标签
RECENT_TAG := $(shell git describe --tags --abbrev=0  2>&1 | grep -v "fatal" || echo "v0.0.0")

ifeq ($(RECENT_TAG),v0.0.0)
	COMMITS := $(shell git rev-list --count HEAD)
else
	COMMITS := $(shell git log --first-parent --format='%ae' $(RECENT_TAG)..$(BRANCH) | wc -l)
	COMMITS := $(shell echo $(COMMITS) | sed 's/ //g')
endif

# 从版本字符串中提取主版本号、次版本号和修订号
GIT_VERSION_MAJOR := $(shell echo $(RECENT_TAG) | cut -d. -f1 | sed 's/v//')
GIT_VERSION_MINOR := $(shell echo $(RECENT_TAG) | cut -d. -f2)
GIT_VERSION_PATCH := $(shell echo $(RECENT_TAG) | cut -d. -f3)

# windows 系统 git bash 没有 bc
# FINAL_PATCH := $(shell echo $(GIT_VERSION_PATCH) + $(COMMITS) | bc)
FINAL_PATCH := $(shell echo '$(GIT_VERSION_PATCH) $(COMMITS)' | awk '{print $$1 + $$2}')
VERSION := v$(GIT_VERSION_MAJOR).$(GIT_VERSION_MINOR).$(FINAL_PATCH)

# test:
# 	@echo ">>>${RECENT_TAG}"

## info: 查看构建版本相关信息
.PHONY: info
info:
	@echo "dir: $(MODULE_NAME)"
	@echo "version: $(VERSION)"
	@echo "branch $(BRANCH)"
	@echo "hash: $(HASH_AND_DATE)"
	@echo "support $$(go tool dist list | grep amd64 | grep linux)"



# targetPlatform:=android-arm,android-arm64
targetPlatform:=android-arm64

.PHONY: build/android
build/android:
	@flutter build apk \
		--release \
		--target-platform ${targetPlatform} \
		--obfuscate --split-debug-info=./symbols \
		--split-per-abi \
		--build-name=$(VERSION)
	@rm -rf ./app && mkdir -p ./app
	@cp ./build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ./app/flutter_$(HASH_AND_DATE)_$(VERSION).apk
	@echo "[OK] build android apk, see ./app/flutter_$(HASH_AND_DATE)_$(VERSION).apk"
