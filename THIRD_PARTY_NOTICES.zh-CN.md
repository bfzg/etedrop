# 第三方组件声明

[English](./THIRD_PARTY_NOTICES.md)

本仓库在 Flutter 客户端、NestJS 服务端、文件分享页和官网中使用了第三方开源项目。各子项目的依赖清单保存在对应目录中：

- [fast_send_flutter/pubspec.yaml](./fast_send_flutter/pubspec.yaml)
- [fast_send_server/package.json](./fast_send_server/package.json)
- [share-page-app/package.json](./share-page-app/package.json)
- [website/package.json](./website/package.json)

## FFmpeg

本仓库在 [ffmpeg_build/](./ffmpeg_build/) 目录下包含 FFmpeg 和 FFprobe 二进制文件，用于开发、打包和部分媒体处理流程。本声明不会修改这些二进制文件。

FFmpeg 有独立的许可证要求，具体义务取决于构建参数、启用的编解码器以及链接的第三方库。重新分发安装包或二进制发布物前，请确认实际 FFmpeg 构建配置、源码来源、启用组件和许可证要求，并按对应许可证提供必要的许可证文本、源码获取方式或其他声明。

FFmpeg 官方法律说明：

- https://ffmpeg.org/legal.html

## Inter 字体

应用和官网中包含 Inter 字体文件。Inter 使用 SIL Open Font License 发布。重新分发字体文件时，请保留对应许可证声明。

## 图标和资源

本项目包含应用图标、文件类型图标、SVG 资源和产品图片。将这些资源用于仓库之外的其他项目或商业材料前，请确认它们是项目自有资源，还是受第三方单独许可证约束的资源。

## 说明

本文件是开源合规提示，不替代法律意见。发布正式安装包、应用商店版本或二进制产物前，应按实际发布内容重新核对第三方组件、许可证和声明文件。
