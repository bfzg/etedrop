## 裁剪范围与产品策略（统一一份 ffmpeg）

建议 **只编一份 ffmpeg/ffprobe**：同时带齐 **remux（切片 fMP4）** 与 **转码（libx264 + AAC）** 所需模块。**二进制稍大可以接受**；真正吃性能的是 **运行时转码**（CPU），由应用里 **用户手动开关** 控制是否走转码逻辑。

**应用内行为（与编译无关，同一套二进制）：**

- **关闭「视频转码」**：只对 **MP4/MOV** 做 **`-c copy`** 封装成 **fMP4**（fragmented MP4），供浏览器 MSE 边收边解。**不**对 MKV/AVI 等扩展路径做转码（可提示用户仅支持 mp4/mov，或拒绝播放）。
- **开启「视频转码」**：用 **ffprobe**（或等价信息）判断当前文件是否 **浏览器 MSE 可播**的常见组合（实践中以 **H.264 视频 + AAC 音频** 为主流；**HEVC/Vorbis等** 在部分浏览器不可用则视为需转码）。若已满足则仍 **`-c copy`** 只切片；**不满足**则 **`libx264` + `aac`** 转成可播流，再套相同 fMP4 mux 标志推给网页。

**封装范围（单文件）**：`.mp4` / `.mov` / `.m4v`，`.mkv`，`.webm`，`.avi`，`.wmv`（ASF）等。**不纳入**：HLS、DASH、多段 TS等；**不包含 FLV**。

**许可**：`libx264` 需 **`--enable-gpl`**。若产品不能接 GPL，可改用 **`libopenh264`**（BSD）等，需自行改 configure 与编码参数（本文以 x264 为例）。

---

## macOS：原生编译裁剪版（产出 ffmpeg / ffprobe）

1. 依赖
  xcode-select --install
  brew install pkg-config nasm yasm x264

2. 获取源码（8.1）
  git clone https://github.com/FFmpeg/FFmpeg.git
  cd FFmpeg
  git checkout n8.1

3. 配置裁剪（remux + 常见单文件转码，一份搞定）

  `pipe` 用于输出到 stdout（`pipe:1`），边产边推。

  **必须先让 `pkg-config` 能找到 Homebrew 的 x264**（否则会出现 `ERROR: x264 not found using pkg-config`）。在 **同一条终端会话里**、`configure` 之前执行：

  ```
  brew install x264 pkg-config
  export PKG_CONFIG_PATH="$(brew --prefix x264)/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
  pkg-config --modversion x264
  ```

  最后一行应打印 x264 版本号；若仍失败，确认路径下存在 `$(brew --prefix x264)/lib/pkgconfig/x264.pc`。

  若不想依赖 `PKG_CONFIG_PATH`，可在下面 `../configure` 末尾 **追加**（与最后一行 `\` 衔接）：

  ```
  --extra-cflags="-I$(brew --prefix x264)/include" \
  --extra-ldflags="-L$(brew --prefix x264)/lib"
  ```

  （多数情况下只设 `PKG_CONFIG_PATH` 即可，无需重复写 include/lib。）

  ```
  mkdir -p build-macos && cd build-macos

  ../configure \
    --prefix="$PWD/install" \
    --disable-everything \
    --disable-doc \
    --disable-debug \
    --disable-ffplay \
    --enable-ffmpeg \
    --enable-ffprobe \
    --enable-avformat \
    --enable-avcodec \
    --enable-avutil \
    --enable-protocol=file \
    --enable-protocol=pipe \
    --enable-demuxer=mov \
    --enable-demuxer=matroska \
    --enable-demuxer=avi \
    --enable-demuxer=asf \
    --enable-demuxer=mpegps \
    --enable-demuxer=mpegvideo \
    --enable-muxer=mp4 \
    --enable-parser=h264 \
    --enable-parser=hevc \
    --enable-parser=aac \
    --enable-decoder=h264,hevc,vp8,vp9,mpeg4,mpeg2video \
    --enable-decoder=aac,mp3,ac3,eac3,flac,vorbis,opus \
    --enable-encoder=aac \
    --enable-libx264 \
    --enable-gpl \
    --enable-swscale \
    --enable-filter=scale \
    --enable-bsf=aac_adtstoasc
  ```

  若某条 `--enable-decoder=…` 报错，可拆成多行 `--enable-decoder=h264` 等。

  **仍报 x264 / pkg-config**：确认用的是 **本机终端** 而不是未加载 Homebrew 的脚本环境；Apple Silicon 上 Homebrew 一般在 `/opt/homebrew`，需安装过 **Command Line Tools** 与 **brew 的 x264**。

4. 编译安装
  ```
  make -j"$(sysctl -n hw.ncpu)"
  make install
  ```

  产物在：
  - build-macos/install/bin/ffmpeg
  - build-macos/install/bin/ffprobe

## Windows：在 Windows 电脑上编译裁剪版（产出 ffmpeg.exe / ffprobe.exe）

建议走 MSYS2 + mingw-w64（FFmpeg 社区最常用路径，踩坑最少）。

1) 安装 MSYS2
  从 https://www.msys2.org/ 安装。打开 "MSYS2 MinGW x64" 终端。

2) 安装编译工具链与依赖
  ```
  pacman -Syu
  # 关掉窗口再打开同一个 "MinGW x64" 终端

  pacman -S --needed \
    base-devel \
    git \
    mingw-w64-x86_64-toolchain \
    mingw-w64-x86_64-nasm \
    mingw-w64-x86_64-yasm \
    mingw-w64-x86_64-pkg-config \
    mingw-w64-x86_64-x264
  ```

3) 拉源码与 checkout 8.1
  ```
  git clone https://github.com/FFmpeg/FFmpeg.git
  cd FFmpeg
  git checkout n8.1
  mkdir -p build-win && cd build-win
  ```

4) 配置裁剪

  与 **macOS 第 3 步** 使用 **同一套** `../configure` 参数块（同一 enable 列表）；若 `pkg-config` 找不到 x264，在 MSYS2 下确认 `mingw-w64-x86_64-x264` 已装，或手动加 `--extra-cflags` / `--extra-ldflags`。

5) 编译安装
  ```
  make -j"$(nproc)"
  make install
  ```

  产物在：
  - build-win/install/bin/ffmpeg.exe
  - build-win/install/bin/ffprobe.exe

## 产物体积与 ffplay（Windows / macOS 常见疑问）

**体积差（例如 Windows `ffmpeg.exe` 约 11MB、macOS `ffmpeg` 约 7MB）多数算正常**，常见原因包括：

- **链接方式**：MinGW 下常把更多依赖 **静态链进** `ffmpeg.exe`；macOS 侧 **x264 等可能以 `.dylib` 动态链接**，主程序文件会显得更瘦（总占用要连依赖一起看）。
- **运行时与 PE**：Windows 可执行文件格式、C/C++ 运行库与 **macOS Mach-O** 体积模型不同，同功能差 **百分之几十** 不奇怪。
- **符号表**：若 Windows 侧未 **strip**，会再大一截。安装目录可试：`strip install/bin/ffmpeg.exe install/bin/ffprobe.exe`（MinGW 自带 `strip`）。

**ffplay**：教程只应产出 **ffmpeg** 与 **ffprobe**。若仍出现 **`ffplay.exe`**，多半是旧目录残留、或曾用未带 `--disable-everything` 的配置编过；**configure 里已写 `--disable-ffplay`** 后 **clean 再编**（删掉 `build-win` 重来），`install/bin` 里不应再生成 ffplay。**不要**把 ffplay 打进 Flutter assets。

## Android：用 NDK 交叉编译（产出无后缀的 ffmpeg / ffprobe）

Flutter 里使用方式与桌面类似：把可执行文件打进 `assets`，首次运行解压到应用私有目录并 `chmod +x` 再 `Process.start`。

**ABI**：本文档只维护 **`arm64-v8a`**（64 位 ARM）。不再编 **`armeabi-v7a`**：32 位机已过时，新机型均为 arm64。

以下在 **macOS 或 Linux 主机** 上操作；**Windows主机** 可装 WSL2 或在 Linux CI 上编。

### 1. 准备 NDK

- 安装 [Android NDK](https://developer.android.com/ndk/downloads)（文档编写时常用 r26+）。
- 设环境变量，例如：`export ANDROID_NDK_HOME=/path/to/ndk`

NDK 里 LLVM 工具链路径形如：

- macOS Apple Silicon：`$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-arm64/bin`
- macOS Intel：`$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin`
- Linux：`$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin`

下文记为 `$LLVM_BIN`。

### 2. API Level 与目标 ABI

- `API`：建议与工程 **`minSdkVersion` 一致或略高**（例如 24）。
- **仅 arm64-v8a**：编译器 `$LLVM_BIN/aarch64-linux-android${API}-clang`，configure 使用 `--arch=aarch64`（见下节）。

### 3. 配置与编译示例（arm64-v8a + API 24）

**libx264**：须 **先为 Android 交叉编译 x264 静态库**，再在下列 `../configure` 中增加 `--enable-libx264 --enable-gpl` 以及指向该库的 `CFLAGS`/`LDFLAGS`（与桌面同一套 FFmpeg enable 列表）。仅 remux、不要转码时可去掉 x264 相关项并删掉 GPL，但与你方「统一一份、开关在应用」策略不一致，故一般仍建议编全量。

在 FFmpeg 源码目录外建 `build-android-arm64`，进入后执行（按你本机修改 `LLVM_BIN`、`API`；x264 路径自行替换）：

```
API=24
LLVM_BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-arm64/bin"
export CC="$LLVM_BIN/aarch64-linux-android${API}-clang"
export CXX="$LLVM_BIN/aarch64-linux-android${API}-clang++"
export AR="$LLVM_BIN/llvm-ar"
export RANLIB="$LLVM_BIN/llvm-ranlib"

mkdir -p build-android-arm64 && cd build-android-arm64

../configure \
  --prefix="$PWD/install" \
  --enable-cross-compile \
  --target-os=android \
  --arch=aarch64 \
  --sysroot="$LLVM_BIN/../sysroot" \
  --cc="$CC" \
  --cxx="$CXX" \
  --ar="$AR" \
  --ranlib="$RANLIB" \
  --disable-everything \
  --disable-doc \
  --disable-debug \
  --disable-ffplay \
  --enable-ffmpeg \
  --enable-ffprobe \
  --enable-avformat \
  --enable-avcodec \
  --enable-avutil \
  --enable-protocol=file \
  --enable-protocol=pipe \
  --enable-demuxer=mov \
  --enable-demuxer=matroska \
  --enable-demuxer=avi \
  --enable-demuxer=asf \
  --enable-demuxer=mpegps \
  --enable-demuxer=mpegvideo \
  --enable-muxer=mp4 \
  --enable-parser=h264 \
  --enable-parser=hevc \
  --enable-parser=aac \
  --enable-decoder=h264,hevc,vp8,vp9,mpeg4,mpeg2video \
  --enable-decoder=aac,mp3,ac3,eac3,flac,vorbis,opus \
  --enable-encoder=aac \
  --enable-libx264 \
  --enable-gpl \
  --enable-swscale \
  --enable-filter=scale \
  --enable-bsf=aac_adtstoasc

make -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
make install
```

（若尚未链接 x264，先去掉 `--enable-libx264` 与 `--enable-gpl` 仅能编 remux；待 x264 就绪后再打开。）

产物在 `build-android-arm64/install/bin/ffmpeg`、`ffprobe`。复制到 Flutter 工程例如：

- `fast_send_flutter/assets/ffmpeg/android/arm64-v8a/ffmpeg`
- `fast_send_flutter/assets/ffmpeg/android/arm64-v8a/ffprobe`

并在 `pubspec.yaml` 中声明对应 asset（仅 arm64 包体可只打 `android/arm64-v8a/ffmpeg` 等，无需 v7 目录）；**应用代码**需扩展 `ffmpeg_bundle.dart` 等平台判断（当前仓库若仅桌面，需自行接入）。

### 4. 真机注意点

- 仅在应用 **私有目录** 解压后再执行；避免把可执行文件放在共享存储。
- 在多种品牌、Android 版本上实测 `Process.start`；若遇策略限制，再考虑改为 **JNI + libavcodec** 等方案（超出本文档范围）。

---

## 运行命令参考（与应用开关对应）

**用户关闭转码**：仅处理 **MP4/MOV**，**`-c copy`** 切片 fMP4（stdout）

```
ffmpeg -hide_banner -loglevel error -i input.mp4 -map 0 -c copy \
  -movflags +frag_keyframe+empty_moov+default_base_moof -f mp4 pipe:1
```

**用户开启转码**：若 ffprobe 判定 **已是**浏览器可播（如 H.264 + AAC），仍用 **`-c copy`** 同上；否则示例（MKV → H.264/AAC fMP4，preset/crf 按产品调）

```
ffmpeg -hide_banner -loglevel error -i input.mkv \
  -map 0:v:0 -map 0:a:0? \
  -c:v libx264 -preset veryfast -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +frag_keyframe+empty_moov+default_base_moof \
  -f mp4 pipe:1
```

- seek：用 `-ss <time>` 放在 `-i` 之前（input seeking，更快），然后重启进程
