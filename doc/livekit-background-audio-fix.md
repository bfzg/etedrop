# LiveKit 后台音频断连问题修复

## 问题现象

应用切到后台后，LiveKit 连接立即断开，无法继续接收音频。即使手动注释掉断开逻辑，连接仍然会在数秒内因系统回收而中断。

## 根因分析

### 1. 代码层面：主动断开连接

`lib/pages/room/index.dart` 中的生命周期监听，在 `AppLifecycleState.paused`（进入后台）时主动调用了 `leaveCurrentRoom()`，直接断开了 LiveKit 连接。

### 2. Android 层面：缺少音频类型前台服务

Android 系统对后台进程有严格限制。如果应用没有声明 `mediaPlayback` 类型的前台服务，系统会认为该应用不需要在后台播放音频，从而暂停或杀死其网络连接和 WebRTC 进程。

原先的前台服务只声明了 `dataSync|phoneCall`，缺少 `mediaPlayback` 和 `microphone`。

### 3. iOS 层面：后台模式不完整

`Info.plist` 只声明了 `audio` 后台模式，缺少 `voip` 模式。WebRTC 属于 VoIP 通信，需要 `voip` 后台模式才能在后台保持 PeerConnection 的心跳和数据传输。

### 4. 没有配置 AudioSession

系统不知道应用的音频使用意图。没有通过 `AudioSession` 告知系统"这是一个语音通话应用，需要后台持续运行"，系统会按普通应用处理，后台时暂停音频通道。

## 抖音/QQ 音乐/B 站/Soul 的做法

这些应用后台能持续播放音频，核心依赖三点：

- **Android**：前台服务 + `foregroundServiceType="mediaPlayback"` → 系统不杀音频进程
- **iOS**：`UIBackgroundModes: audio/voip` + 正确的 `AVAudioSession` 配置 → 系统允许后台音频
- **不主动断开连接**：后台时保持 WebRTC/音频连接，仅在回到前台时检测是否需要恢复

## 修复方案

### 修改 1：不再后台主动断开 LiveKit

**文件**：`lib/pages/room/index.dart`

将 `paused` 时断开连接的逻辑改为保持连接，仅在 `resumed` 时检查连接状态，如果已断开则重连。

### 修改 2：Android 添加 mediaPlayback 前台服务

**文件**：`android/app/src/main/AndroidManifest.xml`

- 新增权限：`FOREGROUND_SERVICE_MEDIA_PLAYBACK`、`FOREGROUND_SERVICE_MICROPHONE`
- 更新 `BackgroundService` 的 `foregroundServiceType` 为 `dataSync|phoneCall|mediaPlayback|microphone`

### 修改 3：iOS 添加 voip 后台模式

**文件**：`ios/Runner/Info.plist`

`UIBackgroundModes` 新增 `voip` 和 `fetch`。

### 修改 4：配置 AudioSession

**文件**：`lib/provider/livekit/livekit_provider.dart`

新增 `_configureAudioSession()` 方法，在 LiveKit 初始化时配置：

- **iOS**：`AVAudioSessionCategory.playAndRecord` + `voiceChat` 模式 + 允许蓝牙/扬声器/混音
- **Android**：`voiceCommunication` 用途 + `speech` 内容类型 + 允许被 duck 时不暂停

### 修改 5：更新后台服务类型

**文件**：`lib/services/background_service.dart`

`foregroundServiceTypes` 新增 `AndroidForegroundType.mediaPlayback` 和 `AndroidForegroundType.microphone`。

### 修改 6：添加后台自动重连机制

**文件**：`lib/provider/livekit/livekit_provider.dart`

- 监听 `RoomReconnectingEvent` / `RoomReconnectedEvent`，利用 LiveKit 自带重连机制
- 新增 `_attemptBackgroundReconnect()`：连接断开时自动尝试 5 次重连（间隔递增 2s/4s/6s/8s/10s）
- 保存 `_lastUrl` / `_lastToken` 供后台重连使用

### 修改 7：新增依赖

**文件**：`pubspec.yaml`

新增 `audio_session` 包。

## 注意事项

- 国产 Android 手机可能需要用户手动关闭电池优化、允许后台自启动
- iOS 使用 `voip` 后台模式时，App Store 审核会检查是否确实有 VoIP 功能（本应用有语音通话，合理使用）
- 测试务必使用真机，模拟器的后台行为不准确
