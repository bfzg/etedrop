## 裁剪范围与产品策略（统一一份 ffmpeg）

建议 **只编一份 ffmpeg/ffprobe**：同时带齐 **remux（切片 fMP4）** 与 **转码（libx264 + AAC）** 所需模块。**二进制稍大可以接受**；真正吃性能的是 **运行时转码**（CPU），由应用里 **用户手动开关** 控制是否走转码逻辑。

**应用内行为（与编译无关，同一套二进制）：**

- **关闭「视频转码」**：只对 **MP4/MOV** 做 **`-c copy`** 封装成 **fMP4**（fragmented MP4），供浏览器 MSE 边收边解。**不**对 MKV/AVI 等扩展路径做转码（可提示用户仅支持 mp4/mov，或拒绝播放）。
- **开启「视频转码」**：用 **ffprobe**（或等价信息）判断当前文件是否 **浏览器 MSE 可播**的常见组合（实践中以 **H.264 视频 + AAC 音频** 为主流；**HEVC/Vorbis等** 在部分浏览器不可用则视为需转码）。若已满足则仍 **`-c copy`** 只切片；**不满足**则 **`libx264` + `aac`** 转成可播流，再套相同 fMP4 mux 标志推给网页。

**封装范围（单文件）**：`.mp4` / `.mov` / `.m4v`，`.mkv`，`.webm`，`.avi`，`.wmv`（ASF）等。**不纳入**：HLS、DASH、多段 TS等；**不包含 FLV**。

**许可**：`libx264` 需 **`--enable-gpl`**。若产品不能接 GPL，可改用 **`libopenh264`**（BSD）等，需自行改 configure 与编码参数（本文以 x264 为例）。

---

## 手机：只要切片分发、不转码（Mac 上操作）

**目标**：二进制尽量小、省电；只做 **MP4/MOV 进 → fMP4 出（`-c copy` + fragmented mux）**，不编 x264、不编 AAC 编码器、不要 `scale`/`swscale`。

**运行时命令（与桌面「关闭转码」一致）**：

```bash
ffmpeg -hide_banner -loglevel error -i input.mp4 -map 0 -c copy \
  -movflags +frag_keyframe+empty_moov+default_base_moof -f mp4 pipe:1
```

### Android（NDK 交叉编译，仅 arm64-v8a）

**0. 一次性准备**

- 已装 Android Studio / `sdkmanager`，本机有 NDK（文档以 r26+ 为例）。
- 终端里能指向 NDK 根目录，例如：

```bash
# 按你本机版本改数字
export ANDROID_NDK_HOME="$HOME/Library/Android/sdk/ndk/26.1.10909125"
```

- 确认预编译工具链目录（Apple Silicon / Intel 二选一，不存在就换路径看下）：

```bash
# Apple Silicon
export LLVM_BIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-arm64/bin"
```

**1. 拉 FFmpeg 源码**

```bash
cd ~/work   # 任意目录
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg
git checkout n8.1
```

**2. 配置（API 与工程 `minSdk` 对齐，示例 24）**

```bash
API=24
export CC="$LLVM_BIN/aarch64-linux-android${API}-clang"
export CXX="$LLVM_BIN/aarch64-linux-android${API}-clang++"
export AR="$LLVM_BIN/llvm-ar"
export RANLIB="$LLVM_BIN/llvm-ranlib"

mkdir -p build-android-arm64-remux && cd build-android-arm64-remux

../configure \
  --prefix="$PWD/install" \
  --enable-cross-compile \
  --target-os=android \
  --arch=aarch64 \
  --sysroot="$LLVM_BIN/../sysroot" \
  --cc="$CC" --cxx="$CXX" --ar="$AR" --ranlib="$RANLIB" \
  --disable-everything \
  --disable-doc --disable-debug --disable-ffplay \
  --enable-ffmpeg --enable-ffprobe \
  --enable-avformat --enable-avcodec --enable-avutil \
  --enable-protocol=file --enable-protocol=pipe \
  --enable-demuxer=mov \
  --enable-muxer=mp4 \
  --enable-parser=h264 --enable-parser=hevc --enable-parser=aac \
  --enable-bsf=aac_adtstoasc
```

若 `configure` 或后续链接报错，可再打开最小编解码器（仍不做转码，仅便于拷贝路径走通）：

```bash
# 在上一段 ../configure 末尾追加（同一行或续行）例如：
# --enable-decoder=h264,hevc,aac
```

**3. 编译安装**

```bash
make -j"$(sysctl -n hw.ncpu)"
make install
```

**4. 产物**

- `build-android-arm64-remux/install/bin/ffmpeg`
- `build-android-arm64-remux/install/bin/ffprobe`

拷进 Flutter 工程（示例路径，需在 `pubspec.yaml` 里登记 assets）：

- `assets/ffmpeg/android/arm64-v8a/ffmpeg`
- `assets/ffmpeg/android/arm64-v8a/ffprobe`

应用内：**解压到应用私有目录 → `chmod +x` → `Process.start`**（勿从共享存储直接执行）。

### iOS

- **不能像 Android 一样**把未嵌入签名的 `ffmpeg` 可执行文件打进包再在沙盒里当普通程序跑；App Store / 沙盒下一般不采用「独立 ffmpeg 二进制 + Process」方案。
- **可行路径**（择一）：
  - 用 **`ffmpeg_kit_flutter`** 等现成 FFmpeg 套件，按官方文档选 **`min` / `video` 等子包**，在 Dart 层调 remux（体积与能力按套件划分，非本文 configure 列表）。
  - 或 **Xcode 交叉编译多架构 `libav*.a` + FFI**：工作量大，需单独工程维护。
- **产品侧**：若 iPhone **只负责传文件**、浏览器/桌面负责 MSE 播放，可 **不在 iOS 内置 ffmpeg**，与「手机性能只做传输」一致。

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
    --enable-encoder=libx264 \
    --enable-libx264 \
    --enable-gpl \
    --enable-swscale \
    --enable-filter=scale \
    --enable-bsf=aac_adtstoasc
  ```

  若某条 `--enable-decoder=…` 报错，可拆成多行 `--enable-decoder=h264` 等。

  注意：在 `--disable-everything` 的前提下，仅写 `--enable-libx264` 可能仍不会把 `libx264` 编码器实际注册进最终二进制；为避免 `ffmpeg -encoders` 里看不到 `libx264`，请显式追加 `--enable-encoder=libx264`。

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

  ```bash
  pacman -Syu --needed
  # 关掉窗口再打开同一个 "MSYS2 MinGW x64" 终端

  pacman -S --needed \
    base-devel \
    git \
    make \
    diffutils \
    pkgconf \
    mingw-w64-x86_64-toolchain \
    mingw-w64-x86_64-nasm \
    mingw-w64-x86_64-yasm
  ```

3) （强烈推荐）产出“真正单文件”的 ffmpeg.exe：先编译静态 x264

> 说明：用 MSYS2 自带的 `mingw-w64-x86_64-x264` 很容易把 `libx264-xxx.dll` 动态依赖带进最终 `ffmpeg.exe`，在别的机器/目录运行时就会报 “找不到 libx264-xxx.dll”。  
> 为了做到 **单个 exe**（不依赖 `/mingw64/bin/*.dll`），这里改为 **手动编译静态 x264（`libx264.a`）**。

```bash
# 建议在一个固定工作目录，比如 /d/project
cd /d/project

rm -rf x264 x264-install
git clone https://code.videolan.org/videolan/x264.git
cd x264

./configure --prefix="/d/project/x264-install" --enable-static --disable-shared
make -j"$(nproc)"
make install

ls -la /d/project/x264-install/lib/libx264.a
```

4) 拉 FFmpeg 源码与 checkout 8.1

```bash
cd /d/project
rm -rf FFmpeg
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg
git checkout n8.1
mkdir -p build-win && cd build-win
```

5) 配置裁剪并全静态链接（真正单文件）

> 关键点：
> - 用 `PKG_CONFIG_LIBDIR` **隔离** pkg-config 搜索路径，只让它看到你编译的静态 x264。
> - 加 `-static -static-libgcc -static-libstdc++` 尽量把运行时也静态链进 exe。
> - 为了避免引入 `/mingw64/bin/zlib1.dll`、`/mingw64/bin/libiconv-2.dll` 等动态依赖，这里直接 `--disable-zlib --disable-iconv`（会牺牲少量相关能力，但换来“真单文件”稳定性）。

```bash
export PKG_CONFIG_LIBDIR="/d/project/x264-install/lib/pkgconfig"
unset PKG_CONFIG_PATH

rm -f config.h config.mak config.log ffbuild/.config

../configure \
  --prefix="$PWD/install" \
  --target-os=mingw32 \
  --arch=x86_64 \
  --disable-everything \
  --disable-doc \
  --disable-debug \
  --disable-ffplay \
  --disable-iconv \
  --disable-zlib \
  --enable-ffmpeg \
  --enable-ffprobe \
  --enable-avformat \
  --enable-avcodec \
  --enable-avutil \
  --disable-shared \
  --enable-static \
  --pkg-config-flags=--static \
  --extra-cflags="-I/d/project/x264-install/include" \
  --extra-ldflags="-L/d/project/x264-install/lib -static -static-libgcc -static-libstdc++" \
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
  --enable-bsf=aac_adtstoasc \
  --enable-swscale \
  --enable-filter=scale \
  --enable-encoder=aac \
  --enable-encoder=libx264 \
  --enable-libx264 \
  --enable-gpl \
  --disable-vaapi \
  --disable-libdrm \
  --disable-bzlib
```

6) 编译安装与验证（是否“真单文件”）

```bash
make -j"$(nproc)"
make install
strip install/bin/ffmpeg.exe install/bin/ffprobe.exe

install/bin/ffmpeg.exe -version
install/bin/ffprobe.exe -version
ldd install/bin/ffmpeg.exe
```

验证标准：
- `ldd install/bin/ffmpeg.exe` 输出里 **不应出现** `/mingw64/bin/*.dll`（如 `libx264-*.dll`、`zlib1.dll`、`libiconv-2.dll`、`libwinpthread-1.dll` 等）。
- 仍会看到 `KERNEL32.dll` / `ntdll.dll` 等 **Windows 系统 DLL**，这是正常的。

产物在：
- `build-win/install/bin/ffmpeg.exe`
- `build-win/install/bin/ffprobe.exe`

## 产物体积与 ffplay（Windows / macOS 常见疑问）

**体积差（例如 Windows `ffmpeg.exe` 约 11MB、macOS `ffmpeg` 约 7MB）多数算正常**，常见原因包括：

- **链接方式**：MinGW 下常把更多依赖 **静态链进** `ffmpeg.exe`；macOS 侧 **x264 等可能以 `.dylib` 动态链接**，主程序文件会显得更瘦（总占用要连依赖一起看）。
- **运行时与 PE**：Windows 可执行文件格式、C/C++ 运行库与 **macOS Mach-O** 体积模型不同，同功能差 **百分之几十** 不奇怪。
- **符号表**：若 Windows 侧未 **strip**，会再大一截。安装目录可试：`strip install/bin/ffmpeg.exe install/bin/ffprobe.exe`（MinGW 自带 `strip`）。

**ffplay**：教程只应产出 **ffmpeg** 与 **ffprobe**。若仍出现 **`ffplay.exe`**，多半是旧目录残留、或曾用未带 `--disable-everything` 的配置编过；**configure 里已写 `--disable-ffplay`** 后 **clean 再编**（删掉 `build-win` 重来），`install/bin` 里不应再生成 ffplay。**不要**把 ffplay 打进 Flutter assets。

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
