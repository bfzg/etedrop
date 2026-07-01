# EteDrop / Fast Send Workspace

EteDrop is a cross-platform file transfer project. It combines a Flutter desktop
and mobile client, a NestJS signaling service, a React-based public share page,
and a Docusaurus website. The core goal is fast device-to-device file transfer
with local-network discovery, WebRTC/P2P transfer, and share links for browser
receivers.

The repository is organized as a workspace instead of a single package. Each
subproject has its own dependency lockfile and local development commands.

## Background

The project was built to make file transfer between phones, laptops, desktops,
and browsers easier without forcing every file through centralized cloud
storage. The app prefers direct transfer paths when possible and uses the server
mainly for signaling, share-page delivery, and operational endpoints.

Typical usage scenarios:

- send files between devices on the same local network;
- send a share link that can be opened in a browser;
- preview common file types before download;
- stream or transcode media where supported;
- run independent global and mainland China service endpoints.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `fast_send_flutter/` | Flutter client for Android, iOS, macOS, Windows, and Linux. |
| `fast_send_server/` | NestJS server for WebSocket signaling, share routing, static share-page hosting, health checks, and usage metrics. |
| `share-page-app/` | React/Vite share page opened by browser receivers. Its production build is served by `fast_send_server`. |
| `website/` | Docusaurus marketing/documentation website and release download pages. |
| `doc/` | Architecture, deployment, packaging, protocol, and product planning documents. |
| `ffmpeg_build/` | FFmpeg/FFprobe binaries used by packaging and media workflows. See `THIRD_PARTY_NOTICES.md` before redistributing builds. |
| `images/` | Project images and supporting visual assets. |

## Tech Stack

- Flutter and Dart for the multi-platform client.
- NestJS, TypeScript, and `ws` for the signaling/API server.
- React, Vite, Tailwind CSS, and i18next for the share page.
- Docusaurus, React, and TypeScript for the website.
- FFmpeg/FFprobe for selected media workflows.

## Development Prerequisites

Install the tools needed by the subproject you are working on:

- Git
- Node.js 20 or newer
- npm
- Flutter SDK compatible with Dart `^3.9.2`
- Android Studio and Android SDK for Android builds
- Xcode and CocoaPods for iOS/macOS builds
- CMake and desktop build tooling for Flutter desktop targets
- Docker, Nginx, and PM2 for production-like server deployment, if needed

Run `flutter doctor` before working on the client.

## Quick Start

Clone the repository:

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

The server defaults to `HOST=0.0.0.0` and `PORT=3000`. Production deployments in
the existing docs use `PORT=40321` behind Nginx.

Useful commands:

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

Open `http://localhost:5173/share`. A real share route uses
`/share/:deviceId/:shareCode`.

Build the share page:

```bash
npm run build
```

The Vite build writes to `share-page-app/share/`. For deployment with the Nest
server, follow the server build flow that places the final files under
`fast_send_server/public/share/`.

### Flutter Client

```bash
cd fast_send_flutter
flutter pub get
flutter devices
flutter run -d macos
```

Replace `macos` with `android`, `ios`, `windows`, or `linux` depending on your
machine and installed SDKs.

The client API endpoints can be overridden at build time:

```bash
flutter run -d macos \
  --dart-define=API_BASE_GLOBAL=http://localhost:3000 \
  --dart-define=API_BASE_MAINLAND=http://localhost:3000
```

For Android release signing, copy the template and fill in local values:

```bash
cp fast_send_flutter/android/key.properties.example fast_send_flutter/android/key.properties
```

Never commit `key.properties`, keystores, certificates, Apple provisioning files,
or service credentials.

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

Important runtime values:

- `PORT`: HTTP/WebSocket port. Defaults to `3000`.
- `HOST`: bind host. Defaults to `0.0.0.0`.
- `FAST_SEND_PUBLIC_ROOT`: optional absolute path to the server `public`
  directory when the share page is served from a custom location.

Production deployments usually terminate TLS at Nginx and proxy to the Nest
server. See `doc/服务器部署文档.md` and `fast_send_server/README.md`.

### Client Endpoints

The Flutter client resolves two API bases:

- `API_BASE_GLOBAL`, default `https://api.etedrop.com`
- `API_BASE_MAINLAND`, default `https://api.etedrop.cn`

These are read from Dart compile-time environment values via `--dart-define`.
The app derives WebSocket routes from the selected HTTP base:

- `/api/share`
- `/api/connect`

### Signing and Store Credentials

Signing files are intentionally ignored by Git. Keep these local or in a secure
CI secret store:

- `fast_send_flutter/android/key.properties`
- Android `.jks` / `.keystore` files
- Apple certificates and provisioning profiles
- App Store Connect credentials
- Google Play credentials
- Firebase or Google service configuration files, if added later

## Development Flow

1. Pick the subproject you are changing.
2. Install dependencies in that subproject with `npm ci` or `flutter pub get`.
3. Run the local dev command.
4. Keep generated artifacts and private config out of commits.
5. Run the checks related to the changed package.
6. Update docs when behavior, configuration, or deployment changes.

Recommended checks before opening a pull request:

```bash
cd fast_send_flutter && flutter analyze
cd fast_send_server && npm test
cd share-page-app && npm run build
cd website && npm run typecheck
```

## Deployment Notes

Server deployment and Nginx examples live in `doc/服务器部署文档.md`. Desktop and
mobile packaging notes live in:

- `doc/桌面端打包-DMG与EXE教程.md`
- `doc/移动端打包-Android APK与iOS安装包教程.md`
- `fast_send_flutter/BUILD_PACKAGE.md`

The repository contains public share-page assets in `fast_send_server/public/share/`.
If you rebuild the share page, make sure the server is serving the intended
version.

## Security

Do not commit secrets or signing material. If a credential has ever been pushed
to a public repository, rotate it and remove it from Git history before relying
on it again.

Report security issues privately by email. See `SECURITY.md`.

## Third-Party Components

Third-party dependencies are declared in each subproject manifest. FFmpeg
binaries are present under `ffmpeg_build/`; verify their build configuration and
license obligations before redistributing release packages. See
`THIRD_PARTY_NOTICES.md`.

## Contact

Maintainer contact:

- Email: yuanzhou_cn@qq.com
- Website: https://etedrop.com

## Copyright and License

Copyright (c) 2026 EteDrop contributors.

The project source code is released under the MIT License unless a file or
third-party component states otherwise. See `LICENSE` and
`THIRD_PARTY_NOTICES.md`.
