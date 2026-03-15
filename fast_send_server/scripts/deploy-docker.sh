#!/usr/bin/env bash
# 本地构建镜像并导出为 tar，可选：通过 DEPLOY_SSH 自动上传到服务器。
# 需在仓库根目录构建（上下文需同时包含 fast_send_server 与 share-page-app）。
# 用法：
#   仅打包：npm run docker:deploy-pack
#   打包并上传：DEPLOY_SSH=root@43.153.143.37 DEPLOY_PATH=/www/wwwroot/rtc.a4life.xyz npm run docker:deploy-pack

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT="$(dirname "$SERVER_DIR")"

IMAGE_NAME="${IMAGE_NAME:-fast-send-server}"
TAR_NAME="${TAR_NAME:-fast-send-server.tar}"
TAR_PATH="$SERVER_DIR/$TAR_NAME"

# 可选：上传目标。例 DEPLOY_SSH=root@43.153.143.37  DEPLOY_PATH=/www/wwwroot/rtc.a4life.xyz
DEPLOY_SSH="${DEPLOY_SSH:-}"
DEPLOY_PATH="${DEPLOY_PATH:-/tmp}"

# 服务器多为 x86，在 Mac (arm64) 上构建时需指定平台，否则会 exec format error
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/amd64}"
EXPECTED_ARCH="${BUILD_PLATFORM#linux/}"  # linux/amd64 -> amd64

echo "Building Docker image: $IMAGE_NAME (platform: $BUILD_PLATFORM, context: $WORKSPACE_ROOT)"
cd "$WORKSPACE_ROOT"

# 使用支持多平台的 builder，否则在 Mac 上 --platform 可能被忽略、打出仍是 arm64
if docker buildx use amd64builder 2>/dev/null; then
  echo "Using buildx builder: amd64builder"
else
  echo "Creating buildx builder 'amd64builder' for cross-build (one-time)..."
  docker buildx create --name amd64builder --driver docker-container --platform "$BUILD_PLATFORM" || true
  docker buildx use amd64builder
fi

docker buildx build --platform "$BUILD_PLATFORM" --load -f fast_send_server/Dockerfile -t "$IMAGE_NAME" .

BUILT_ARCH="$(docker image inspect "$IMAGE_NAME" --format '{{.Architecture}}' 2>/dev/null || true)"
echo "Image architecture: $BUILT_ARCH (expected: $EXPECTED_ARCH)"
if [[ -n "$BUILT_ARCH" && "$BUILT_ARCH" != "$EXPECTED_ARCH" ]]; then
  echo "ERROR: 镜像架构为 $BUILT_ARCH，与目标 $EXPECTED_ARCH 不一致，上传到 x86 服务器会 exec format error。"
  echo "请在本机先执行："
  echo "  docker buildx create --name amd64builder --driver docker-container --platform linux/amd64"
  echo "  docker buildx use amd64builder"
  echo "再重新运行: npm run docker:deploy-pack"
  exit 1
fi

echo "Saving image to $TAR_PATH"
docker save -o "$TAR_PATH" "$IMAGE_NAME"

if [[ -n "$DEPLOY_SSH" ]]; then
  echo "Uploading to $DEPLOY_SSH:$DEPLOY_PATH/"
  scp "$TAR_PATH" "$DEPLOY_SSH:$DEPLOY_PATH/" || {
    echo "scp 失败，请检查：1) ssh $DEPLOY_SSH 能否登录 2) 目标路径 $DEPLOY_PATH 是否存在且有写权限"
    exit 1
  }
  echo "Upload done. On server run:"
  echo "  docker load -i $DEPLOY_PATH/$TAR_NAME && docker stop fast-send 2>/dev/null; docker rm fast-send 2>/dev/null; docker run -d -p 40321:3000 -e PORT=3000 --name fast-send --restart unless-stopped $IMAGE_NAME"
else
  echo "Done. To upload manually:"
  echo "  scp $TAR_PATH root@你的服务器:$DEPLOY_PATH/"
  echo "On server: docker load -i $DEPLOY_PATH/$TAR_NAME && docker run -d -p 40321:3000 -e PORT=3000 --name fast-send --restart unless-stopped $IMAGE_NAME"
fi
