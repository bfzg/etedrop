// 与 Web 分享页 `share-page-app/src/utils/shareFilePreviewKind.ts` 对齐。

/// 浏览器内建预览能力分类（不含 Office 等需专用软件的类型）。
enum SharePreviewKind {
  video,
  image,
  pdf,
  audio,
  text,
  none,
}

SharePreviewKind sharePreviewKindForFileName(String name) {
  final ext = _fileExtension(name);
  if (ext.isEmpty) return SharePreviewKind.none;
  if (ext == 'pdf') return SharePreviewKind.pdf;
  if (_videoStreamExts.contains(ext)) return SharePreviewKind.video;
  if (_imageExts.contains(ext)) return SharePreviewKind.image;
  if (_audioExts.contains(ext)) return SharePreviewKind.audio;
  if (_textExts.contains(ext)) return SharePreviewKind.text;
  return SharePreviewKind.none;
}

const _videoStreamExts = {'mp4'};

const _imageExts = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'bmp',
  'webp',
  'ico',
  'svg',
};

const _audioExts = {
  'mp3',
  'wav',
  'ogg',
  'm4a',
  'aac',
  'flac',
  'opus',
};

const _textExts = {
  'txt',
  'text',
  'md',
  'log',
  'json',
  'xml',
  'yaml',
  'yml',
  'toml',
  'ini',
  'csv',
  'tsv',
  'js',
  'mjs',
  'cjs',
  'ts',
  'jsx',
  'tsx',
  'vue',
  'svelte',
  'py',
  'dart',
  'java',
  'go',
  'rs',
  'c',
  'cc',
  'cpp',
  'h',
  'hpp',
  'cs',
  'kt',
  'swift',
  'rb',
  'php',
  'sh',
  'bash',
  'zsh',
  'sql',
  'graphql',
  'html',
  'htm',
  'css',
  'scss',
  'sass',
  'less',
  'env',
  'gitignore',
  'dockerignore',
  'properties',
  'gradle',
  'cmake',
  'lock',
};

String _fileExtension(String fileName) {
  final t = fileName.trim();
  final i = t.lastIndexOf('.');
  if (i <= 0 || i == t.length - 1) return '';
  return t.substring(i + 1).toLowerCase();
}
