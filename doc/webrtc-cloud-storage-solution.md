# WebRTC 自建网盘方案设计

## 一、需求概述

构建一个基于 WebRTC 的自建网盘系统：
- **Desktop 端（服务端）**：部署在用户的 Windows/Mac 上，指定文件夹作为存储目录，电脑开机即可运行
- **客户端**：手机、网页通过 WebRTC 连接 Desktop 获取/传输文件
- **核心要求**：支持跨网络访问、P2P 优先、连接失败时走转发（TURN）

---

## 二、可行性分析

### 2.1 技术可行性 ✅

| 方面 | 评估 | 说明 |
|------|------|------|
| WebRTC DataChannel | ✅ 可行 | 现有 `PeerDataChannel.ts` 已实现完整的数据传输封装 |
| P2P 穿透 | ⚠️ 部分可行 | 仅靠 STUN 约 70-80% 成功率，需 TURN 兜底 |
| 跨网络访问 | ✅ 可行 | 需要信令服务器 + TURN 转发 |
| 桌面常驻服务 | ✅ 可行 | Electron 支持系统托盘、开机自启 |
| 文件系统访问 | ✅ 可行 | Electron 有完整的 Node.js 文件系统 API |

### 2.2 现有项目基础

```
FastSend/
├── utils/PeerDataChannel.ts   # WebRTC DataChannel 封装（可复用）
├── utils/publicStunList.ts    # 公共 STUN 列表（无 TURN）
├── server/                    # Nuxt 信令服务器

fast_send_desktop/
├── Electron + React + shadcn-ui
├── 已有完整的桌面应用框架
```

**现有问题**：
- `pubTurnList = []` —— 没有 TURN 服务器，NAT 穿透失败时无法回退
- 信令服务器依赖 Nuxt，需要公网部署

---

## 三、方案对比

### 3.1 方案一：纯 WebRTC + 自建 TURN（推荐 ⭐）

```
┌─────────────┐     信令(WebSocket)     ┌─────────────┐
│   Desktop   │◄────────────────────────►│  信令服务器  │
│  (服务端)    │                          │  (公网)     │
└──────┬──────┘                          └──────┬──────┘
       │                                        │
       │  P2P (优先) / TURN (兜底)              │
       │◄──────────────────────────────────────►│
       │                                        │
┌──────▼──────┐                          ┌──────▼──────┐
│    手机     │                          │    网页     │
│   (客户端)   │                          │   (客户端)   │
└─────────────┘                          └─────────────┘
```

**组件**：
| 组件 | 技术选型 | 部署位置 |
|------|----------|----------|
| 信令服务器 | Node.js + WebSocket | 公网 VPS（轻量） |
| STUN 服务器 | 公共 STUN（Google等） | 无需部署 |
| TURN 服务器 | coturn | 公网 VPS |
| Desktop | Electron | 用户本地 |
| 客户端 | Web/PWA | 浏览器 |

**优点**：
- 轻量，只需 WebRTC DataChannel，无视频模块
- 可复用现有 `PeerDataChannel.ts`
- TURN 服务器资源消耗低（仅转发数据）
- 完全自主可控

**缺点**：
- 需要自建 TURN 服务器
- 需要自建信令服务器

**成本估算**：
- 信令服务器：最低配 VPS（1核1G）约 ¥30/月
- TURN 服务器：按流量计费，或与信令共用

---

### 3.2 方案二：LiveKit

```
┌─────────────┐                          ┌─────────────┐
│   Desktop   │◄────────────────────────►│  LiveKit    │
│  (服务端)    │        Room              │   Server    │
└─────────────┘                          └──────┬──────┘
                                                │
                                         ┌──────▼──────┐
                                         │   客户端     │
                                         └─────────────┘
```

**优点**：
- 开箱即用，连接成功率高（内置 TURN）
- 支持多人房间
- 有完善的 SDK

**缺点**：
- **过重**：包含完整的音视频模块（你不需要）
- **依赖**：需要部署 LiveKit Server 或使用 LiveKit Cloud
- **成本**：LiveKit Cloud 按分钟计费，自建需要较高配置服务器
- **复杂度**：引入额外的概念（Room、Participant、Track）

**结论**：对于纯文件传输场景，LiveKit 确实太重了。

---

### 3.3 方案三：使用 Cloudflare Calls（新兴方案）

Cloudflare 提供的 WebRTC 服务，内置 TURN：
- 优点：全球边缘节点，延迟低
- 缺点：目前仍在 Beta，API 可能变化

---

### 3.4 方案对比总结

| 维度 | 纯 WebRTC + TURN | LiveKit | Cloudflare Calls |
|------|------------------|---------|------------------|
| 轻量程度 | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| 连接可靠性 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 自主可控 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| 部署复杂度 | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| 月成本 | ¥30-100 | ¥100-500 | 按用量 |
| 适合场景 | 文件传输 | 音视频+文件 | 通用 |

**推荐方案**：**纯 WebRTC + 自建 coturn**

---

## 四、推荐方案详细设计

### 4.1 系统架构

```
                                    ┌──────────────────┐
                                    │   公网 VPS       │
                                    │  ┌────────────┐  │
                                    │  │ 信令服务器  │  │
                                    │  │ (WebSocket)│  │
                                    │  └────────────┘  │
                                    │  ┌────────────┐  │
                                    │  │  coturn    │  │
                                    │  │ (TURN/STUN)│  │
                                    │  └────────────┘  │
                                    └────────┬─────────┘
                                             │
              ┌──────────────────────────────┼──────────────────────────────┐
              │                              │                              │
              ▼                              ▼                              ▼
    ┌─────────────────┐            ┌─────────────────┐            ┌─────────────────┐
    │    Desktop      │◄──────────►│     手机        │◄──────────►│     网页        │
    │   (Windows/Mac) │   P2P/TURN │    (PWA)        │   P2P/TURN │   (Browser)     │
    │                 │            │                 │            │                 │
    │  📁 存储目录     │            │                 │            │                 │
    └─────────────────┘            └─────────────────┘            └─────────────────┘
```

### 4.2 核心模块设计

#### 4.2.1 Desktop 端（服务端）

```typescript
// 核心功能模块
interface DesktopService {
  // 文件系统
  fileManager: {
    setStorageDir(path: string): void
    listFiles(dir?: string): FileInfo[]
    readFile(path: string): ReadableStream
    writeFile(path: string, stream: ReadableStream): void
    deleteFile(path: string): void
    watchChanges(): Observable<FileChange>
  }
  
  // WebRTC 连接管理
  connectionManager: {
    onClientConnect(handler: (client: PeerConnection) => void): void
    broadcastFileChange(change: FileChange): void
  }
  
  // 系统集成
  systemIntegration: {
    enableAutoStart(): void
    minimizeToTray(): void
    showNotification(msg: string): void
  }
}
```

#### 4.2.2 信令服务器

```typescript
// 信令协议
interface SignalingMessage {
  type: 'register' | 'connect' | 'offer' | 'answer' | 'ice-candidate'
  from: string      // 设备 ID
  to?: string       // 目标设备 ID
  payload: any      // SDP 或 ICE candidate
}

// 设备注册
interface DeviceRegistry {
  deviceId: string
  deviceName: string
  publicKey: string  // 用于端到端加密
  online: boolean
  lastSeen: Date
}
```

#### 4.2.3 ICE 服务器配置

```typescript
const iceServers: RTCIceServer[] = [
  // 公共 STUN（免费）
  { urls: 'stun:stun.l.google.com:19302' },
  { urls: 'stun:stun.cloudflare.com:3478' },
  
  // 自建 TURN（兜底）
  {
    urls: 'turn:your-server.com:3478',
    username: 'user',
    credential: 'password'
  },
  {
    urls: 'turns:your-server.com:5349',  // TLS
    username: 'user',
    credential: 'password'
  }
]
```

### 4.3 通信协议设计

#### 4.3.1 DataChannel 消息协议

```typescript
// 消息类型
type MessageType = 
  | 'file-list-request'    // 请求文件列表
  | 'file-list-response'   // 文件列表响应
  | 'file-download-request'// 下载文件请求
  | 'file-upload-request'  // 上传文件请求
  | 'file-chunk'           // 文件分块数据
  | 'file-complete'        // 传输完成
  | 'sync-request'         // 同步请求
  | 'sync-diff'            // 同步差异

interface Message {
  id: string
  type: MessageType
  payload: any
  timestamp: number
}

// 文件信息
interface FileInfo {
  path: string
  name: string
  size: number
  mtime: number      // 修改时间
  hash?: string      // 用于增量同步
  isDirectory: boolean
}
```

#### 4.3.2 文件传输流程

```
Client                          Desktop
   │                               │
   │──── file-download-request ───►│
   │     { path: '/photos/1.jpg' } │
   │                               │
   │◄─── file-chunk ───────────────│
   │     { index: 0, data: ... }   │
   │                               │
   │◄─── file-chunk ───────────────│
   │     { index: 1, data: ... }   │
   │                               │
   │◄─── file-complete ────────────│
   │     { hash: 'abc123' }        │
   │                               │
```

### 4.4 安全设计

```typescript
// 1. 设备配对（首次连接）
interface DevicePairing {
  // 生成配对码（6位数字）
  generatePairingCode(): string
  
  // 验证配对码
  verifyPairingCode(code: string): boolean
  
  // 交换公钥
  exchangePublicKeys(): Promise<void>
}

// 2. 端到端加密（可选）
interface E2EEncryption {
  encrypt(data: ArrayBuffer, publicKey: CryptoKey): Promise<ArrayBuffer>
  decrypt(data: ArrayBuffer, privateKey: CryptoKey): Promise<ArrayBuffer>
}

// 3. 访问控制
interface AccessControl {
  // 允许的客户端列表
  allowedDevices: string[]
  
  // 只读/读写权限
  permissions: Map<string, 'read' | 'write'>
}
```

---

## 五、开发步骤

### 阶段一：基础设施（1-2 周）

- [ ] **1.1 部署信令服务器**
  - 使用 Node.js + ws 库
  - 实现设备注册、SDP/ICE 转发
  - 部署到 VPS

- [ ] **1.2 部署 coturn TURN 服务器**
  ```bash
  # Ubuntu 安装
  sudo apt install coturn
  
  # 配置 /etc/turnserver.conf
  listening-port=3478
  tls-listening-port=5349
  realm=your-domain.com
  server-name=your-domain.com
  lt-cred-mech
  user=username:password
  ```

- [ ] **1.3 更新 ICE 配置**
  - 修改 `publicStunList.ts`，添加 TURN 服务器

### 阶段二：Desktop 服务端（2-3 周）

- [ ] **2.1 文件系统模块**
  - 存储目录选择 UI
  - 文件列表 API
  - 文件读写流
  - 文件变更监听（chokidar）

- [ ] **2.2 WebRTC 服务端**
  - 复用 `PeerDataChannel.ts`
  - 实现多客户端连接管理
  - 实现消息协议处理

- [ ] **2.3 系统集成**
  - 系统托盘
  - 开机自启
  - 后台运行

### 阶段三：客户端（2-3 周）

- [ ] **3.1 Web 客户端**
  - 复用现有 FastSend 代码
  - 添加文件浏览 UI
  - 添加上传/下载功能

- [ ] **3.2 移动端 PWA**
  - 响应式设计
  - 离线缓存
  - 添加到主屏幕

### 阶段四：增强功能（2-3 周）

- [ ] **4.1 设备配对与安全**
  - 配对码机制
  - 设备管理 UI

- [ ] **4.2 文件同步**
  - 增量同步算法
  - 冲突处理

- [ ] **4.3 优化**
  - 断点续传
  - 传输进度
  - 错误重试

---

## 六、技术栈总结

| 层级 | 技术 |
|------|------|
| Desktop | Electron + React + TypeScript |
| Web 客户端 | Nuxt 3 / Vue 3 (复用现有) |
| 信令服务器 | Node.js + WebSocket |
| TURN 服务器 | coturn |
| 文件监听 | chokidar |
| 数据传输 | WebRTC DataChannel |
| UI 组件 | shadcn-ui / PrimeVue |

---

## 七、风险与应对

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| NAT 穿透失败 | 无法 P2P | TURN 服务器兜底 |
| TURN 带宽成本 | 费用增加 | 优先 P2P，大文件压缩 |
| Desktop 离线 | 无法访问 | 提示用户，支持离线缓存 |
| 安全风险 | 数据泄露 | 配对验证 + 可选 E2E 加密 |

---

## 八、文件分享模块设计（重新设计）

### 8.1 架构概述

文件分享功能采用 **服务端中转 + WebRTC P2P** 的混合架构：

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FastSend 服务端                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │   分享页面       │    │   分享记录存储   │    │   信令服务      │         │
│  │  /share/{code}  │    │  (设备码+分享码) │    │   (WebSocket)   │         │
│  └────────┬────────┘    └────────┬────────┘    └────────┬────────┘         │
└───────────┼─────────────────────┼─────────────────────┼────────────────────┘
            │                      │                      │
            │ HTTP                 │ 查询                 │ 信令
            ▼                      ▼                      ▼
┌─────────────────┐         ┌─────────────────┐    ┌─────────────────┐
│   浏览器用户     │◄───────►│   Desktop A     │◄──►│   Desktop B     │
│  访问分享链接    │  WebRTC │  (设备码: ABC)   │    │  (设备码: XYZ)   │
└─────────────────┘   P2P   │  📁 存储目录     │    │  📁 存储目录     │
                            └─────────────────┘    └─────────────────┘
```

**核心设计原则：**
1. **Desktop 端不提供 HTTP 服务** - 所有 HTTP 服务由 FastSend 服务端提供
2. **设备码（Device ID）** - 唯一标识每个 Desktop 客户端
3. **分享码（Share Code）** - 用于查找对应设备上的文件
4. **WebRTC P2P 传输** - 文件数据通过 WebRTC DataChannel 直接传输

### 8.2 数据结构

```typescript
// ==================== 服务端存储（仅设备信息） ====================

// 设备在线状态（服务端内存，不持久化）
interface DeviceConnection {
  deviceId: string;        // 设备唯一标识（UUID）
  deviceName: string;      // 设备名称（用户自定义）
  ws: WebSocket;           // WebSocket 连接实例
  lastHeartbeat: number;   // 最后心跳时间
}

// 服务端维护的映射关系（内存）
// deviceConnections: Map<deviceId, DeviceConnection>
// 注意：不需要存储 shareCode 映射，deviceId 直接编码在分享链接中

// ==================== Desktop 端存储（完整分享信息） ====================

// 本地分享记录（Desktop 存储，持久化到 shares.json）
interface ShareRecord {
  shareCode: string;       // 分享码（8位，如 A1B2C3D4）
  path: string;            // 文件相对路径
  fileName: string;        // 文件名
  size: number;            // 文件大小
  passwordHash: string | null; // SHA256 哈希后的密码
  createdAt: number;       // 创建时间戳
  expiresAt: number | null;// 过期时间
}

// 设备配置（Desktop 存储，持久化到 device-config.json）
interface DeviceConfig {
  deviceId: string;        // 设备唯一标识（首次启动时生成）
  deviceName: string;      // 设备名称（默认为计算机名）
  createdAt: number;       // 创建时间戳
}
```

**设计原则：**
- **服务端无状态**：不存储分享记录，只维护设备在线状态和分享码→设备ID的映射
- **Desktop端持有完整数据**：分享记录、密码哈希、文件路径等敏感信息都在本地
- **隐私保护**：服务端不知道用户分享了什么文件，只知道"某个分享码属于某个设备"

### 8.3 分享流程

#### 8.3.1 创建分享（Desktop 端）

```
用户                    Desktop                   FastSend 服务端
 │                         │                            │
 │── 右键文件 → 分享 ──────►│                            │
 │                         │                            │
 │                         │── 本地生成分享码 ──────────│
 │                         │   (8位随机码)              │
 │                         │                            │
 │                         │── 本地存储分享记录 ────────│
 │                         │   (shareCode → 文件路径、  │
 │                         │    密码哈希、过期时间)     │
 │                         │                            │
 │◄── 显示分享链接 ─────────│                            │
 │    https://fastsend.com/share/{deviceId}/A1B2C3D4   │
 │                         │                            │
 │    （无需上报服务端，deviceId 已在链接中）           │
```

**简化点**：创建分享时完全本地操作，不需要与服务端通信。

#### 8.3.2 访问分享（浏览器用户）

```
浏览器用户              FastSend 服务端              Desktop
    │                         │                         │
    │── GET /share/{deviceId}/A1B2C3D4 ───────────────►│
    │                         │                         │
    │◄── 分享页面 HTML ────────│                         │
    │   (通用下载页面)         │                         │
    │                         │                         │
    │── WebSocket 连接 ───────►│                         │
    │   { type: 'connect',    │                         │
    │     deviceId }          │                         │
    │                         │                         │
    │                         │── 根据 deviceId 查找 ──│
    │                         │   设备是否在线          │
    │                         │                         │
    │                    [如果 Desktop 离线]            │
    │◄── { type: 'error',     │                         │
    │      code: 'OFFLINE' }  │                         │
    │   显示"设备离线"提示     │                         │
    │                         │                         │
    │                    [如果 Desktop 在线]            │
    │◄─────────────── WebRTC 信令交换 ─────────────────►│
    │                         │  (服务端只转发信令)      │
    │                         │                         │
    │◄═══════════════ WebRTC P2P 连接建立 ════════════►│
    │                         │                         │
    │   ════════════ 以下全部走 P2P ════════════        │
    │                         │                         │
    │── { type: 'share-request', shareCode } ─────────►│
    │                         │                         │
    │                         │   Desktop 本地查找分享  │
    │                         │                         │
    │                    [如果分享不存在]               │
    │◄── { type: 'error', code: 'NOT_FOUND' } ─────────│
    │                         │                         │
    │                    [如果分享存在]                 │
    │◄── { type: 'share-info', fileName, fileSize, ────│
    │      hasPassword }      │                         │
    │                         │                         │
    │   [如果需要密码]         │                         │
    │── { type: 'share-verify', password } ───────────►│
    │                         │                         │
    │                         │   Desktop 验证密码      │
    │                         │                         │
    │◄── { type: 'verify-result', success } ──────────│
    │                         │                         │
    │   [验证通过后请求下载]   │                         │
    │── { type: 'download-start' } ───────────────────►│
    │                         │                         │
    │◄══════════════ P2P 文件传输 ════════════════════│
    │   { type: 'file-chunk', data, ... }              │
    │   { type: 'file-done', hash }                    │
```

**设计优势**：
- 服务端只做两件事：检测设备在线 + 转发 WebRTC 信令
- 设备在线后，所有业务逻辑（分享验证、密码校验、文件传输）都走 P2P
- 服务端完全不知道分享内容，隐私性更好

### 8.4 离线处理

**核心限制：Desktop 必须在线才能传输文件**

这是 P2P 架构的固有特性，无法绕过。处理方式：

#### 8.4.1 用户体验优化

```
┌─────────────────────────────────────────────────────────┐
│                    📤 FastSend                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📄 document.pdf                                │   │
│  │  大小: 2.5 MB                                   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ⚠️ 分享者的设备当前离线                               │
│                                                         │
│  请联系分享者开启电脑，或稍后再试。                     │
│                                                         │
│  ┌─────────────────┐                                   │
│  │   🔄 重新检测    │                                   │
│  └─────────────────┘                                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 8.4.2 可选的增强方案（未来考虑）

| 方案 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| **邮件/推送通知** | Desktop 离线时，发送通知给分享者 | 用户体验好 | 需要用户绑定邮箱/推送服务 |
| **小文件缓存** | 小于 X MB 的文件临时缓存到服务端 | 离线也能下载 | 违背 P2P 初衷，增加服务端成本 |
| **预约下载** | 用户留下邮箱，Desktop 上线后自动发送下载链接 | 异步体验 | 实现复杂 |

**当前版本建议**：仅实现"离线提示 + 重新检测"，保持架构简单。

### 8.5 API 设计

#### 8.5.1 服务端（无 REST API，仅 WebSocket）

服务端不提供 REST API，所有通信通过 WebSocket 完成。服务端只需要：
- 维护设备在线状态（deviceId → WebSocket 映射）
- 转发 WebRTC 信令

| 端点 | 说明 |
|------|------|
| `/share/[deviceId]/[code]` | 分享下载页面（静态 HTML，通用模板） |
| `/api/connect` | WebSocket 信令端点 |

#### 8.5.2 WebSocket 信令协议（仅用于建立 P2P 连接）

服务端只负责：检测设备在线 + 转发 WebRTC 信令，不参与任何业务逻辑。

```typescript
// ==================== Desktop → 服务端 ====================

// 设备上线
{ type: 'device-online', deviceId: string, deviceName: string }

// 心跳
{ type: 'heartbeat' }

// WebRTC 信令（转发给浏览器）
{ type: 'offer', peerId: string, sdp: RTCSessionDescription }
{ type: 'ice-candidate', peerId: string, candidate: RTCIceCandidate }

// ==================== 服务端 → Desktop ====================

// 上线确认
{ type: 'device-online-ack', success: boolean }

// 有浏览器想连接（通知 Desktop 准备接收 WebRTC 连接）
{ type: 'peer-connect', peerId: string }

// WebRTC 信令（来自浏览器）
{ type: 'answer', peerId: string, sdp: RTCSessionDescription }
{ type: 'ice-candidate', peerId: string, candidate: RTCIceCandidate }

// ==================== 浏览器 → 服务端 ====================

// 请求连接设备
{ type: 'connect', deviceId: string }

// WebRTC 信令
{ type: 'answer', sdp: RTCSessionDescription }
{ type: 'ice-candidate', candidate: RTCIceCandidate }

// ==================== 服务端 → 浏览器 ====================

// 设备离线错误
{ type: 'error', code: 'OFFLINE', message: '分享者设备离线' }

// 设备在线，准备建立 P2P 连接
{ type: 'device-online' }

// WebRTC 信令（来自 Desktop）
{ type: 'offer', sdp: RTCSessionDescription }
{ type: 'ice-candidate', candidate: RTCIceCandidate }
```

#### 8.5.3 P2P DataChannel 协议（WebRTC 建立后）

所有业务逻辑通过 P2P DataChannel 直接通信，服务端不参与。

```typescript
// ==================== 浏览器 → Desktop ====================

// 请求分享信息
{ type: 'share-request', shareCode: string }

// 验证密码
{ type: 'share-verify', password: string }

// 开始下载
{ type: 'download-start' }

// ==================== Desktop → 浏览器 ====================

// 分享信息
{ type: 'share-info', fileName: string, fileSize: number, hasPassword: boolean }

// 分享不存在
{ type: 'error', code: 'NOT_FOUND', message: '分享不存在' }

// 分享已过期
{ type: 'error', code: 'EXPIRED', message: '分享已过期' }

// 密码验证结果
{ type: 'verify-result', success: boolean, error?: string }

// 文件传输（复用现有 PeerDataChannel 协议）
{ type: 'file-meta', fileName: string, fileSize: number, hash: string }
{ type: 'file-chunk', index: number, data: ArrayBuffer }
{ type: 'file-done', hash: string }
```

#### 8.5.4 Desktop 端 IPC API

| API | 输入 | 输出 | 说明 |
|-----|------|------|------|
| `getDeviceInfo` | `{}` | `{ deviceId, deviceName }` | 获取设备信息 |
| `setDeviceName` | `{ name }` | `{ success }` | 设置设备名称 |
| `createShare` | `{ path, password?, expiresIn? }` | `{ shareCode, shareUrl }` | 创建分享（纯本地操作） |
| `deleteShare` | `{ shareCode }` | `{ success }` | 删除分享（纯本地操作） |
| `listShares` | `{}` | `ShareRecord[]` | 列出本地分享 |
| `getConnectionStatus` | `{}` | `{ connected, deviceId }` | 获取与服务端的连接状态 |

### 8.6 设备码机制

#### 8.6.1 设备码生成

```typescript
// 首次启动时生成，存储在本地配置文件
function generateDeviceId(): string {
  return crypto.randomUUID(); // 如：550e8400-e29b-41d4-a716-446655440000
}

// 存储位置：{userData}/device-config.json
interface DeviceConfig {
  deviceId: string;
  deviceName: string;
  createdAt: number;
}
```

#### 8.6.2 设备在线状态维护

```typescript
// Desktop 启动时连接服务端 WebSocket
const ws = new WebSocket('wss://fastsend.com/api/connect');

ws.onopen = () => {
  // 发送设备上线消息
  ws.send(JSON.stringify({
    type: 'device-online',
    deviceId: config.deviceId,
    deviceName: config.deviceName
  }));
  
  // 定期心跳
  setInterval(() => {
    ws.send(JSON.stringify({ type: 'heartbeat' }));
  }, 30000);
};
```

### 8.7 安全设计

1. **设备认证**
   - 设备码为 UUID，难以猜测
   - 可选：设备首次注册时生成密钥对，后续通信签名验证

2. **分享密码**
   - 密码在 Desktop 端使用 SHA256 哈希存储
   - 验证时在 Desktop 端进行，服务端不存储密码

3. **路径安全**
   - 分享的文件必须在存储目录内
   - 使用 `path.resolve` + 前缀检查防止路径穿越

4. **过期机制**
   - 分享可设置过期时间
   - 服务端和 Desktop 端双重检查

5. **传输安全**
   - WebRTC DataChannel 默认使用 DTLS 加密
   - 可选：端到端加密（使用设备公钥）

### 8.8 文件位置

```
FastSend/server/
├── api/
│   └── connect.ts           # WebSocket 信令（需扩展，处理设备和分享）
├── pages/
│   └── share/
│       └── [code].vue       # 分享下载页面（通用模板）
└── utils/
    └── deviceStore.ts       # 设备在线状态管理（内存）

fast_send_desktop/src/
├── main/
│   └── device-manager.ts    # 设备管理（ID生成、WebSocket连接、分享上报）
├── ipc/
│   ├── device/
│   │   ├── handlers.ts      # 设备相关 IPC
│   │   └── index.ts
│   └── share/
│       ├── handlers.ts      # 分享相关 IPC（已有，需修改）
│       └── index.ts
└── components/cloud/
    └── share-dialog.tsx     # 分享对话框（需修改）
```

### 8.9 分享链接格式

```
https://fastsend.com/share/{deviceId}/{shareCode}

示例：https://fastsend.com/share/550e8400-e29b-41d4-a716-446655440000/A1B2C3D4
```

**设计优势**：
- deviceId 在链接中，服务端无需维护分享码映射
- 创建分享完全本地操作，无需网络请求
- 服务端更简单，只需维护设备在线状态

用户访问此链接后：
1. 服务端返回通用分享页面
2. 页面通过 WebSocket 连接服务端，带上 deviceId 和 shareCode
3. 服务端转发请求给对应 Desktop，Desktop 返回文件信息
4. 用户点击下载，建立 WebRTC 连接，P2P 传输文件

### 8.10 实现步骤

#### 阶段一：服务端扩展（FastSend）
- [ ] 扩展 `connect.ts` WebSocket 信令，支持：
  - 设备上线/离线管理（deviceId → WebSocket 映射）
  - 分享请求转发（根据 URL 中的 deviceId 找到设备）
  - WebRTC 信令转发
- [ ] 创建 `deviceStore.ts` 管理设备在线状态
- [ ] 创建分享下载页面 `/share/[deviceId]/[code].vue`

#### 阶段二：Desktop 端修改
- [ ] 实现 `device-manager.ts` 设备管理模块：
  - 首次启动生成设备码（UUID）
  - 启动时连接服务端 WebSocket 并注册设备
  - 处理来自服务端的分享请求
- [ ] 修改分享功能：
  - 本地生成分享码并存储
  - 生成包含 deviceId 的分享链接
  - 处理分享请求，建立 WebRTC 连接发送文件

#### 阶段三：已完成 ✅
- [x] 删除 `share-server.ts`（本地 HTTP 服务）
- [x] 简化分享对话框

---

## 九、结论

**方案可行**。推荐使用 **纯 WebRTC + 自建 coturn** 方案：

1. **轻量**：不引入 LiveKit 等重型框架，只用 DataChannel
2. **可靠**：STUN + TURN 组合，覆盖各种网络环境
3. **可复用**：现有 `PeerDataChannel.ts` 可直接使用
4. **成本低**：一台低配 VPS 即可运行信令 + TURN

预计开发周期：**6-10 周**（单人全职）
