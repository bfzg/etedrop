# Flutter 与服务端联调计划

## 一、背景与目标

Flutter 客户端需对接 Eddy 服务端的 **WebSocket 信令**（取件码传文件、设备/分享通道）与 **REST 分享 API**（若使用服务端存储）。本文档给出 baseUrl、WS 地址、鉴权与错误处理的联调清单，便于开发与测试环境统一。

---

## 二、范围

| In Scope | Out of Scope |
|----------|--------------|
| 环境与地址配置（开发/测试/生产） | 具体 UI 实现 |
| WebSocket 连接地址与协议约定 | WebRTC 内部实现 |
| REST baseUrl 与分享 API 调用方式 | 业务状态管理细节 |
| 错误处理与重连策略（清单级） | 鉴权实现细节（当前无 token） |

---

## 三、地址与配置清单

### 3.1 当前 Flutter 常量（lib/core/config/constants.dart）

| 常量 | 当前示例值 | 说明 |
|------|------------|------|
| signalingServerUrl | `wss://fastsend.ing/api/connect` | 取件码传文件用 WebSocket |
| shareServerUrl | `ws://localhost:3000/api/share` | 设备注册/分享通道 WebSocket |
| shareLinkBaseUrl | `http://localhost:3000` | 分享链接前缀（如 /share/:deviceId/:shareCode），本地联调与服务端同地址 |
| heartbeatInterval | 30000 | 心跳间隔（毫秒） |
| reconnectInterval | 5000 | 重连间隔（毫秒） |

**联调要点**：

- 开发时：`shareServerUrl` 通常为 `ws://localhost:3000/api/share` 或本机 IP，与本地运行的服务端一致；`signalingServerUrl` 可为同一服务端的 `ws://localhost:3000/api/connect` 或已有公网 wss。
- 测试/生产：所有 WS 与 HTTP 需使用同一域名或明确区分的域名，并统一为 wss/https；`webBaseUrl` 为分享页访问根地址。

### 3.2 REST API Base URL

- 当前 Dio 示例为 `baseUrl: 'https://xxx.com'`，**需在联调前改为实际服务端地址**（如 `http://localhost:3000` 或 `https://api.xxx.com`）。
- 分享 REST 路径为：`POST/GET/DELETE /api/share`、`GET /api/share/:code`，与《分享接口说明》一致；若 baseUrl 已含端口或路径前缀，请求 path 为相对路径即可。

### 3.3 WebSocket 路径与协议

| 场景 | 地址 | 协议依据 |
|------|------|----------|
| 传文件（发送/接收） | signalingServerUrl → `/api/connect` | 《信令协议说明》取件码通道 |
| 设备上线/分享 | shareServerUrl → `/api/share` | 《信令协议说明》分享/设备通道 |

- 连接时使用 `Uri.parse(signalingServerUrl)` 或 `Uri.parse(shareServerUrl)`，无需再拼 path。
- 消息格式：JSON，必填字段 `type`；其余见《信令协议说明》。

---

## 四、鉴权（当前与后续）

- **当前**：服务端 REST 与两条 WS 均无鉴权；Flutter 端 Dio 已挂载 `AuthInterceptor`，可预留 token 写入逻辑，但服务端暂不校验。
- **后续**：若增加 JWT 或设备签名，需约定：
  - REST：Header `Authorization: Bearer <token>` 或 Query 参数；
  - WS：首包携带 token 或由服务端在握手后首条消息校验。
  具体以《认证与安全设计》为准，联调时在本文档补充「鉴权开关」与测试账号/设备说明。

---

## 五、错误处理清单

### 5.1 WebSocket

- **连接失败**：提示网络错误，按 reconnectInterval 重连；若为「取件码」场景，可提示用户检查取件码或稍后重试。
- **服务端 err 消息**：根据 `msg` 或未来统一 `code` 展示提示（如「该取件码已被使用」「设备尚未注册」「会话已超时」）。
- **对端断开**：信令会收到 `err`，需清理本地会话状态并提示（如「发送方已断开连接」）。

### 5.2 REST（分享 API）

- **4xx**：404 按《分享接口说明》统一为「分享不存在或已过期」；400 为参数错误，展示校验信息。
- **5xx**：提示服务异常，可带重试入口。
- **超时**：Dio 已配置 connectTimeout/receiveTimeout，可在拦截器中统一提示「请求超时」。

### 5.3 分享链接

- 生成格式：`${shareLinkBaseUrl}/share/${deviceId}/${shareCode}`，与《WebRTC网盘与分享方案》§8.9 一致。
- 若分享页尚未部署，链接可先用于复制；打开后需服务端提供对应页面或 SPA 路由。

---

## 六、联调检查项（按顺序）

1. **环境**：服务端已启动（默认 3000 端口），Flutter 中 shareServerUrl / baseUrl 指向该地址。
2. **取件码**：发送方连 `/api/connect` 发 send → 收 code；接收方同端点发 receive + code → 双方能交换 sdp/candidate，建立 P2P。
3. **设备通道**：Desktop 连 `/api/share` 发 device-online（deviceId/deviceName）→ 收 device-online-ack；定期发 heartbeat；服务端 2 分钟无心跳踢下线。
4. **分享 REST**（若使用）：POST /api/share 创建 → GET /api/share 列表 → GET /api/share/:code?password=xxx 查询 → DELETE /api/share/:code 删除；code 大小写不敏感。
5. **分享链接**：生成的链接格式正确；若已有分享页，在浏览器中打开可进入下载流程（含设备离线提示）。

---

## 七、验收标准

- 能根据本文档在开发环境完成「取件码传文件 + 设备上线 + 分享 REST（若用）」的端到端联调。
- 地址与错误处理与《信令协议说明》《分享接口说明》无冲突；后续鉴权或新接口在本文档补充即可。

---

## 八、待办项与风险

| 待办 | 说明 |
|------|------|
| baseUrl 配置化 | 将 Dio baseUrl 与 WS 地址改为环境/构建配置（如 flavor 或 .env），避免写死 |
| 错误码统一 | 服务端与 Flutter 约定统一 err.code，便于多语言文案与分类处理 |
| 分享页联调 | 服务端提供分享页后，在 Flutter 中验证链接打开与离线提示流程 |

**风险**：本地使用 localhost 时，真机无法直连；需用本机 IP 或隧道/公网环境进行设备与分享联调。
