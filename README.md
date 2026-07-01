# EteDrop / Fast Send Workspace

[简体中文](./README.zh-CN.md)

EteDrop is a cross-platform file transfer project. It includes a Flutter client,
a NestJS signaling service, a file sharing page, and an official website. The
project aims to make file transfer between phones, computers, desktop systems,
and browsers easier, with local-network and WebRTC/P2P transfer paths preferred
where possible. The server mainly provides signaling, share-page delivery, and
operational endpoints.

## Background

Many file transfer tools rely on cloud relay, which can limit speed, privacy,
and large-file handling. EteDrop is designed around these goals:

- transfer directly on the local network when possible;
- establish WebRTC connections through a signaling service across networks;
- let receivers open share links in a browser;
- support common file preview, download, and selected media playback/transcoding
  workflows;
- support separate global and mainland China service endpoints.

## Repository Layout

| Path | Purpose |
| --- | --- |
| [fast_send_flutter/](./fast_send_flutter/) | Flutter client for Android, iOS, macOS, Windows, and Linux. |
| [fast_send_server/](./fast_send_server/) | NestJS server for WebSocket signaling, share routing, static share-page hosting, health checks, and metrics. |
| [share-page-app/](./share-page-app/) | React/Vite share page opened by browser receivers. |
| [website/](./website/) | Docusaurus website, download pages, blog, and product pages. |
| [doc/](./doc/) | Architecture, deployment, packaging, protocol, and planning documents. |
| [ffmpeg_build/](./ffmpeg_build/) | FFmpeg/FFprobe binaries used by media workflows. See [third-party notices](./THIRD_PARTY_NOTICES.md) before redistributing. |
| [images/](./images/) | Project images and supporting visual assets. |

## Documentation

- [Server README](./fast_send_server/README.md)
- [Flutter client README](./fast_send_flutter/README.md)
- [Share page README](./share-page-app/README.md)
- [Website README](./website/README.md)
- [Server deployment guide](./doc/服务器部署文档.md)
- [Desktop packaging guide](./doc/桌面端打包-DMG与EXE教程.md)
- [Mobile packaging guide](./doc/移动端打包-Android APK与iOS安装包教程.md)
- [Server architecture overview](./doc/服务端架构总览.md)
- [Signaling protocol](./doc/信令协议说明.md)
- [Share API](./doc/分享接口说明.md)
- [Third-party notices](./THIRD_PARTY_NOTICES.md)
- [Security policy](./SECURITY.md)
- [Contributing guide](./CONTRIBUTING.md)
- [License](./LICENSE)

## Tech Stack

- Flutter / Dart for the multi-platform client.
- NestJS / TypeScript / `ws` for the signaling and API service.
- React / Vite / Tailwind CSS / i18next for the browser share page.
- Docusaurus / React / TypeScript for the website.
- FFmpeg / FFprobe for selected media handling workflows.

## Development Requirements

Install the tools required by the subproject you want to work on:

- Git
- Node.js 20 or newer
- npm
- Flutter SDK compatible with Dart `^3.9.2`
- Android Studio and Android SDK for Android builds
- Xcode and CocoaPods for iOS / macOS builds
- CMake and platform desktop build tools for Flutter desktop targets
- Docker, Nginx, and PM2 for production-like deployment

Before working on the client, run:

```bash
flutter doctor
```

## Quick Start

```bash
git clone https://github.com/bfzg/fast_send_workspace.git
cd fast_send_workspace
```

### Server

```bash
cd fast_send_server
npm ci
npm run start:dev
```

The server defaults to:

- `HOST=0.0.0.0`
- `PORT=3000`

Production deployment docs usually use `PORT=40321` behind Nginx.

Common commands:

```bash
npm run build
npm test
npm run lint
```

### Share Page

```bash
cd share-page-app
npm ci
npm run tailwind
npm run dev
```

Open:

- `http://localhost:5173/share`
- real share route format: `/share/:deviceId/:shareCode`

Build the share page:

```bash
npm run build
```

The current Vite build outputs to `share-page-app/share/`. For server
deployment, confirm that the final files are placed under
[fast_send_server/public/share/](./fast_send_server/public/share/).

### Flutter Client

```bash
cd fast_send_flutter
flutter pub get
flutter devices
flutter run -d macos
```

Replace `macos` with `android`, `ios`, `windows`, or `linux` depending on your
machine and SDK setup.

For local server debugging, override the default API endpoints with
`--dart-define`:

```bash
flutter run -d macos \
  --dart-define=API_BASE_GLOBAL=http://localhost:3000 \
  --dart-define=API_BASE_MAINLAND=http://localhost:3000
```

### Website

```bash
cd website
npm ci
npm run start
```

Build the international site:

```bash
npm run build
```

Build the mainland China site:

```bash
npm run build:domestic
```

## Configuration

### Server

Common runtime values:

| Config | Description |
| --- | --- |
| `PORT` | HTTP / WebSocket port. Defaults to `3000`. |
| `HOST` | Bind host. Defaults to `0.0.0.0`. |
| `FAST_SEND_PUBLIC_ROOT` | Optional absolute path to the server `public` directory for share-page static assets. |

For deployment details, see the [server deployment guide](./doc/服务器部署文档.md)
and [server README](./fast_send_server/README.md).

### Client API Endpoints

The Flutter client reads two compile-time values:

| Config | Default |
| --- | --- |
| `API_BASE_GLOBAL` | `https://api.etedrop.com` |
| `API_BASE_MAINLAND` | `https://api.etedrop.cn` |

The client derives WebSocket routes from the selected HTTP API base:

- `/api/share`
- `/api/connect`

Related code: [server_endpoints.dart](./fast_send_flutter/lib/core/config/server_endpoints.dart).

### Android Signing

Android release builds need local signing configuration. Copy the template:

```bash
cp fast_send_flutter/android/key.properties.example fast_send_flutter/android/key.properties
```

Then fill in local values. Do not commit:

- `fast_send_flutter/android/key.properties`
- `.jks` / `.keystore`
- Apple certificates and provisioning profiles
- App Store Connect credentials
- Google Play credentials
- Firebase / Google service configuration files

Template: [key.properties.example](./fast_send_flutter/android/key.properties.example).

## Development Flow

Recommended flow:

1. Choose the subproject you are changing.
2. Install dependencies in that directory with `npm ci` or `flutter pub get`.
3. Start the local dev service or run the client.
4. Do not commit secrets, certificates, build output, or local config.
5. Update documentation when behavior, configuration, or deployment changes.
6. Run checks for the affected subproject before submitting changes.

Recommended checks:

```bash
cd fast_send_flutter && flutter analyze
cd fast_send_server && npm test
cd share-page-app && npm run build
cd website && npm run typecheck
```

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution notes.

## Deployment and Packaging

Deployment and packaging docs:

- [Server deployment guide](./doc/服务器部署文档.md)
- [Desktop packaging guide](./doc/桌面端打包-DMG与EXE教程.md)
- [Mobile packaging guide](./doc/移动端打包-Android APK与iOS安装包教程.md)
- [Flutter packaging notes](./fast_send_flutter/BUILD_PACKAGE.md)

Server deployment usually terminates TLS at Nginx and proxies to the NestJS
service. Share-page static assets are hosted by the server; after rebuilding the
share page, confirm that [fast_send_server/public/share/](./fast_send_server/public/share/)
contains the intended version.

## Security

Do not commit secrets, signing files, certificates, or private deployment
configuration. If a credential was ever pushed to a public repository, treat it
as leaked, rotate it, and clean the Git history.

Report security issues privately. See [SECURITY.md](./SECURITY.md).

## Third-Party Components and FFmpeg

Subproject dependencies are declared in:

- [fast_send_flutter/pubspec.yaml](./fast_send_flutter/pubspec.yaml)
- [fast_send_server/package.json](./fast_send_server/package.json)
- [share-page-app/package.json](./share-page-app/package.json)
- [website/package.json](./website/package.json)

This repository includes [ffmpeg_build/](./ffmpeg_build/). FFmpeg license
obligations depend on the exact build options and enabled components. Before
publishing installers or binary releases, verify the FFmpeg build configuration,
source origin, and license requirements. See [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md).

## Contact

- Email: [yuanzhou_cn@qq.com](mailto:yuanzhou_cn@qq.com)
- Website: [https://etedrop.com](https://etedrop.com)

## Copyright and License

Copyright (c) 2026 EteDrop contributors.

Unless a file header or third-party component states otherwise, the source code
is released under the [MIT License](./LICENSE). Third-party components, fonts,
icons, and FFmpeg-related content are also covered by
[THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md).
