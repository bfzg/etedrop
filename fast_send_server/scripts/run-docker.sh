#!/usr/bin/env bash
# 在服务器上加载镜像并运行（首次或更新后）。端口、镜像名可通过环境变量覆盖。
# 用法：在服务器上执行 ./scripts/run-docker.sh

set -e
cd "$(dirname "$0")/.."
IMAGE_NAME="${IMAGE_NAME:-fast-send-server}"
CONTAINER_NAME="${CONTAINER_NAME:-fast-send}"
PORT="${PORT:-40321}"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping and removing existing container: $CONTAINER_NAME"
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

echo "Starting $CONTAINER_NAME on port $PORT"
docker run -d \
  -p "${PORT}:3000" \
  -e PORT=3000 \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  "$IMAGE_NAME"

echo "Done. Check: docker logs -f $CONTAINER_NAME"
