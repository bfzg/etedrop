import '../../features/cloud/models/fs_entry.dart';

const String _base = 'assets/images/fileType';

/// 根据文件条目返回对应的 PNG 图标资源路径（assets/fileType）。
String fileTypePngForEntry(FsEntry entry) {
  if (entry.isDirectory)
    return '$_base/wenjianleixing-biaozhuntu-wenjianjia.png';
  return fileTypePngForFileName(entry.name);
}

/// 根据文件名（含后缀）返回对应的 PNG 图标资源路径（assets/fileType）。
String fileTypePngForFileName(String name) {
  final ext = _safeExtension(name);
  switch (ext) {
    // 图片
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'webp':
    case 'ico':
    case 'svg':
      return '$_base/wenjianleixing-biaozhuntu-tupianwenjian.png';

    // 视频
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'mkv':
    case 'wmv':
    case 'webm':
    case 'flv':
      return '$_base/wenjianleixing-biaozhuntu-shipinwenjian.png';

    // 音频
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
    case 'ogg':
    case 'm4a':
      return '$_base/wenjianleixing-biaozhuntu-shengyinwenjian.png';

    // 文档
    case 'pdf':
      return '$_base/wenjianleixing-biaozhuntu-PDFwendang.png';
    case 'doc':
    case 'docx':
      return '$_base/wenjianleixing-biaozhuntu-Wordwendang.png';
    case 'xls':
    case 'xlsx':
    case 'csv':
      return '$_base/wenjianleixing-biaozhuntu-gongzuobiao.png';
    case 'ppt':
    case 'pptx':
      return '$_base/wenjianleixing-biaozhuntu-huandengpian.png';

    // 压缩包
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return '$_base/wenjianleixing-biaozhuntu-yasuowenjian.png';

    // 文本/代码
    case 'txt':
    case 'md':
    case 'log':
    case 'json':
    case 'xml':
    case 'yaml':
    case 'yml':
    case 'toml':
    case 'js':
    case 'ts':
    case 'jsx':
    case 'tsx':
    case 'py':
    case 'dart':
    case 'java':
    case 'go':
    case 'rs':
    case 'c':
    case 'cpp':
    case 'h':
    case 'html':
    case 'css':
      return '$_base/wenjianleixing-biaozhuntu-jishiben.png';

    // 链接
    case 'url':
    case 'webloc':
    case 'lnk':
      return '$_base/wenjianleixing-biaozhuntu-lianjie.png';

    default:
      return '$_base/wenjianleixing-biaozhuntu-weizhiwenjian.png';
  }
}

String _safeExtension(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final dot = trimmed.lastIndexOf('.');
  if (dot <= 0 || dot == trimmed.length - 1) return '';
  return trimmed.substring(dot + 1).toLowerCase();
}
