SHELL := /bin/bash

APP_DIR := .
APP_OUT_DIR := $(APP_DIR)/share

# 服务端静态托管目录（Nest public/share）
SERVER_SHARE_DIR := ../fast_send_server/public/share

.PHONY: install build deploy clean

install:
	@cd "$(APP_DIR)" && npm install

build:
	@cd "$(APP_DIR)" && npm run build

# 打包并同步到服务端托管目录
deploy: build
	@mkdir -p "$(SERVER_SHARE_DIR)"
	@rsync -a --delete "$(APP_OUT_DIR)/" "$(SERVER_SHARE_DIR)/"
	@echo "Deployed to $(SERVER_SHARE_DIR)"

clean:
	@rm -rf "$(APP_OUT_DIR)"
