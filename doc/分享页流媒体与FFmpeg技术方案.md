# 分享页流媒体与 FFmpeg 技术方案

## 文档信息

| 项目 | 说明 |
|------|------|
| 关联能力 | 公网分享页在浏览器内**可拖动进度条**的在线播放；桌面/移动端作为分享发起端 |
| 传输层 | 沿用现有 **WebRTC DataChannel**（信令不经视频字节） |
| 媒体处理 | 发起端优先使用 **裁剪版 FFmpeg**（随桌面端打包，`Process` 调用）或 **FFmpegKit**（移动端/部分桌面端）执行 **remux→fMP4**；尽量 **copy**，不默认转码 |
| 修订依据 | 产品结论：H.265 **不强制**转 H.264；以**浏览器能否解码**为准；**容器**需调整为 Web / MSE 友好形态（如 **fMP4**）时再处理 |

---

## 一、FFmpegKit 说明与仓库状态

### 1.1 是否为「ffmpegkit」

用户提供的仓库路径  
`https://github.com/arthenica/ffmpeg-kit/tree/main/flutter/flutter`  
即为 **FFmpegKit** 工程中的 **Flutter 插件子目录**，发布包名一般为 **`ffmpeg_kit_flutter`**（及带后缀变体如 `ffmpeg_kit_flutter_min`、`ffmpeg_kit_flutter_min_gpl` 等）。

典型用法为 Dart 代码调用，例如：

```dart
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

FFmpegKit.executeAsync('-i <input> ... <output>', ...);
```

与「单独分发一个 `ffmpeg` 可执行文件再在进程里 `Process.run`」相比，**FFmpegKit 把原生库与统一 API 封装进 App**，由 **`FFmpegKit.execute` / `executeAsync`** 驱动，**调用方式在客户端侧以代码为主**，无需用户手动安装 FFmpeg。

### 1.2 维护状态风险（须在立项时知晓）

官方仓库 **FFmpegKit 已于 2025-06-23 被标记为 Archived（只读）**（见 GitHub 仓库页提示）。  

**对项目的影响与对策：**

- **短期**：仍可锁定 **已发布 pub 版本**（如文档编写时常见的 `6.0.3` / `6.0.3-LTS`）继续使用；需自行承担**安全补丁与 FFmpeg 上游升级**滞后风险。
- **中期**：评估 **社区 Fork**、**自维护 AAR/Framework 裁剪构建**，或 **Flutter 侧仅保留「命令 + 二进制」抽象**以便替换底层实现。
- 本方案下文所述「FFmpeg 命令与能力裁剪」与具体载体（FFmpegKit 或 自研 FFI）**解耦**，便于迁移。

---

## 二、需求摘要（已对齐产品结论）

| 维度 | 结论 |
|------|------|
| **H.265 / HEVC** | **不默认**转码为 H.264；**若当前浏览器可解码 HEVC**（与 OS/浏览器版本强相关），则以 **copy** 为主，由**前端播放器能力**决定是否可播。 |
| **转码触发条件** | 当**容器或封装**不适合 MSE / `<video>` 管线（如需 **fragmented MP4**）、或**音/视频编码**在目标浏览器上**明确不可播**时，再在发起端做 **有限转码或重封装**。 |
| **容器目标** | 以 **fMP4（fragmented MP4）** 作为与 **Web MSE** 对接的首选封装；命令层使用 FFmpeg 的 **movflags** 等参数生成适合 **appendBuffer** 的比特流。 |
| **GPL** | **能播且可 copy/remux 完成的链路优先**，避免绑定 **libx264** 等 GPL 组件；仅当必须软件编码 H.264 等场景再引入 **GPL 变体包**（如 `*_gpl`），并走合规评审。 |
| **平台** | **Android、iOS、macOS** 与 **FFmpegKit 官方 Flutter 支持范围一致**；**Windows、Linux（Flutter 桌面）** 需在实现阶段核对 **pub.dev 平台标签**；若官方未覆盖，采用 **独立裁剪 `ffmpeg` 二进制 + `Process` / FFI** 与 **统一 Dart 抽象层** 对齐（见第六节）。 |
| **调用方式** | 采用 **FFmpegKit 的 Dart API**（`execute` / `executeAsync` / `cancel`），不在此方案中再引入「用户本机安装 FFmpeg」。 |

---

## 二点五、当前仓库落地状态（2026-03）

### 2.5.1 已有裁剪产物与放置位置

仓库已存在裁剪产物目录：

- `ffmpeg_build/mac/ffmpeg`、`ffmpeg_build/mac/ffprobe`
- `ffmpeg_build/windows/ffmpeg.exe`、`ffmpeg_build/windows/ffprobe.exe`

已将产物复制到 Flutter 工程 assets（用于随桌面端打包与运行时解包）：

- `fast_send_flutter/assets/ffmpeg/macos/ffmpeg`
- `fast_send_flutter/assets/ffmpeg/macos/ffprobe`
- `fast_send_flutter/assets/ffmpeg/windows/ffmpeg.exe`
- `fast_send_flutter/assets/ffmpeg/windows/ffprobe.exe`

并在 `fast_send_flutter/pubspec.yaml` 增加了 `assets/ffmpeg/` 资源路径。

### 2.5.2 运行时封装

Flutter 侧已新增封装（桌面端）：

- `fast_send_flutter/lib/core/utils/ffmpeg_bundle.dart`：从 assets 解包到 `ApplicationSupport/ffmpeg`，macOS 下设置可执行权限
- `fast_send_flutter/lib/core/utils/ffmpeg_runner.dart`：提供 `remuxToFragmentedMp4()`（`-c copy` + `movflags` 输出 fMP4 文件）

并在 `ShareP2PHandler` 增加可选 remux 开关：当 DataChannel 收到 `download-start` 且 `remuxFmp4: true` 时，优先 remux 输出 `.mp4`（fMP4）再按现有文件下载协议发送；失败则自动降级为原文件直传。

### 2.5.3 Web 端配合（share-page-app）

已在分享页增加“**在线播放**”能力（仍走 DataChannel 拉取文件，但下载完成后在页面内播放）：  

- `share-page-app/src/pages/SharePageView.tsx`：当文件扩展名推断为视频时展示“在线播放（浏览器兼容时）”按钮与 `<video controls>` 播放区
- `share-page-app/src/hooks/useSharePage.ts`：`sendDownloadStart({ intent: 'play', remuxFmp4: true })` 会在 `download-start` 消息中附带 `remuxFmp4: true`，并在收完 `Blob` 后生成 `blob:` URL 注入播放器，而不是触发保存下载

注意：该实现当前是“**先传完再播（Blob 播放）**”，不是 MSE 的分段边下边播；但它验证了“Web 端需要与 desktop 端 remux 协作才能更稳播放”的联动链路（尤其是需要 fMP4 的情况）。

### 2.5.4 边推边播（MSE）实现（P0+）

已新增一条“**stream 模式**”用于边推边播（不依赖完整下载）：  

- Web 端：点击“播放”会发送 `stream-start`，并初始化 `MediaSource + SourceBuffer`，将 DataChannel 二进制帧按到达顺序 `appendBuffer`
- Desktop 端：收到 `stream-start` 后使用裁剪版 FFmpeg 执行 `-c copy` + `movflags`，将 fragmented MP4 输出到 `pipe:1`，再经 DataChannel 持续发送二进制数据；结束时发送 `stream-done`

当前限制：SourceBuffer MIME 固定为 `video/mp4; codecs=\"avc1.42E01E, mp4a.40.2\"`，因此只保证 **H.264/AAC** 场景可靠；后续可通过 `stream-meta` 携带 codec 信息做动态协商。

### 2.5.5 最稳定分段协议（init-segment-v1）

为避免浏览器对 MP4 分段边界敏感导致的 `DEMUXER_ERROR_COULD_NOT_OPEN`，引入**显式分段二进制协议**：  

- 控制消息：`stream-meta.binaryMode = \"init-segment-v1\"`
- 二进制帧：`[kind:1byte][payload...]`
  - `kind=0`：init segment（应包含 `ftyp+moov` 及 moof 前所有 header box），web 端必须先 append
  - `kind=1`：media segment（以 `moof` 起头，包含随后 `mdat` 等）

发送端（Flutter/desktop）从 FFmpeg `pipe:1` 输出中按 MP4 box 切分，确保 init/segment 边界正确；接收端（web）按 kind 直接追加，无需再猜测 box 边界，稳定性最高。

## 三、总体架构

### 3.1 数据路径（逻辑）

```
┌─────────────────────────────────────────────────────────────────┐
│ 分享发起端（Flutter：Android / iOS / macOS / Win / Linux）        │
│  1. 用户选取网盘文件                                                │
│  2. 媒体管线判定：copy remux → fMP4 片段 / 或有限转码               │
│  3. FFmpeg（FFmpegKit 或平台二进制）输出连续字节或分片                │
│  4. 经现有 ShareP2P / DataChannel 协议发送                          │
└────────────────────────────┬────────────────────────────────────┘
                             │ WebRTC DC（二进制 + JSON 控制）
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 分享页（share-page-app）                                          │
│  MediaSource + SourceBuffer 消费 fMP4                             │
│  <video>：进度条 / currentTime / seek                            │
│  seek 时 DC 回传「从新时间点重定位」→ 发起端重启 FFmpeg 段           │
└─────────────────────────────────────────────────────────────────┘
```

**信令服务器（fast_send_server）**：仍仅承担 **WebSocket 信令 + 静态 SPA**；**视频流不经过服务端**（除非未来单独做中继，不在本文范围）。

### 3.2 与「仅整文件下载」的关系

- **保留**现有 `download-start` **整文件下载**能力，作为兼容与小文件场景。
- **新增**「**流媒体会话**」：独立子状态机（`stream-init` / `stream-segment` / `seek` / `stream-abort`），避免与现有 offset 续传语义互相干扰（具体消息名在接口设计中再冻结）。

---

## 四、浏览器侧技术方案（share-page-app）

### 4.1 MSE + fMP4

- 使用 **`MediaSource` + `SourceBuffer('video/mp4; codecs="avc1.…, mp4a.…"` 或含 hev1/hvc1 等)**，按发起端协议**追加 init segment 与 media segment**。
- **HEVC**：`SourceBuffer` 的 codecs 字符串与**当前浏览器是否实现 HEVC MSE**强相关；不可用时 **Feature detect** 失败则提示「请下载到本地播放」或走发起端降级（若产品允许再讨论转码）。

### 4.2 进度条与 seek

- **缓冲区内 seek**：原生 `<video>` 行为。
- **缓冲区未覆盖目标时间**：向 DataChannel 发送 **`seek`（建议携带 `targetTimeSec` 或规范化的 `targetPts`）**；发起端 **终止当前输出**，从 **关键帧前**重新 demux/remux（FFmpeg `-ss` 配合输出策略），再发送 **新的 init（如需要）+ 后续 fragment**；网页侧 **`sourceBuffer.remove()`** 清理过时区间或使用 **追加新 timeline** 策略（实现阶段选一种并写死，避免缓冲无限增长）。

### 4.3 前端职责边界

- **能播与否**：以前端 **`MediaSource.isTypeSupported` + 解码错误事件**为准；**不因「文件名是 .mp4」就假定可播**。

---

## 五、发起端技术方案（Flutter + FFmpeg）

### 5.1 FFmpegKit 包选型（与 GPL）

| 场景 | 建议包方向 |
|------|------------|
| 多数 **copy + remux** 到 fMP4，无 libx264 | **min / video / https** 等非 GPL 组合（以 [Packages Wiki](https://github.com/arthenica/ffmpeg-kit/wiki/Packages) 为准） |
| 必须 **libx264 软件编码** | `*_min_gpl` / `*_full_gpl` 等，**引入前法务确认** |

**原则**：以 **能否在浏览器解码** 为判据；**能 copy 则不动编码**，减小包体与专利/许可风险。

### 5.2 能力矩阵（逻辑功能，非具体命令）

| 功能 | FFmpeg 侧 | 说明 |
|------|-----------|------|
| 解复用 | `mov`, `matroska` 等按需开启 | 输入覆盖网盘常见格式时，build 裁剪时打开对应 **demuxer** |
| 复用 | `mp4` + fragmented | **MSE 友好** |
| 码流拷贝 | `-c copy` | **首选**；H.264/H.265/AAC 等在「浏览器可播」前提下保持原编码 |
| Seek | 进程级 **取消 + 重新 execute**（带 `-ss`） | 与 `FFmpegKit.cancel(sessionId)` 对齐 |
| 输出形态 | stdout 或分段写临时文件再读入 DC | 实现阶段二选一；需**背压**与 DC `bufferedAmount` 协同（沿用现有分片节流思路） |

### 5.3 与现有 `ShareP2PHandler` 的衔接

- 在 **不改变**现有「整文件顺序读取」逻辑的前提下，**新增**一条 **`StreamingSession`**：
  - 收到 Web **`stream-start`** 后启动 FFmpeg 输出；
  - 二进制帧可采用 **类型前缀**（init / media）或 **独立 JSON meta**，与现有 **8 字节 offset 文件块**区分，避免解析混淆。
- **seek**：停止当前 FFmpeg session → 新命令从估算关键帧处输出。

### 5.4 H.265 政策的技术落点

- **不**在方案层强制 **HEVC → AVC**。
- **发起端**在 **share-info 或独立 meta** 中可携带 **`codecs` / `mime` 提示**（可选），**前端**决定 MSE codecs 字符串与是否尝试播放。
- 若未来数据统计显示 **大量 Chrome + HEVC MSE 不可用**，可再增加 **「可选转码配置文件」**，不作为第一版必选项。

---

## 六、Windows / Linux（Flutter 桌面）补充策略

官方 README 对 **`ffmpeg_kit_flutter` 的明确支持列表**以 **Android、iOS、macOS** 为主（见 [FFmpegKit Flutter README](https://github.com/arthenica/ffmpeg-kit/tree/main/flutter/flutter)）。

**设计原则：**

1. **实现前**：在 `pub.dev` 核对所用版本的 **`platforms: windows: linux:`** 是否可用；若插件未提供实现，则：
   - **方案 A**：同仓库 **自定义 plugin** 复制 Android/iOS 的 **FFI 思路**，链接 **本仓库裁剪的 `ffmpeg` / `libffmpeg`**；
   - **方案 B**：随应用发布 **单文件裁剪 `ffmpeg` 可执行体**，`Process.start` 写入 pipe / 临时 fMP4 文件，**Dart 抽象接口**与 FFmpegKit 路径一致（`runRemux`、`cancel`）。

2. **文档与代码约束**：业务层只依赖 **`MediaPipeline` 抽象**（例如 `startStream(inputPath, options)` / `seek(t)` / `dispose()`），底层 **Android/iOS/macOS → FFmpegKit**，**Windows/Linux → 二进制或 FFI**，避免业务分叉。

---

## 七、FFmpeg 裁剪构建（与 FFmpegKit 的关系）

### 7.1 目标

在 **遵守产品功能** 前提下最小化体积：

- **必选**：`file` 协议、`mov/mp4` **demuxer**、**mp4 muxer**（fragmented）、`h264`/`hevc`/`aac` **parser**（随 demux 需求启用）、必要时 **matroska** 等。
- **可选**：仅在确认需要时再打开 **解码器/编码器/滤镜**；**禁止**默认打入全套编码器。

### 7.2 实施位置

- **使用官方预编译包**：选用 **`min`** 等变体已比 **`full`** 小；进一步裁剪需 **Fork FFmpegKit 构建脚本** 修改 `configure`。
- **自维护**：对 **Windows/Linux** 随包二进制，使用独立 **`configure --disable-everything` + 白名单 enable**（参见团队内《FFmpeg 裁剪》结论或运维文档）。

---

## 七点五、WebRTC 视频轨方案调研结论（2026-03，不可行）

曾评估过将 FFmpeg 产出的视频码流直接注入 WebRTC **video track（RTP）** 在浏览器端用 `<video srcObject>` 播放。经调研后明确放弃，原因：

1. **flutter_webrtc 无外部视频注入 API**：Dart 层面只有 `getUserMedia` / `getDisplayMedia` 两类采集源，没有 "从 FFmpeg pipe / raw H.264 创建 `MediaStreamTrack`" 的公开 API。实现需在 macOS/Windows 分别写 C++ / ObjC 原生层 fork 插件，工作量极大且长期维护成本高。
2. **浏览器 live `MediaStream` 无 VOD 交互**：`<video srcObject={stream}>` 播放实时流时，`duration` 为 `Infinity`，`currentTime` 不可任意设置，`playbackRate` 被忽略或 clamp——无法实现进度条拖拽、快进、倍速等 VOD 特性。
3. **项目零基础**：仓库 WebRTC 层面只有 DataChannel + 信令，没有任何 audio/video track 使用先例。

**最终方案**：沿用 **DataChannel + MSE（fMP4）**，在此基础上增强 seek / 倍速 / H.265 动态检测。

---

## 七点六、Seek 协议（stream-seek / stream-seeked）

### 消息定义

| 方向 | 消息类型 | 字段 | 说明 |
|------|----------|------|------|
| Web → Desktop | `stream-seek` | `targetTime: number`（秒） | 用户拖动进度条或点击到未缓冲的时间点 |
| Desktop → Web | `stream-seeked` | `actualTime: number`（秒） | FFmpeg 实际定位到的关键帧时间 |

### 全链路流程

1. **Web 端**：`<video>` 触发 `seeking` 事件 → 检查 `targetTime` 是否在已缓冲 (`buffered`) 范围内 → 不在则通过 DataChannel 发送 `stream-seek`
2. **Desktop 端**：收到 `stream-seek` → kill 当前 FFmpeg 进程 → 用 `-ss <targetTime>` 重启 FFmpeg（input seeking，快速定位最近关键帧）→ 发送 `stream-seeked` → 重发 init segment（kind=0）+ 后续 media segment（kind=1）→ 最终 `stream-done`
3. **Web 端**：收到 `stream-seeked` → `sourceBuffer.abort()` + `sourceBuffer.remove(0, Infinity)` 清空旧缓冲 → 重置 init/segment 解析状态 → 接收新 init + media segment 恢复播放

### FFmpeg `-ss` 放在输入侧

```
ffmpeg -ss 45.000 -i input.mp4 -c copy -movflags +frag_keyframe+empty_moov+default_base_moof -f mp4 pipe:1
```

`-ss` 在 `-i` 前面为 **input seeking**，FFmpeg 直接跳到最近的关键帧，速度极快（不需解码跳过的帧）。

---

## 七点七、倍速播放

**纯前端实现**，无需 Desktop 配合。

Web 端通过 `videoElement.playbackRate = rate` 设置倍速（0.5x / 1x / 1.5x / 2x）。MSE 的 `SourceBuffer` 在高倍速下会更快消耗缓冲区，当播放位置接近缓冲尾部时可能触发 seeking → 走上述 seek 协议补充数据。

UI 在视频播放器下方以按钮组形式提供倍速选择。

---

## 七点八、H.265 动态检测

### Desktop 端

- `ffprobe` 检测视频 codec：允许 `h264` 和 `hevc`（不再仅限 H.264）
- `stream-meta` 携带精确 `codecs` 字符串（H.264 → `avc1.42E01E`，H.265 → `hev1.1.6.L93.B0`）和 `duration`（秒）

### Web 端

- `pickSupportedMp4Mime` 候选列表包含 H.265 MIME（`hev1.*`、`hvc1.*`）和 H.264 MIME
- 根据 `stream-meta.mime` 优先匹配，`MediaSource.isTypeSupported` 动态判断
- 不支持时显示提示"该浏览器不支持 HEVC 编码，请下载播放"

### stream-meta 增强字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `mime` | `string` | 完整 MIME（如 `video/mp4; codecs="hev1.1.6.L93.B0, mp4a.40.2"`） |
| `codecs` | `string` | codec 部分（如 `hev1.1.6.L93.B0, mp4a.40.2`） |
| `duration` | `number` | 视频时长（秒），用于设置 `MediaSource.duration` |
| `binaryMode` | `string` | 二进制帧编码（`init-segment-v1`） |

---

## 八、风险与测试要点

| 风险 | 缓解 |
|------|------|
| FFmpegKit 归档 | 锁版本 + Fork/自研适配计划 |
| HEVC 在 Chrome MSE 不可用 | 前端检测 + 提示下载；产品统计后再议转码 |
| seek 卡顿 | FFmpeg `-ss` 放在 **输入侧**（较快关键帧）与 **输出 fragment 对齐**策略需在 PoC 验证 |
| DC 背压 | 与现有 **bufferedAmount** 节流一致；流媒体模式可能需更小 chunk |
| 多平台行为不一致 | **抽象层 + CI** 对 Android/iOS/macOS/Win/Linux 各跑一段 **固定样例文件** |
| macOS 沙盒禁止执行解包二进制 | **开发期**可关闭 `com.apple.security.app-sandbox` 验证链路；**正式版**建议将 `ffmpeg` 作为 app bundle 内置 helper（签名后执行），避免从 Application Support 动态解包执行 |

**测试样例建议**：H.264+AAC MP4、HEVC+AAC MP4（若需）、MKV 封装 H.264（remux）、音轨异常/无音轨。

---

## 九、交付物拆分（建议迭代）

| 阶段 | 内容 | 状态 |
|------|------|------|
| **P0** | 发起端 **copy → fMP4** 输出 + Web **MSE 顺序播放** + init-segment-v1 协议 + H.265 动态检测 + duration 传递 | **已实现** |
| **P1** | **seek 全链路**（stream-seek / stream-seeked / SourceBuffer reset）+ **倍速**（playbackRate UI）| **已实现** |
| **P2** | Windows/Linux **统一 MediaPipeline** + 裁剪 FFmpeg 体积优化 | 待做 |
| **P3** | 可选 **失败自动转码**（非 HEVC→H264 强制的其它编码兜底） | 待做 |

---

## 十、参考链接

- FFmpegKit Flutter 目录：[https://github.com/arthenica/ffmpeg-kit/tree/main/flutter/flutter](https://github.com/arthenica/ffmpeg-kit/tree/main/flutter/flutter)
- FFmpegKit Packages / 变体说明：仓库 Wiki（Packages、LTS）
- 项目内关联：`doc/WebRTC网盘与分享方案.md`、`doc/分享接口说明.md`（若需与信令字段对齐可在此文档后续追加「流媒体控制消息」附录）

---

**文档结束**
