# fast_send_server 部署说明

## 运行地址

http://43.153.143.37:40321/

---

## 推荐：Docker 部署（无需在服务器上 npm i / 构建）

本地一次构建镜像，拷到服务器后直接运行，**服务器只需安装 Docker**，不用装 Node、不用拷贝源码、不用跑 npm i。

**本地需先启动 Docker**（Docker Desktop 或 Colima 等），否则会报 `failed to connect to the docker API`。

### 1. 本地打包镜像并导出

```bash
cd fast_send_server
npm run docker:deploy-pack
# 或
./scripts/deploy-docker.sh
```

会生成 **`fast-send-server.tar`**（已含后端 + 分享页前端，开箱即用）。

### 2. 上传到服务器

**方式 A：脚本自动上传**（需已配置 SSH 免密登录）

```bash
DEPLOY_SSH=root@43.153.143.37 DEPLOY_PATH=/www/wwwroot/rtc.a4life.xyz npm run docker:deploy-pack
```

脚本会先构建、打包，再执行 `scp`。若失败，请检查：1) `ssh $DEPLOY_SSH` 能否登录；2) 目标路径是否存在（不存在则先在服务器上 `mkdir -p /www/wwwroot/rtc.a4life.xyz`）。

**方式 B：手动上传**

```bash
scp fast_send_server/fast-send-server.tar user@你的服务器:/tmp/
```

### 3. 在服务器上加载并运行

```bash
docker load -i /www/wwwroot/rtc.a4life.xyz/fast-send-server.tar
docker stop fast-send 2>/dev/null; docker rm fast-send 2>/dev/null
docker run -d -p 40321:3000 -e PORT=3000 --name fast-send --restart unless-stopped fast-send-server
```

**更新部署**：本地重新执行步骤 1～2，服务器上重复上面三条命令即可（先 load 再 stop/rm 再 run）。

### 4. 若出现 `exec format error`（架构不一致）

说明镜像是按你本机 CPU 架构打的（如 Mac 上是 arm64），而服务器是 x86。**部署脚本已用 `buildx` 按 `linux/amd64` 构建**，按下面做一遍即可：

**1）服务器上删掉旧容器和旧镜像**

```bash
docker stop fast-send 2>/dev/null; docker rm fast-send 2>/dev/null
docker rmi fast-send-server
```

**2）本机重新打包并上传**

```bash
npm run docker:deploy-pack
# 上传生成的 fast-send-server.tar 到服务器
```

**3）服务器上重新 load 并运行**

```bash
docker load -i /path/to/fast-send-server.tar
docker run -d -p 40321:3000 -e PORT=3000 --name fast-send --restart unless-stopped fast-send-server
```

**4）在服务器上确认镜像架构**

```bash
docker image inspect fast-send-server --format '{{.Architecture}}'
```

应显示 `amd64`。若仍是 `arm64`，说明本机（Mac）构建时未按 amd64 产出，按下面 **5）** 在本机创建专用 builder 再打包。

**5）本机 Mac 上强制打出 amd64 镜像（若 4 显示为 arm64）**

Docker 默认 builder 有时会忽略 `--platform`，需要单独建一个用于跨平台的 builder，再打包：

```bash
# 本机执行（仅需一次）
docker buildx create --name amd64builder --driver docker-container --platform linux/amd64
docker buildx use amd64builder

# 再打包
cd fast_send_server && npm run docker:deploy-pack
```

脚本会检查打出的镜像架构，若不是 amd64 会报错并提示上述命令。完成后重新上传 tar，在服务器上 `docker rmi fast-send-server` 再 `docker load` 和 `docker run`。

若服务器是 **arm64**，可指定平台再打包：`BUILD_PLATFORM=linux/arm64 npm run docker:deploy-pack`。

### 5. Docker 下查看服务状态与日志

| 操作 | 命令 |
|------|------|
| 查看是否在跑 | `docker ps`（看是否有 `fast-send`、状态为 Up） |
| 查看状态摘要 | `docker ps -a --filter name=fast-send` |
| 实时看日志 | `docker logs -f fast-send` |
| 最近 N 行日志 | `docker logs --tail 100 fast-send` |
| 停止 | `docker stop fast-send` |
| 启动 | `docker start fast-send` |
| 重启 | `docker restart fast-send` |

查看日志时用**容器名** `fast-send`，不要用镜像名 `fast-send-server`。若用 **Docker Compose** 部署，可执行：`docker compose ps`、`docker compose logs -f`。

### 可选：用 Docker Compose

当前只有一个容器，单条 `docker run` 已够用。若希望用配置文件管理（端口、环境变量一目了然，以后加 nginx 等也方便），可用 Compose：

1. 把 `fast_send_server/docker-compose.yml` 拷到服务器某目录（如 `/opt/fast-send/`）。
2. 在该目录执行：
   ```bash
   docker load -i /tmp/fast-send-server.tar
   docker compose up -d
   ```
3. 更新时：重新 load 镜像后执行 `docker compose up -d --force-recreate`。

## 方式二：直接部署（Node）

适合不想用 Docker、在服务器上直接跑 Node 的场景。

### 1. 本地打包

```bash
cd fast_send_server
npm ci
npm run build              # Nest 后端
npm run build:share        # 分享页 React 前端 → 输出到 public/share/
```

会生成 `dist/` 和 `public/share/`。部署时需保留 `public/share/`。

### 2. 上传到服务器

上传整个项目目录（含 `package.json`、`package-lock.json`、`src/`、`dist/`、`public/`）。

在服务器上（在项目目录内）：

```bash
cd /www/wwwroot/rtc.a4life.xyz
npm ci --omit=dev          # 仅安装生产依赖（无需再构建）
```

### 3. 在服务器上运行

```bash
PORT=40321 node dist/main.js
# 或
PORT=40321 npm run start:prod
```

### 4. 后台常驻（PM2）

```bash
npm install -g pm2
PORT=40321 pm2 start dist/main.js --name etedrop-server
pm2 save && pm2 startup
```

| 操作 | 命令 |
|------|------|
| 停止 | `pm2 stop etedrop-server` |
| 重启 | `pm2 restart etedrop-server` |
| 日志 | `pm2 logs etedrop-server` |

---

## 环境变量

| 变量 | 说明 | 默认 |
|------|------|------|
| `PORT` | HTTP 与 WebSocket 服务端口 | `3000` |

**Node 版本：** 开发用 Node 24、服务器用 Node 22 没问题，NestJS 都兼容。无需改代码。

---

## 部署后检查

- HTTP: `http://你的服务器IP:3000/`
- WebSocket 分享: `ws://你的服务器IP:3000/api/share`
- WebSocket 信令: `ws://你的服务器IP:3000/api/connect`
- 分享页: `http://你的服务器IP:3000/share/:deviceId/:shareCode`

客户端里的 `shareLinkBaseUrl`、`shareServerUrl` 要改成你的服务器地址（如 `https://你的域名`、`wss://你的域名`）。
