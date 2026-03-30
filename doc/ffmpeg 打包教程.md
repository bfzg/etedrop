## macOS：原生编译裁剪版（产出 ffmpeg / ffprobe）

1. 依赖
  xcode-select --install
  brew install pkg-config nasm yasm

2. 获取源码（8.1）
  git clone https://github.com/FFmpeg/FFmpeg.git
  cd FFmpeg
  git checkout n8.1

3. 配置裁剪（只保留 MP4/MOV → fMP4 需要的模块）

  ```mkdir -p build-macos && cd build-macos
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
    --enable-demuxer=mov \
    --enable-muxer=mp4 \
    --enable-parser=h264 \
    --enable-parser=hevc \
    --enable-parser=aac \
    --enable-bsf=aac_adtstoasc
  说明：这是“偏保守的最小集”，满足你们 copy + fMP4 的主路径；不含编码器（不做转码）。
  ```

  

4. 编译安装
  ```
  make -j"$(sysctl -n hw.ncpu)"
  make install
  产物在：
  build-macos/install/bin/ffmpeg
  build-macos/install/bin/ffprobe
  Windows：在 Windows 电脑上编译裁剪版（产出 ffmpeg.exe / ffprobe.exe）
  Windows 我建议走 MSYS2 + mingw-w64（FFmpeg 社区最常用路径，踩坑最少）。
  ```

## windows

1) 安装 MSYS2
  从 https://www.msys2.org/ 安装。打开 “MSYS2 MinGW x64” 终端。

2) 安装编译工具链与依赖
  pacman -Syu

```
# 关掉窗口再打开同一个 “MinGW x64” 终端

pacman -S --needed \
  base-devel \
  git \
  mingw-w64-x86_64-toolchain \
  mingw-w64-x86_64-nasm \
  mingw-w64-x86_64-yasm \
  mingw-w64-x86_64-pkg-config

3) 拉源码与 checkout 8.1
   git clone https://github.com/FFmpeg/FFmpeg.git
   cd FFmpeg
   git checkout n8.1
   mkdir -p build-win && cd build-win
4) 配置裁剪（同样只做 remux→fMP4）
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
     --enable-demuxer=mov \
     --enable-muxer=mp4 \
     --enable-parser=h264 \
     --enable-parser=hevc \
     --enable-parser=aac \
     --enable-bsf=aac_adtstoasc
5) 编译安装
   make -j"$(nproc)"
   make install
   
产物在：
build-win/install/bin/ffmpeg.exe
build-win/install/bin/ffprobe.exe
```



你们“fMP4 播放”最关键的运行命令（后续接 WebRTC/MSE 时用）
只 remux（不转码）的典型命令形态会类似：

生成 fMP4（文件输出）：-c copy + -movflags +frag_keyframe+empty_moov+default_base_moof（具体参数你们 PoC 后再定）
seek：用 -ss <time>（通常放输入前更快）然后重启进程
如果你告诉我你们准备 输出到文件还是 输出到 stdout（边产边推），我可以把这条命令也一并写成你们项目里可直接用的模板（含 seek 重启策略）。