# EteDrop / Fast Send Workspace

[English](./README.md)

EteDrop 是一个跨平台文件传输项目，包含 Flutter 客户端、NestJS 信令服务、文件分享页和  官网。项目目标是让手机、电脑、桌面端和浏览器之间可以更方便地传输文件，优先使用局域网和 WebRTC/P2P 等直接传输方式，服务端主要负责信令、分享页分发和运行状态接口。

## 项目背景

很多文件传输工具依赖云端中转，速度、隐私和大文件体验都会受到限制。EteDrop 的设计方向是：

- 局域网内尽量直接传输文件；
- 跨网络场景通过信令服务建立 WebRTC 连接；
- 接收方可以通过浏览器打开分享链接；
- 支持常见文件预览、下载和部分媒体播放/转码流程；
- 支持全球节点和中国大陆节点两套服务地址。

## 目录说明

| 路径 | 说明 |
| --- | --- |
| [fast_send_flutter/](./fast_send_flutter/) | Flutter 客户端，覆盖 Android、iOS、macOS、Windows、Linux。 |
| [fast_send_server/](./fast_send_server/) | NestJS 服务端，负责 WebSocket 信令、分享路由、静态分享页、健康检查和指标接口。 |
| [share-page-app/](./share-page-app/) | React/Vite 分享页，浏览器接收文件时打开。 |
| [website/](./website/) | Docusaurus 官网、下载页、博客和产品页面。 |
| [doc/](./doc/) | 架构、部署、打包、协议和开发计划文档。 |
| [ffmpeg_build/](./ffmpeg_build/) | FFmpeg/FFprobe 二进制文件，用于媒体相关流程。重新分发前请查看 [第三方声明](./THIRD_PARTY_NOTICES.md)。 |
| [images/](./images/) | 项目图片和辅助视觉资源。 |

## 可点击文档

- [服务端 README](./fast_send_server/README.md)
- [Flutter 客户端 README](./fast_send_flutter/README.md)
- [分享页 README](./share-page-app/README.md)
- [官网 README](./website/README.md)
- [服务器部署文档](./doc/服务器部署文档.md)
- [桌面端打包 DMG 与 EXE 教程](./doc/桌面端打包-DMG与EXE教程.md)
- [移动端打包 Android APK 与 iOS 安装包教程](./doc/移动端打包-Android APK与iOS安装包教程.md)
- [服务端架构总览](./doc/服务端架构总览.md)
- [信令协议说明](./doc/信令协议说明.md)
- [分享接口说明](./doc/分享接口说明.md)
- [第三方声明](./THIRD_PARTY_NOTICES.md)
- [安全策略](./SECURITY.md)
- [贡献说明](./CONTRIBUTING.md)
- [开源许可证](./LICENSE)

## 技术栈

- Flutter / Dart：多平台客户端。
- NestJS / TypeScript / `ws`：信令服务和 API 服务。
- React / Vite / Tailwind CSS / i18next：浏览器分享页。
- Docusaurus / React / TypeScript：官网。
- FFmpeg / FFprobe：部分媒体处理、播放和转码流程。

## 开发环境

根据要开发的子项目安装对应工具：

- Git
- Node.js 20 或更高版本
- npm
- Flutter SDK，Dart 版本需兼容 `^3.9.2`
- Android Studio 和 Android SDK，用于 Android 构建
- Xcode 和 CocoaPods，用于 iOS / macOS 构建
- CMake 和对应桌面平台构建工具，用于 Flutter 桌面端
- Docker、Nginx、PM2，用于生产或类生产部署

开发客户端前建议先执行：

```bash
flutter doctor
```

## 快速开始

```bash
git clone https://github.com/bfzg/etedrop.git
cd fast_send_workspace
```

### 启动服务端

```bash
cd fast_send_server
npm ci
npm run start:dev
```

服务端默认监听：

- `HOST=0.0.0.0`
- `PORT=3000`

生产部署文档中通常使用 `PORT=40321`，再由 Nginx 反向代理到服务端。

常用命令：

```bash
npm run build
npm test
npm run lint
```

### 启动分享页

```bash
cd share-page-app
npm ci
npm run tailwind
npm run dev
```

打开：

- `http://localhost:5173/share`
- 真实分享路由格式：`/share/:deviceId/:shareCode`

构建分享页：

```bash
npm run build
```

当前分享页 Vite 构建会输出到 `share-page-app/share/`。服务端部署时请确认最终产物已放入 [fast_send_server/public/share/](./fast_send_server/public/share/)。

### 启动 Flutter 客户端

```bash
cd fast_send_flutter
flutter pub get
flutter devices
flutter run -d macos
```

可以把 `macos` 替换为 `android`、`ios`、`windows` 或 `linux`，取决于当前机器和 SDK 环境。

本地调试服务端地址时，可以通过 `--dart-define` 覆盖默认 API 地址：

```bash
flutter run -d macos \
  --dart-define=API_BASE_GLOBAL=http://localhost:3000 \
  --dart-define=API_BASE_MAINLAND=http://localhost:3000
```

### 启动官网

```bash
cd website
npm ci
npm run start
```

构建国际站：

```bash
npm run build
```

构建中国大陆站：

```bash
npm run build:domestic
```

## 配置说明

### 服务端配置

常用运行参数：

| 配置 | 说明 |
| --- | --- |
| `PORT` | HTTP / WebSocket 监听端口，默认 `3000`。 |
| `HOST` | 监听地址，默认 `0.0.0.0`。 |
| `FAST_SEND_PUBLIC_ROOT` | 可选。指定服务端 `public` 目录的绝对路径，用于分享页静态资源部署兜底。 |

更多部署细节请查看 [服务器部署文档](./doc/服务器部署文档.md) 和 [服务端 README](./fast_send_server/README.md)。

### 客户端接口地址

Flutter 客户端默认读取两个编译期配置：

| 配置 | 默认值 |
| --- | --- |
| `API_BASE_GLOBAL` | `https://api.etedrop.com` |
| `API_BASE_MAINLAND` | `https://api.etedrop.cn` |

客户端会根据选中的 HTTP API 地址推导 WebSocket 地址：

- `/api/share`
- `/api/connect`

相关代码可查看 [server_endpoints.dart](./fast_send_flutter/lib/core/config/server_endpoints.dart)。

### Android 签名配置

Android release 构建需要本地签名配置。复制模板：

```bash
cp fast_send_flutter/android/key.properties.example fast_send_flutter/android/key.properties
```

然后填写本机真实值。请勿提交以下文件：

- `fast_send_flutter/android/key.properties`
- `.jks` / `.keystore`
- Apple 证书和 Provisioning Profile
- App Store Connect 凭据
- Google Play 凭据
- Firebase / Google service 配置文件

签名模板可查看 [key.properties.example](./fast_send_flutter/android/key.properties.example)。

## 开发流程

建议流程：

1. 选择要修改的子项目。
2. 在对应目录安装依赖：`npm ci` 或 `flutter pub get`。
3. 启动本地开发服务或运行客户端。
4. 不提交密钥、证书、构建产物和本地配置。
5. 修改行为、配置或部署方式时，同步更新文档。
6. 提交前运行受影响子项目的检查命令。

推荐检查：

```bash
cd fast_send_flutter && flutter analyze
cd fast_send_server && npm test
cd share-page-app && npm run build
cd website && npm run typecheck
```

贡献说明见 [CONTRIBUTING.md](./CONTRIBUTING.md)。

## 部署和打包

部署与打包文档：

- [服务器部署文档](./doc/服务器部署文档.md)
- [桌面端打包 DMG 与 EXE 教程](./doc/桌面端打包-DMG与EXE教程.md)
- [移动端打包 Android APK 与 iOS 安装包教程](./doc/移动端打包-Android APK与iOS安装包教程.md)
- [Flutter 打包说明](./fast_send_flutter/BUILD_PACKAGE.md)

服务端部署一般由 Nginx 终止 TLS，再代理到 NestJS 服务。分享页静态资源由服务端托管，重新构建分享页后需要确认 [fast_send_server/public/share/](./fast_send_server/public/share/) 中是预期版本。

## 安全说明

请勿提交任何密钥、签名文件、证书或私有部署配置。如果某个密钥曾经推送到公开仓库，应当视为泄露，重新生成并清理 Git 历史。

安全问题请私下反馈，详见 [SECURITY.md](./SECURITY.md)。

## 第三方组件和 FFmpeg

各子项目的第三方依赖声明在：

- [fast_send_flutter/pubspec.yaml](./fast_send_flutter/pubspec.yaml)
- [fast_send_server/package.json](./fast_send_server/package.json)
- [share-page-app/package.json](./share-page-app/package.json)
- [website/package.json](./website/package.json)

仓库中包含 [ffmpeg_build/](./ffmpeg_build/) 目录。FFmpeg 的许可证义务取决于具体构建参数和启用组件。发布安装包或二进制产物前，请确认 FFmpeg 构建配置、源码来源和许可证要求。更多说明见 [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)。

## 联系开发者

- Email: [yuanzhou_cn@qq.com](mailto:yuanzhou_cn@qq.com)
- Website: [https://etedrop.com](https://etedrop.com)

## 版权和许可证

Copyright (c) 2026 EteDrop contributors.

除文件头或第三方组件另有说明外，本项目源码使用 [MIT License](./LICENSE) 开源。第三方组件、字体、图标和 FFmpeg 相关内容请同时查看 [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)。
