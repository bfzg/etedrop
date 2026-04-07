# Windows 安装器（Inno Setup）与升级说明

本目录提供 `EteDrop` 的 Windows 安装器脚本（Inno Setup）。

## 目标

- **默认安装到用户目录**：`%LocalAppData%\EteDrop`（无需管理员权限，适合在线升级）
- **支持选择安装目录**：向导可修改安装路径
- **支持覆盖升级**：保持 `AppId` 不变即可识别旧版本并升级

## 前置条件

- Windows 安装 [Inno Setup](https://jrsoftware.org/isinfo.php)
- 先构建 Flutter Windows Release：

```bash
cd fast_send_flutter
flutter build windows --release
```

产物目录应存在：

`build\windows\x64\runner\Release\`

## 编译安装包

用 Inno Setup 自带的 `ISCC.exe` 编译脚本。

> 如果你安装的 Inno Setup 没有包含 `ChineseSimplified.isl`（可选语言包），脚本会自动只启用英文以保证编译不失败。

在 `fast_send_flutter` 目录下执行（PowerShell）：

```powershell
$ISCC = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
if (-not $ISCC) {
  $candidates = @(
    "C:\Program Files*",
    (Join-Path $env:LOCALAPPDATA "Programs")
  )
  $ISCC = $candidates |
    Where-Object { Test-Path $_ } |
    ForEach-Object {
      Get-ChildItem $_ -Recurse -Filter ISCC.exe -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    } |
    Where-Object { $_ } |
    Select-Object -First 1
}
if (-not $ISCC) { throw "未找到 ISCC.exe：请先安装 Inno Setup。" }

$ver = (Select-String -Path .\pubspec.yaml -Pattern '^version:\s*' | Select-Object -First 1).Line.Split(':')[1].Trim().Split('+')[0]
& $ISCC `
  /DMyAppVersion=$ver `
  /DReleaseDir="..\..\build\windows\x64\runner\Release" `
  .\installer\windows\EteDrop.iss
```

输出默认在：

`fast_send_flutter\dist\EteDrop-Setup-<version>-win-x64.exe`

## 升级包策略（关键点）

- **保持 `EteDrop.iss` 里的 `AppId` 永久不变**：这是 Inno 识别“同一应用升级”的关键
- 每次发布用新的 `AppVersion`（如 `1.0.2`）重新编译 `Setup.exe`，该 `Setup.exe` 就是你的“升级包”

## 在线升级（建议做法）

推荐让应用下载新的 `Setup.exe`，然后以静默参数运行：

- ` /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS `

注意：升级时需要先退出主程序，否则文件可能被占用导致升级失败。
