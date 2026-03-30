## macOS：原生编译裁剪版（产出 ffmpeg / ffprobe）

1. 依赖
  xcode-select --install
  brew install pkg-config nasm yasm

2. 获取源码（8.1）
  git clone https://github.com/FFmpeg/FFmpeg.git
  cd FFmpeg
  git checkout n8.1

3. 配置裁剪（只保留 MP4/MOV → fMP4 需要的模块）

  ```
  mkdir -p build-macos && cd build-macos

  ../configure \
    --prefix="$PWD/install" \
    --disable-everything \
    --disable-doc \
    --disable-debug \
    --enable-ffmpeg \
    --enable-ffprobe \
    --enable-avformat \
    --enable-avcodec \
    --enable-avutil \
    --enable-protocol=file \
    --enable-protocol=pipe \
    --enable-demuxer=mov \
    --enable-muxer=mp4 \
    --enable-parser=h264 \
    --enable-parser=hevc \
    --enable-parser=aac \
    --enable-bsf=aac_adtstoasc
  ```

  说明：pipe 协议用于输出到 stdout（pipe:1），实现边转边推流。不含编码器（不做转码）。

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
    mingw-w64-x86_64-pkg-config
  ```

3) 拉源码与 checkout 8.1
  ```
  git clone https://github.com/FFmpeg/FFmpeg.git
  cd FFmpeg
  git checkout n8.1
  mkdir -p build-win && cd build-win
  ```

4) 配置裁剪（同样只做 remux→fMP4）
  ```
  ../configure \
    --prefix="$PWD/install" \
    --disable-everything \
    --disable-doc \
    --disable-debug \
    --enable-ffmpeg \
    --enable-ffprobe \
    --enable-avformat \
    --enable-avcodec \
    --enable-avutil \
    --enable-protocol=file \
    --enable-protocol=pipe \
    --enable-demuxer=mov \
    --enable-muxer=mp4 \
    --enable-parser=h264 \
    --enable-parser=hevc \
    --enable-parser=aac \
    --enable-bsf=aac_adtstoasc
  ```

5) 编译安装
  ```
  make -j"$(nproc)"
  make install
  ```

  产物在：
  - build-win/install/bin/ffmpeg.exe
  - build-win/install/bin/ffprobe.exe

## 运行命令参考

只 remux（不转码）的典型命令：

- 生成 fMP4（stdout 输出，边产边推）：
  ```
  ffmpeg -hide_banner -loglevel error -i input.mp4 -map 0 -c copy \
    -movflags +frag_keyframe+empty_moov+default_base_moof -f mp4 pipe:1
  ```
- seek：用 `-ss <time>` 放在 `-i` 之前（input seeking，更快），然后重启进程
