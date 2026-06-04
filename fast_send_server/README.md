# fast_send_server 部署说明

代码里默认 **`PORT=3000`**、`HOST=0.0.0.0`（`src/main.ts`）。生产与 Nginx 反代约定 **`PORT=40321`**，由本机 `127.0.0.1:40321` 连到上游（见 `doc/服务器部署文档.md`）。

对外域名由 Nginx 终止 TLS，例如：

- 国内线：`https://api.etedrop.cn`
- 全球线：`https://api.etedrop.com`

（客户端线路见 `fast_send_flutter/lib/core/config/server_endpoints.dart`。）

###  后台常驻（PM2）

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
| 从 PM2 列表删除 | `pm2 delete etedrop-server`（删除后执行 `pm2 save` 更新持久化列表） |
| 取消开机自启 | 若曾执行过 `pm2 startup`：先 `pm2 unstartup`（或按该命令输出的提示用 root 跑一遍），再按需 `pm2 delete` + `pm2 save` |

彻底不再用 PM2 托管本服务时：**`pm2 delete etedrop-server`** → **`pm2 save`**；若希望系统重启后也不再拉起，再执行 **`pm2 unstartup`**（以当前系统提示为准）。

---

## 日志在哪儿看

1. **PM2 标准输出**（Nest 的 `Logger`、连接/断线等）：  
   `pm2 logs etedrop-server`  
   含启动时的 `Listening on …`、`SignalingService` / `Share` 相关行（如浏览器连上某 `deviceId`、设备上下线等，视代码里 `log`/`debug` 级别而定）。

2. **用量统计写文件**（若开启相关逻辑）：数据目录下的 `device-usage.log`（见 `usage-analytics.service.ts` 中 `eventLogPath`），不是替代 PM2 的主日志，而是追加的业务事件。

3. **Nginx 访问/错误**（HTTPS 是否到达本机、是否 502）：  
   例如 `sudo tail -f /var/log/nginx/access.log` 与你站点 `error_log` 配置的路径。

> 注意：进程须带 **`PORT=40321`**（或与 Nginx `proxy_pass` 一致），否则默认会监听 **3000**（见 `src/main.ts`），Nginx 会连错端口。

---

## 部署后检查

本机直连（调试用，端口与上面一致）：

- `curl -sS http://127.0.0.1:40321/` → 应返回 **`Hello World!`**（`AppController` 根路径）

经 Nginx / HTTPS：

- WebSocket 分享: `wss://你的 API 域名/api/share`
- WebSocket 信令: `wss://你的 API 域名/api/connect`
- 分享页: `https://你的官网域名/share/:deviceId/:shareCode`

客户端 `shareServerUrl` / `signalingServerUrl` 须与上述域名一致。

---

## 服务端状态与用量查询（预留 HTTP 接口）

业务统计由 `SignalingController` 挂在 **`/api/system`** 下，全部为 **GET**、返回 JSON（`/metrics` 除外）。单机部署时：**「安装数量」** 指服务端曾登记过的**不同 `deviceId` 数量**（持久化在部署目录下 `runtime/device-registry.json`）；**「在线数量」** 指当前信令 WebSocket 仍连接着的设备数。多机或多实例时，每台机器各自一份 registry，需自行汇总。

| 路径 | 说明 |
|------|------|
| **`/api/system/health`** | 心跳 + 汇总：进程正常、`signaling` 运行时指标、`usage` 用量摘要、`timestamp`。 |
| **`/api/system/usage/summary`** | 仅返回用量摘要（与 `health` 里的 `usage` 相同）。 |
| **`/api/system/usage/devices?limit=200`** | 最近活跃的一批设备明细（上限 2000，默认 200）；含 `isOnline` 等字段。 |
| **`/api/system/usage/events?limit=200`** | 最近用量事件（上线/离线/浏览器连接等，上限 1000，默认 200）。 |
| **`/api/system/metrics`** | Prometheus 文本指标（`Content-Type: text/plain; version=0.0.4`），便于 Grafana / `prometheus` 抓取。 |

**`health.signaling`（运行时，内存态）**

- `onlineDevices`：当前在线设备（WebSocket 连接数）。
- `waitingSessions` / `pairedSessions`：信令会话中等待配对 / 已配对数量。

**`usage` / `usage/summary`（`UsageSummary`）**

- `installedDevices`：累计出现过的唯一设备数（等价于安装侧「登记过的设备」规模）。
- `onlineDevices`：当前在线设备数（与 `signaling.onlineDevices` 一致口径）。
- `activeDevices24h`：最近 24 小时内有活动的唯一设备数（按 registry 里 `lastSeenAt`）。
- `totalOnlineEvents` / `totalBrowserConnectEvents`：历史上线次数、浏览器连接次数累加。
- `recordedAt`：本条摘要生成时间（毫秒时间戳）。

**示例（本机，端口与上文一致）：**

```bash
curl -sS https://api.etedrop.cn/api/system/health | jq .
curl -sS https://api.etedrop.cn/api/system/usage/summary | jq .
curl -sS https://api.etedrop.cn/api/system/metrics
```

经公网 HTTPS 时把主机换成实际 API 域名即可，例如：``。

> 接口当前**无鉴权**；若不想对外暴露用量，可在 Nginx 上对 `/api/system` 做 IP 白名单、Basic Auth 或内网-only。

### 怎么验证 `https://api.etedrop.cn` 能访问（国内线示例）

域名以你实际解析为准；下面以 **`api.etedrop.cn`** 为例（勿与 `etedrop` 拼写混淆）。

在**任意能上网的机器**上：

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://api.etedrop.cn/
```

期望 **`200`**，且：

```bash
curl -sS https://api.etedrop.cn/
```

正文为 **`Hello World!`**，说明 TLS、Nginx 反代、`fast_send_server` 均正常。

在**API 所在服务器本机**还可对比（不经公网 DNS，只测本机服务）：

```bash
curl -sS http://127.0.0.1:40321/
```

若本机有 `200` 而域名无响应，查 Nginx、`proxy_pass` 端口、防火墙、DNS 是否指到该机。

用浏览器打开 `https://api.etedrop.cn/` 也应直接看到 `Hello World!`（部分环境会对根路径做缓存，以 `curl` 为准更稳）。

### 分享页 404：`api-cn.etedrop.com/public/share/index.html` 等旧路径

**若 JSON 里仍是 `…/api-cn.etedrop.com/…`，说明跑的还是旧版 `dist`（之前用 `process.cwd()` 拼路径）。** 必须在**部署目录**重新编译并重启：

```bash
cd /你的部署根目录/例如/api.etedrop.cn
git pull   # 若从仓库拉代码
npm ci && npm run build
pm2 restart etedrop-server
```

在服务器上自检**当前 `dist` 是否已弃用 cwd**（无输出为正常）：

```bash
grep "process.cwd" dist/share-page/share-page.controller.js || echo "ok: 已不用 cwd"
```

`pm2 logs etedrop-server` 启动后应出现一行：  
`Share SPA: /你的部署目录/public/share/index.html`（路径里不应再出现 `api-cn`）。

**仍缺文件时**：先确认 **`public/share/index.html`** 存在（执行 **`npm run build:share`** 并按你们流程把产物放进 `public/share/`）。**应急**（不改代码、只改环境）：给进程设置 **`FAST_SEND_PUBLIC_ROOT`** 为 **`public` 目录的绝对路径**（其下含 `share/index.html`），例如：

```bash
# ecosystem 或 shell 中（路径按你机器修改）
export FAST_SEND_PUBLIC_ROOT=/home/app/api.etedrop.cn/public
pm2 restart etedrop-server --update-env
```

说明：业务代码已用 **`__dirname` 解析**；`FAST_SEND_PUBLIC_ROOT` 仅作运维兜底。
