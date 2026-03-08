# fast_send_server 部署说明

## 运行地址

http://43.153.143.37:40321/

## 方式一：直接部署（Node）

### 1. 本地打包

```bash
cd fast_send_server
npm ci
npm run build
```

会生成 `dist/` 目录（编译后的 JS）。

### 2. 上传到服务器

**必须上传/保留的内容：** 整个 `fast_send_server` 目录（含 `package.json`、`package-lock.json`、`src/`），**且在服务器上安装依赖并构建**，不能只上传 `dist/` 或单个 `main.js`。

在服务器上执行（在项目目录内）：

```bash
cd /www/wwwroot/rtc.a4life.xyz   # 或你的项目目录
npm ci --omit=dev                # 安装生产依赖，会生成 node_modules
npm run build                    # 生成 dist/
```

### 3. 在服务器上运行

**务必在项目根目录执行**（这样 `node` 才能找到 `node_modules` 里的 `@nestjs/common` 等）：

```bash
cd /www/wwwroot/rtc.a4life.xyz   # 进入项目目录
PORT=40321 node dist/main.js
# 或
PORT=40321 npm run start:prod
```

若报 `Cannot find module '@nestjs/common'`，说明当前目录没有 `node_modules`，请在本目录执行 `npm ci --omit=dev` 后再运行。

### 4. 后台常驻（推荐用 PM2）

**启动并指定端口：**

```bash
npm install -g pm2
cd fast_send_server
# 指定端口（例如 40321），可改成你需要的端口
PORT=40321 pm2 start dist/main.js --name fast-send-server
pm2 save && pm2 startup
```

**常用 PM2 命令：**

| 操作 | 命令 |
|------|------|
| 停止 | `pm2 stop fast-send-server` |
| 重启 | `pm2 restart fast-send-server` |
| 删除（停止并移出列表） | `pm2 delete fast-send-server` |
| 查看状态/日志 | `pm2 status` / `pm2 logs fast-send-server` |

**改端口后重启：**

先停止并删除旧进程，再按新端口启动：

```bash
pm2 delete fast-send-server
PORT=40321 pm2 start dist/main.js --name fast-send-server
pm2 save
```

---

## 方式二：Docker 部署

项目已包含 `Dockerfile`，可在服务器上：

```bash
cd fast_send_server
docker build -t fast-send-server .
docker run -d -p 3000:3000 --name fast-send fast-send-server
```

端口映射 `-p 3000:3000` 可按需改（如 `-p 80:3000`）。

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
