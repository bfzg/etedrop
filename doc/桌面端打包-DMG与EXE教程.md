# 桌面端稳定版打包：macOS（DMG）与 Windows（EXE）

本文说明如何在 **EteDrop**（Flutter 工程 `fast_send_flutter`）上打出 **Release 稳定版**，并分别产出 **macOS `.dmg`** 与 **Windows 可执行程序（`EteDrop.exe` 及完整运行目录）**。更通用的运行与签名说明见仓库内 [`fast_send_flutter/README.md`](../fast_send_flutter/README.md)。

---

## 1. 通用准备

1. 安装 [Flutter](https://docs.flutter.dev/get-started/install) 稳定渠道，并执行：

   ```bash
   flutter doctor
   ```

   桌面目标需无关键报错；macOS 需 Xcode，Windows 需 Visual Studio 的「使用 C++ 的桌面开发」工作负载。

2. 进入工程目录并拉依赖：

   ```bash
   cd fast_send_flutter
   flutter pub get
   ```

3. **版本号**：发布前在 `pubspec.yaml` 中确认 `version:`（如 `1.0.0+1`）；构建时也可用 `--build-name` / `--build-number` 覆盖。

4. 本仓库 macOS 应用名为 **EteDrop**，产物为 `EteDrop.app`；Windows 可执行文件名为 **EteDrop.exe**（见 `windows/CMakeLists.txt` 中 `BINARY_NAME`）。

---

## 2. macOS：Release 构建 + 制作 DMG

### 2.1 构建 Release

在 **macOS** 上执行：

```bash
cd fast_send_flutter
flutter build macos --release --tree-shake-icons
```

产物路径：

```text
build/macos/Build/Products/Release/EteDrop.app
```

可选：开启混淆并分离调试符号（便于崩溃符号化，**符号目录请单独保管，勿打进分发包**）：

```bash
flutter build macos --release --tree-shake-icons \
  --obfuscate --split-debug-info=build/macos/symbols
```

### 2.2 对外分发：签名与公证（强烈建议）

未签名或未公证的 `.app` / `.dmg` 在他人电脑上可能被 Gatekeeper 拦截。

#### 省略号、占位符能不能「随便写」？

**不能乱填的是：**

- **`codesign` 的 `-sign` 后面的整串证书名称**  
  必须与钥匙串里 **Developer ID Application** 证书的**完整显示名**一致（含括号里的 **Team ID**，10 位字母数字）。写错会签名失败或签错证书。
- **公证用的 Apple 账号与 Team ID**  
  必须是已付费的 [Apple Developer Program](https://developer.apple.com/programs/) 成员，且该团队有权使用 Developer ID 与 Notary 服务。
- **API Key 的 Key ID、Issuer ID、`.p8` 文件**  
  来自 App Store Connect → 用户与访问 → 密钥；须与团队对应，不能虚构。

**可以你自己起名、但要前后一致的是：**

- **`notarytool` 的钥匙串 profile 名称**（下文示例里的 `notary-profile`）  
  你在执行 `notarytool store-credentials` 时自定一个名字，之后 `submit` 时 `--keychain-profile` 必须用**同一个**名字。叫 `my-etedrop-notary` 也可以，不必和 App 名相同。

---

#### 前置条件

1. **Apple Developer Program** 有效会员（个人或公司）。
2. 在 [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list) 创建并下载 **Developer ID Application** 证书，双击导入 **钥匙串访问**（登录钥匙串）。
3. 本机已安装较新的 **Xcode** 或至少 Xcode Command Line Tools（提供 `codesign`、`notarytool`、`stapler`）。

---

#### 第 1 步：确认签名证书在钥匙串里的「准确名字」

终端执行：

```bash
security find-identity -v -p codesigning
```

在输出里找到带 **`Developer ID Application:`** 的那一行，**整段引号内的字符串**就是 `-sign` 要填的值，例如：

```text
"Developer ID Application: Zhang San (A1B2C3D4E5)"
```

把下面命令里的 `YOUR_DEV_ID_CERT_NAME` **原样替换**为这一整串（保留引号）。

---

#### 第 2 步：对 `EteDrop.app` 签名（需公证时请带 Hardened Runtime）

在 `fast_send_flutter` 目录下，先完成 Release 构建（见 2.1），再执行：

```bash
APP="build/macos/Build/Products/Release/EteDrop.app"

codesign --force --deep --sign "YOUR_DEV_ID_CERT_NAME" \
  --options runtime \
  --timestamp \
  "$APP"
```

说明：

- **`--options runtime`**：启用强化运行时，**提交公证时通常需要**（若 Apple 或后续校验报策略问题，再按报错补全 **entitlements** 或调整签名方式；复杂插件可查阅 [Apple 文档](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)）。
- **`--timestamp`**：打上可信时间戳，证书过期后已发版本仍可验证。

自检签名：

```bash
codesign --verify --verbose=4 "$APP"
spctl -a -vv --type install "$APP"
```

若此处 `spctl` 仍提示未公证，属正常；公证并 staple 后再测应通过或可接受。

---

#### 第 3 步：打 zip 并提交公证

公证上传的是 **zip**（或 dmg/pkg 等），不要只上传裸 `.app` 目录而不打包。

```bash
ZIP_PATH="EteDrop-notarize.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP_PATH"
```

**首次**在本机配置公证凭据（二选一）。

**方式 A：App Store Connect API 密钥（适合 CI / 推荐）**

在 App Store Connect 创建 **Issuer ID + API Key（Admin 或 App Manager）**，下载 `.p8`，然后：

```bash
xcrun notarytool store-credentials \
  --key "/path/to/AuthKey_XXXXXXXXXX.p8" \
  --key-id "XXXXXXXXXX" \
  --issuer "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
  --team-id "YOUR_TEAM_ID" \
  "notary-profile"
```

**方式 B：Apple ID + 应用专用密码**

在 appleid.apple.com 为 Apple ID 生成**应用专用密码**，然后：

```bash
xcrun notarytool store-credentials \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  "notary-profile"
```

其中 `YOUR_TEAM_ID` 为开发者网站上显示的 **10 位 Team ID**；`notary-profile` 可改成你喜欢的别名，但后面 submit 要一致。

提交并等待结果：

```bash
xcrun notarytool submit "$ZIP_PATH" --wait --keychain-profile "notary-profile"
```

若状态为 **Accepted**，继续下一步；若为 **Invalid**，用下面命令取详细日志排查：

```bash
xcrun notarytool log <submission-id> --keychain-profile "notary-profile"
```

---

#### 第 4 步：装订票据（staple）到 `.app`

```bash
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
```

**建议：先 staple 再按 2.3 节制作 DMG**，这样用户从 DMG 拖出的应用已带公证票据。临时 zip 可删除：`rm -f "$ZIP_PATH"`。

---

#### 第 5 步（可选）：对 DMG 再签名

若你生成的是对外分发的 `.dmg`，部分团队还会对 DMG 本身再执行一次 `codesign`（使用同一张 **Developer ID** 相关证书策略以咨询你们安全规范为准）。

---

#### 与 README 的关系

[`fast_send_flutter/README.md`](../fast_send_flutter/README.md) 中「8.5 macOS」保留了精简版命令；本文补充了**占位符含义、凭据两种配置方式、校验与排错**。官方总览见：[Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)。

### 2.3 使用 create-dmg 生成 DMG

1. 安装工具：

   ```bash
   brew install create-dmg
   ```

2. 建议先准备一个**仅含 `.app` 的临时目录**（避免把无关文件打进卷内）：

   ```bash
   STAGING=$(mktemp -d)
   cp -R build/macos/Build/Products/Release/EteDrop.app "$STAGING/"
   ```

3. 生成 DMG（示例：带 Applications 快捷方式、窗口布局可按需改参数）：

   ```bash
   VERSION=$(grep '^version:' pubspec.yaml | head -1 | sed 's/version: *//;s/+.*//')
   create-dmg \
     --volname "EteDrop" \
     --window-pos 200 120 \
     --window-size 660 400 \
     --icon-size 80 \
     --icon "EteDrop.app" 180 170 \
     --hide-extension "EteDrop.app" \
     --app-drop-link 480 170 \
     "EteDrop-${VERSION}-macos.dmg" \
     "$STAGING"
   ```

4. 若 DMG 也需对外分发，可对 DMG 本身再做 **codesign**（按团队证书策略执行）。

5. 清理临时目录：

   ```bash
   rm -rf "$STAGING"
   ```

**说明**：内测可直接分发 zip 包好的 `EteDrop.app`；DMG 主要用于安装体验与品牌展示。包体优化（如避免把 Windows 版 FFmpeg 等资源打进 macOS 包）见 README 中「包体积优化建议」。

---

## 3. Windows：Release 构建与 EXE 分发

### 3.1 构建 Release

在 **Windows** 上进入工程目录执行：

```bash
cd fast_send_flutter
flutter build windows --release
```

主要产物目录：

```text
build\windows\x64\runner\Release\
```

其中 **`EteDrop.exe` 为入口程序**。该目录下同时还有 Flutter 引擎与各插件的 **`.dll`** 等文件，**分发时必须保持整目录结构一致**，不能只拷贝一个 `EteDrop.exe`，否则无法运行。

可选：同样可使用 `--obfuscate` 与 `--split-debug-info`（符号勿随安装包发给最终用户）。

### 3.2 交付形式建议

| 方式 | 说明 |
| ------ | ------ |
| **ZIP 整包** | 将 `Release` 文件夹打包为 zip，用户解压后运行 `EteDrop.exe`。简单、与 Flutter 默认输出一致。 |
| **安装程序（推荐）** | 使用 [Inno Setup](https://jrsoftware.org/isinfo.php)、[WiX](https://wixtoolset.org/) 等把 `Release` 目录打成安装包（`.exe` 安装向导），便于开始菜单、卸载信息与**覆盖升级**。本仓库已提供 Inno 脚本：`fast_send_flutter/installer/windows/EteDrop.iss`。 |
| **MSIX** | 适合企业或商店场景；需额外配置清单与证书，与「单个 EXE」不是同一路线。 |

### 3.3 Inno Setup：用户目录安装 + 覆盖升级（可作“升级包”）

本仓库的脚本默认安装到用户目录（无需管理员权限，适合在线升级）：

```text
%LocalAppData%\EteDrop
```

并且**向导支持改安装目录**。

#### 编译安装包

先构建：

```bash
cd fast_send_flutter
flutter build windows --release
```

再用 Inno Setup 的 `ISCC.exe` 编译（示例 PowerShell）：

```powershell
cd fast_send_flutter
$ver = (Select-String -Path .\pubspec.yaml -Pattern '^version:\s*' | Select-Object -First 1).Line.Split(':')[1].Trim().Split('+')[0]
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" `
  /DMyAppVersion=$ver `
  /DReleaseDir="build\windows\x64\runner\Release" `
  .\installer\windows\EteDrop.iss
```

输出在：

```text
fast_send_flutter\dist\
```

#### 升级包规则（最关键）

- **保持脚本内 `AppId` 永久不变**：同一 AppId 的新 `Setup.exe` 会识别旧版本并覆盖升级  
- 每次发版重新编译新的 `Setup.exe`，这个 `Setup.exe` 就是你的“升级包”

### 3.4 在线升级建议（Windows）

推荐策略是：应用内检查到新版本后，**下载新的安装包 `Setup.exe` 并执行静默升级**（安装前需退出主程序以释放文件占用）。

### 3.5 代码签名（可选，建议正式发行）

使用 Windows 代码签名证书，在构建完成后对 `EteDrop.exe` 及关键 `.dll` 执行 **signtool sign**（具体命令取决于证书介质与 CA）。签名可减少 SmartScreen 警告；安装包 `.exe` 也可在打包步骤中签名。

---

## 4. 检查清单（稳定版发布前）

- [ ] `flutter doctor` 通过，Release 构建无报错。
- [ ] `pubspec.yaml` 版本号与对外公告一致。
- [ ] macOS：对外用户已签名 + 公证（如需）；DMG 内为已 staple 的 `.app`。
- [ ] Windows：分发 **完整 `Release` 目录** 或经测试的安装包。
- [ ] 在**干净虚拟机或未安装开发环境**的机器上试装、试跑一遍。

---

## 5. 相关文档

- [`fast_send_flutter/README.md`](../fast_send_flutter/README.md) — 全平台运行与 macOS 签名/公证命令示例。
- [`doc/ffmpeg 打包教程.md`](ffmpeg%20打包教程.md) — 各平台 FFmpeg 二进制如何裁剪与放入 `assets`。
