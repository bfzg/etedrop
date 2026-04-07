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
  windows-exe     构建 Windows Release 目录 (仅 Windows)
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

case "$TARGET" in
  android-apk) build_android_apk ;;
  android-aab) build_android_aab ;;
  ios-ipa) build_ios_ipa ;;
  macos-app) build_macos_app ;;
  macos-dmg) build_macos_dmg ;;
  windows-exe) build_windows_exe ;;
  *)
    echo "错误: 不支持的 target: $TARGET"
    exit 1
    ;;
esac
