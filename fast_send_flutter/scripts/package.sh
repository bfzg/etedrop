#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TARGET="${1:-}"
BUILD_NAME=""
BUILD_NUMBER=""
SKIP_CLEAN="false"
if [[ $# -gt 0 ]]; then
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-name)
      BUILD_NAME="${2:-}"
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER="${2:-}"
      shift 2
      ;;
    --skip-clean)
      SKIP_CLEAN="true"
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  cat <<'EOF'
用法:
  ./scripts/package.sh <target> [--build-name x.y.z] [--build-number n] [--skip-clean]

支持的 target:
  android-apk     构建 Android APK
  android-aab     构建 Android AAB
  ios-ipa         构建 iOS IPA (仅 macOS)
  macos-app       构建 macOS .app (仅 macOS)
  macos-dmg       构建 macOS .dmg (仅 macOS, 需 create-dmg)
  windows-exe     构建 Windows Release 目录 + 安装器（Inno Setup, 仅 Windows）
  windows-installer  同 windows-exe（兼容别名）
EOF
  exit 1
fi

EXTRA_ARGS=()
if [[ -n "$BUILD_NAME" ]]; then
  EXTRA_ARGS+=("--build-name=$BUILD_NAME")
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  EXTRA_ARGS+=("--build-number=$BUILD_NUMBER")
fi

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "错误: 该目标仅支持在 macOS 执行。"
    exit 1
  fi
}

ensure_windows() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *)
      echo "错误: 该目标仅支持在 Windows 终端执行。"
      exit 1
      ;;
  esac
}

run_flutter_prepare() {
  if [[ "$SKIP_CLEAN" != "true" ]]; then
    flutter clean
  fi
  flutter pub get
}

build_android_apk() {
  run_flutter_prepare
  flutter build apk --release "${EXTRA_ARGS[@]}"
  echo "产物: build/app/outputs/flutter-apk/app-release.apk"
}

build_android_aab() {
  run_flutter_prepare
  flutter build appbundle --release "${EXTRA_ARGS[@]}"
  echo "产物: build/app/outputs/bundle/release/app-release.aab"
}

build_ios_ipa() {
  ensure_macos
  run_flutter_prepare
  (cd ios && pod install)
  flutter build ipa --release "${EXTRA_ARGS[@]}"
  echo "产物目录: build/ios/ipa/"
}

build_macos_app() {
  ensure_macos
  run_flutter_prepare
  flutter build macos --release --tree-shake-icons "${EXTRA_ARGS[@]}"
  echo "产物: build/macos/Build/Products/Release/EteDrop.app"
}

build_macos_dmg() {
  ensure_macos
  run_flutter_prepare
  flutter build macos --release --tree-shake-icons "${EXTRA_ARGS[@]}"

  if ! command -v create-dmg >/dev/null 2>&1; then
    echo "错误: 未安装 create-dmg，请先执行: brew install create-dmg"
    exit 1
  fi

  local version
  version="$(sed -n 's/^version:[[:space:]]*\([^+[:space:]]*\).*/\1/p' pubspec.yaml | head -n 1)"
  version="${version:-dev}"

  local staging
  staging="$(mktemp -d)"
  cp -R build/macos/Build/Products/Release/EteDrop.app "$staging/"

  create-dmg \
    --volname "EteDrop" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 80 \
    --icon "EteDrop.app" 180 170 \
    --hide-extension "EteDrop.app" \
    --app-drop-link 480 170 \
    "EteDrop-${version}-macos.dmg" \
    "$staging"

  rm -rf "$staging"
  echo "产物: EteDrop-${version}-macos.dmg"
}

build_windows_exe() {
  ensure_windows
  run_flutter_prepare
  flutter build windows --release "${EXTRA_ARGS[@]}"
  echo "产物目录: build/windows/x64/runner/Release/"
}

find_iscc_windows() {
  # 优先用 PowerShell 定位 ISCC.exe（用户级/系统级安装都覆盖）
  local ps_cmd
  ps_cmd=$(
    cat <<'EOF'
$p = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
if (-not $p) {
  $candidates = @(
    "C:\Program Files*",
    (Join-Path $env:LOCALAPPDATA "Programs")
  )
  $p = $candidates |
    Where-Object { Test-Path $_ } |
    ForEach-Object {
      Get-ChildItem $_ -Recurse -Filter ISCC.exe -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    } |
    Where-Object { $_ } |
    Select-Object -First 1
}
if ($p) { Write-Output $p }
EOF
  )

  local win_path=""
  win_path="$(powershell.exe -NoProfile -Command "$ps_cmd" 2>/dev/null | tr -d '\r' | head -n 1)"
  if [[ -z "$win_path" ]]; then
    return 1
  fi

  # 直接返回 Windows 路径。后续通过 cmd.exe 调用，避免 MSYS 路径/引号问题。
  echo "$win_path"
}

build_windows_installer() {
  ensure_windows

  # 先构建 Release 目录
  build_windows_exe

  # 再用 Inno Setup 生成安装器
  local iscc
  if ! iscc="$(find_iscc_windows)"; then
    echo "错误: 未找到 ISCC.exe（Inno Setup 命令行编译器）。"
    echo "请先安装 Inno Setup: https://jrsoftware.org/isinfo.php"
    exit 1
  fi

  local version
  version="$(sed -n 's/^version:[[:space:]]*\([^+[:space:]]*\).*/\1/p' pubspec.yaml | head -n 1)"
  version="${version:-dev}"

  echo "使用 ISCC: $iscc"

  # 通过 PowerShell 调用 ISCC，并显式指定工作目录，避免 Git Bash/MSYS 的 cmd 引号/路径解析问题。
  local win_root
  if command -v cygpath >/dev/null 2>&1; then
    win_root="$(cygpath -w "$ROOT_DIR")"
  else
    win_root="$(cd "$ROOT_DIR" && pwd -W 2>/dev/null)" || win_root="$ROOT_DIR"
  fi

  local ps_run
  ps_run=$(
    cat <<EOF
\$ErrorActionPreference = "Stop"
\$iscc = "${iscc//\\/\\\\}"
\$ver = "$version"
Set-Location -LiteralPath "${win_root//\\/\\\\}"
& \$iscc "/DMyAppVersion=\$ver" "installer\\windows\\EteDrop.iss"
if (\$LASTEXITCODE -ne 0) { exit \$LASTEXITCODE }
EOF
  )

  powershell.exe -NoProfile -Command "$ps_run" \
    || {
      echo "错误: Inno Setup 编译失败（见上方 ISCC 输出）。"
      exit 1
    }

  echo "安装器输出目录: installer/windows/dist/"
}

case "$TARGET" in
  android-apk) build_android_apk ;;
  android-aab) build_android_aab ;;
  ios-ipa) build_ios_ipa ;;
  macos-app) build_macos_app ;;
  macos-dmg) build_macos_dmg ;;
  windows-exe) build_windows_installer ;;
  windows-installer) build_windows_installer ;;
  *)
    echo "错误: 不支持的 target: $TARGET"
    exit 1
    ;;
esac
