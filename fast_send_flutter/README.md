# Flutter Template APP

# 多平台运行指南（Android / iOS / Windows / macOS / Linux）

## 1. 环境准备

```bash
flutter doctor
flutter pub get
```

先确认 `flutter doctor` 没有关键报错（尤其是 Android Studio、Xcode、CMake 等）。

## 2. 查看当前可用设备

```bash
flutter devices
```

如果设备列表为空，可先启动模拟器或桌面目标系统。

---

## 3. 运行到 Android 模拟器

1. 打开 Android Studio -> Device Manager，启动一个 Android Emulator。
2. 终端确认设备在线：

```bash
flutter devices
```

3. 运行应用：

```bash
flutter run -d android
```

如果有多个 Android 设备，可以先用 `flutter devices` 查到 device id，再执行：

```bash
flutter run -d <device_id>
```

---

## 4. 运行到 iOS 模拟器（仅 macOS）

1. 启动模拟器：

```bash
open -a Simulator
```

2. 查看 iOS 设备：

```bash
flutter devices
```

3. 运行应用：

```bash
flutter run -d ios
```

如需指定某个 iPhone 模拟器，同样使用 `-d <device_id>`。

---

## 5. 运行到 Windows 桌面

在 Windows 机器上执行：

```bash
flutter run -d windows
```

---

## 6. 运行到 macOS 桌面

在 macOS 机器上执行：

```bash
flutter run -d macos
```

---

## 7. 运行到 Linux 桌面

在 Linux 机器上执行：

```bash
flutter run -d linux
```

---

## 8. 打包发布（Build）

### 8.1 Android

```bash
# 生成 APK
flutter build apk --release

# 生成 App Bundle（上架 Google Play 推荐）
flutter build appbundle --release
```

产物路径：

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 8.2 iOS（仅 macOS）

```bash
flutter build ipa --release
```

说明：iOS 正式发布通常需要在 Xcode 中配置证书与 Provisioning Profile，并通过 Xcode Organizer 或 Transporter 上传。

### 8.3 Windows

```bash
flutter build windows --release
```

产物目录：`build/windows/x64/runner/Release/`

### 8.4 Linux

```bash
flutter build linux --release
```

产物目录：`build/linux/x64/release/bundle/`

### 8.5 macOS（重点）

1. 先构建 release：

```bash
flutter build macos --release --tree-shake-icons
```

2. 构建产物位置：

- `build/macos/Build/Products/Release/<你的App名>.app`

3. 可选：开启混淆 + 分离符号（对包体积帮助有限，但能降低可逆性；也便于崩溃符号化）。

```bash
# 将符号信息输出到本地目录（注意：此目录请妥善保存，线上崩溃需要用它符号化）
flutter build macos --release --tree-shake-icons \
  --obfuscate --split-debug-info=build/macos/symbols
```

4. 本地分发（不公证）可直接压缩 `.app` 给内部测试。

说明：打包/压缩时 **不要** 把 `.dSYM` 一起打进去，否则体积会明显变大。

5. 对外分发建议做 Apple 签名 + 公证（notarization）：

```bash
# 1) 对 .app 签名（请替换证书名称）
codesign --force --deep --sign "Developer ID Application: YOUR_NAME (TEAM_ID)" \
  build/macos/Build/Products/Release/<你的App名>.app

# 2) 打包为 zip 供公证上传
ditto -c -k --sequesterRsrc --keepParent \
  build/macos/Build/Products/Release/<你的App名>.app \
  <你的App名>.zip

# 3) 提交公证（需先配置 App Store Connect API Key 或 Apple ID 凭据）
xcrun notarytool submit <你的App名>.zip --wait --keychain-profile "notary-profile"

# 4) 公证通过后 stapler
xcrun stapler staple build/macos/Build/Products/Release/<你的App名>.app
```

6. 如果你需要 `.dmg` 安装包，可在签名/公证后再制作 DMG（常见做法是使用 `create-dmg` 等工具）。

```
brew install create-dmg
create-dmg \
  "build/macos/Build/Products/Release/<你的App名>.app" \
  --dmg-title "<你的App名>" \
  --overwrite
```

7. 包体积优化建议（macOS 上 80~150MB 很常见）：

- **最有效的手段通常不是 Flutter 参数**：macOS 桌面端会自带 Flutter Engine/ICU 等运行时，基础体积就不小。
- **检查是否把不需要的平台二进制作为 assets 一起打包**：例如仅 macOS 运行却把 `assets/ffmpeg/windows/*.exe` 也打进包，会直接增大包体。
  - 建议做法：将 FFmpeg 资源按平台拆分为“按需下载/首次运行下载”，或在构建前脚本仅拷贝当前平台需要的资源到 `assets/ffmpeg/<platform>/` 再构建。
- **避免 Universal（arm64+x86_64）构建**：如果你只分发给 Apple Silicon，可在 Xcode 里将架构限制为 arm64（Universal 会更大）。

---

## 9. 常用辅助命令

```bash
# 查看支持的平台能力
flutter config

# 启用桌面平台能力（如未启用）
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop

# 清理并重新拉取依赖
flutter clean
flutter pub get
```

## 10. macOS 运行报错：CocoaPods not installed

如果执行 `flutter run -d macos` 报错：

```text
Error: CocoaPods not installed or not in valid state.
```

按下面步骤处理：

1. 安装并确认 CocoaPods：

```bash
brew install cocoapods
pod --version
```

2. 执行 macOS 依赖安装并重新运行：

```bash
flutter clean
flutter pub get
flutter precache --macos
cd macos && pod install && cd ..
flutter run -d macos
```

3. 如果已安装但仍识别不到 `pod`，执行（Apple Silicon 常见）：

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
pod --version
```

# 生成 .g 文件

```
flutter pub run build_runner build --delete-conflicting-outputs
dart run build_runner build --delete-conflicting-outputs
```

# 目录介绍

```
lib/
├── main.dart
├── app.dart                  # 顶层App入口（CupertinoApp/MaterialApp.router）
│
├── core/                     # 核心层（跨业务通用的东西）
│   ├── config/               # 常量、环境配置
│   │   └── env.dart
│   ├── router/               # 路由（go_router / auto_route）
│   │   └── app_router.dart
│   ├── theme/                # 全局主题、颜色、字体
│   ├── models/               # 全局可复用的数据模型
│
├── widgets/                 # 全局通用widgets（Loading、ErrorView等）
│
│
├── features/                 # 按功能模块划分（DDD/模块化思想）
│   ├── auth/                 # 登录注册模块
│   │
│   ├── home/
│   │
│   └── ...更多模块
│
│
├── providers/                # 全局共享的 Riverpod Provider
│
└── services/                 # 第三方/系统服务封装
```
