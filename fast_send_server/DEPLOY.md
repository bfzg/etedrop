# fast_send_server 部署说明

## 需要打包吗？

**需要。** 服务是 TypeScript 写的，部署前要先编译成 JavaScript，再在服务器上用 Node 运行。

---

## 方式一：直接部署（Node）

### 1. 本地打包

```bash
cd fast_send_server
npm ci
npm run build
```

会生成 `dist/` 目录（编译后的 JS）。

### 2. 上传到服务器

把整个项目目录上传（包含 `dist/`、`package.json`、`package-lock.json`），或只在服务器上拉代码再执行：

```bash
git clone <你的仓库> && cd fast_send_server
npm ci --omit=dev    # 只装生产依赖
npm run build
```

### 3. 在服务器上运行

```bash
# 端口可用环境变量 PORT 指定，默认 3000
PORT=3000 node dist/main.js
# 或
npm run start:prod
```

### 4. 后台常驻（推荐用 PM2）

```bash
npm install -g pm2
pm2 start dist/main.js --name fast-send-server
pm2 save && pm2 startup
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

---

## 部署后检查

- HTTP: `http://你的服务器IP:3000/`
- WebSocket 分享: `ws://你的服务器IP:3000/api/share`
- WebSocket 信令: `ws://你的服务器IP:3000/api/connect`
- 分享页: `http://你的服务器IP:3000/share/:deviceId/:shareCode`

客户端里的 `shareLinkBaseUrl`、`shareServerUrl` 要改成你的服务器地址（如 `https://你的域名`、`wss://你的域名`）。
