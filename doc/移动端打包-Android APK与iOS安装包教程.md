# fast_send_flutter 移动端打包教程（Android APK + iOS IPA）

本文基于当前项目 `fast_send_flutter` 实际配置整理，目标是让你可以直接产出：

- Android 安装包：`APK`（以及可选 `AAB`）
- iOS 安装包：`IPA`

---

## 1. 前置条件

在仓库根目录执行（或进入 `fast_send_flutter` 目录执行）：

```bash
cd fast_send_flutter
flutter doctor -v
flutter pub get
```

确保 `flutter doctor -v` 没有关键报错，尤其是：

- Android toolchain
- Xcode（仅 iOS）
- CocoaPods（仅 iOS）

---

## 2. 项目当前配置注意点（非常重要）

### 2.1 Android release 签名已调整为“自动识别”

当前 `android/app/build.gradle.kts` 的 release 配置已改为：

```kotlin
buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
    }
}
```

含义：

- 有 `android/key.properties`：使用正式签名（可分发）
- 无 `android/key.properties`：回退 debug 签名（仅本地测试）

### 2.2 应用标识（Bundle/Application ID）

项目当前 ID 为：

- Android `applicationId`: `com.etedrop.app`
- iOS `PRODUCT_BUNDLE_IDENTIFIER`: `com.etedrop.app`

如果你有自己的正式包名，先统一修改再打包。

---

## 3. Android：生成正式 APK

## 3.1 生成签名文件（只需一次）

```bash
cd fast_send_flutter/android
keytool -genkey -v \
  -keystore etedrop-release.keystore \
  -alias etedrop \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

建议把 keystore 放在 `android/` 下，并妥善备份。

## 3.2 配置密钥参数（本地文件，不要提交）

在 `fast_send_flutter/android/` 新建 `key.properties`：

```properties
storePassword=你的store密码
keyPassword=你的key密码
keyAlias=etedrop
storeFile=etedrop-release.keystore
```

然后把 `android/key.properties` 和 `android/*.keystore` 加入 `.gitignore`（避免泄漏）。

## 3.3 修改 `android/app/build.gradle.kts`

把 release 从 debug 签名改为读取 `key.properties` 的 release 签名。可参考以下逻辑：

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
```

## 3.4 执行打包

回到 Flutter 项目目录：

```bash
cd fast_send_flutter
flutter clean
flutter pub get
flutter build apk --release
```

输出路径：

- `build/app/outputs/flutter-apk/app-release.apk`

可选（上架 Google Play 推荐）：

```bash
flutter build appbundle --release
```

输出路径：

- `build/app/outputs/bundle/release/app-release.aab`

---

## 4. iOS：生成 IPA（安装包）

仅支持在 macOS 上操作。

## 4.1 准备 Apple 签名条件

你需要：

- Apple Developer 账号（付费）
- 对应证书与 Provisioning Profile
- 唯一 Bundle ID（当前是 `com.etedrop.app`）

## 4.2 用 Xcode 完成签名设置（推荐）

```bash
cd fast_send_flutter
open ios/Runner.xcworkspace
```

在 Xcode 中：

1. 选择 `Runner` target -> `Signing & Capabilities`
2. 勾选 `Automatically manage signing`
3. 选择你的 Team
4. 确认 Bundle Identifier 正确且唯一

## 4.3 安装 iOS 依赖并构建 IPA

```bash
cd fast_send_flutter
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

默认输出目录（Flutter 常见）：

- `build/ios/ipa/*.ipa`

## 4.4 安装到真机（常见两种方式）

- 方式 A：用 Apple Configurator / Xcode Devices 安装到已注册设备
- 方式 B：上传 TestFlight（推荐团队测试分发）

如果要上传 App Store Connect，通常使用：

- Xcode Organizer（Archive -> Distribute）
- 或 Transporter 上传 `.ipa`

---

## 5. 常见问题排查

## 5.1 Android 构建成功但安装失败

- 检查是否签名不一致（历史安装包冲突）
- 卸载旧包后重装
- 确认 `minSdk` 与设备系统版本兼容

## 5.2 iOS 构建时报签名错误

- 确认 Team、证书、Profile 三者一致
- 确认 Bundle ID 没有被其他 App 占用
- 执行 `cd ios && pod install` 后重新构建

## 5.3 CocoaPods 相关错误

```bash
brew install cocoapods
pod --version
cd fast_send_flutter/ios && pod install
```

---

## 6. 建议的发布命令清单（可直接复制）

```bash
# 推荐：使用统一脚本（在 fast_send_flutter 目录下）
chmod +x scripts/package.sh

# Android release APK
./scripts/package.sh android-apk

# Android release AAB
./scripts/package.sh android-aab

# iOS release IPA（macOS）
./scripts/package.sh ios-ipa
```

如果你想直接执行 Flutter 原生命令：

```bash
# Android release APK
cd fast_send_flutter
flutter clean
flutter pub get
flutter build apk --release

# Android release AAB
flutter build appbundle --release

# iOS release IPA（macOS）
cd ios && pod install && cd ..
flutter build ipa --release
```

---

## 7. 发布前核对清单

- [ ] `pubspec.yaml` 的 `version` 已更新
- [ ] Android release 不再使用 debug 签名
- [ ] iOS Team / Bundle ID / 证书配置正确
- [ ] 在真机完成安装与基本功能回归
- [ ] 备份 Android keystore 与密码

