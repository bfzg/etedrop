import '../../features/cloud/models/fs_entry.dart';

const String _svgBase = 'assets/svg';

/// 根据文件条目返回对应的 SVG 图标资源路径
String svgIconForEntry(FsEntry entry) {
  if (entry.isDirectory) return '$_svgBase/folder.svg';
  return svgIconForFileName(entry.name);
}

/// 根据文件名（含后缀）返回对应的 SVG 图标资源路径
String svgIconForFileName(String name) {
  final ext = _safeExtension(name);
  switch (ext) {
    // 图片
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
    case 'svg':
      return '$_svgBase/image-file.svg';

    // 视频
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'mkv':
    case 'wmv':
      return '$_svgBase/video-file.svg';

    // 音频
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
    case 'ogg':
      return '$_svgBase/music.svg';

    // 文档
    case 'pdf':
      // 资源文件名为 ptf-file.svg（项目现有命名）
      return '$_svgBase/ptf-file.svg';
    case 'doc':
    case 'docx':
      return '$_svgBase/word-file.svg';
    case 'xls':
    case 'xlsx':
    case 'csv':
      return '$_svgBase/excel-file.svg';
    case 'ppt':
    case 'pptx':
      return '$_svgBase/ppt-file.svg';

    // 压缩包
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return '$_svgBase/zip.svg';

    // 安装包 / 可执行
    case 'apk':
      return '$_svgBase/apk.svg';
    case 'exe':
      return '$_svgBase/exe.svg';
    case 'dmg':
      return '$_svgBase/dmg.svg';
    case 'msi':
      return '$_svgBase/msi.svg';
    case 'ipa':
      return '$_svgBase/ipa.svg';

    // 文本
    case 'txt':
    case 'md':
    case 'log':
      return '$_svgBase/txt-file.svg';

    // 链接
    case 'url':
    case 'webloc':
    case 'lnk':
      return '$_svgBase/link-file.svg';

    default:
      return '$_svgBase/unknown.svg';
  }
}

String _safeExtension(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final dot = trimmed.lastIndexOf('.');
  if (dot <= 0 || dot == trimmed.length - 1) return '';
  return trimmed.substring(dot + 1).toLowerCase();
}

