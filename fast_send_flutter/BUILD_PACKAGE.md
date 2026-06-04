# fast_send_flutter 一键打包脚本说明

项目已新增统一脚本：`scripts/package.sh`。

---

## 1. 准备

```bash
cd fast_send_flutter
chmod +x scripts/package.sh
```

---

## 2. 用法

```bash
./scripts/package.sh <target> [--build-name x.y.z] [--build-number n] [--skip-clean]
```

支持的 `target`：

- `android-apk`：Android APK
- `android-aab`：Android AAB
- `ios-ipa`：iOS IPA（仅 macOS）
- `macos-app`：macOS `.app`（仅 macOS）
- `macos-dmg`：macOS `.dmg`（仅 macOS，需 `create-dmg`）
- `windows-exe`：Windows Release 目录（仅 Windows）

---

## 3. 常用示例

```bash
# Android APK
./scripts/package.sh android-apk

# Android AAB
./scripts/package.sh android-aab

# iOS IPA
./scripts/package.sh ios-ipa

# macOS DMG
./scripts/package.sh macos-dmg

# Windows exe
./scripts/package.sh windows-exe
```

指定版本号示例：

```bash
./scripts/package.sh android-apk --build-name 1.2.3 --build-number 45
```

---

## 4. Android 正式签名

`android/app/build.gradle.kts` 已支持自动识别 `android/key.properties`：

- 存在 `key.properties`：release 正式签名
- 不存在 `key.properties`：回退 debug 签名（仅测试）

`android/key.properties` 示例：

```properties
storePassword=你的store密码
keyPassword=你的key密码
keyAlias=etedrop
storeFile=etedrop-release.keystore
```

请勿提交 `key.properties` 与 `.keystore` 到仓库。
