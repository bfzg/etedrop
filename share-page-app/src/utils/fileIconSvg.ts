/**
 * 根据文件信息返回 public/svg 下对应的图标 SVG 路径。
 * 开发与部署均使用根路径 /svg/xxx，由 Vite / Nest 静态目录提供。
 */
const EXT_TO_SVG_FILE: Record<string, string> = {
  // 图片
  jpg: 'image-file.svg',
  jpeg: 'image-file.svg',
  png: 'image-file.svg',
  gif: 'image-file.svg',
  webp: 'image-file.svg',
  bmp: 'image-file.svg',
  ico: 'image-file.svg',
  svg: 'image-file.svg',

  // 视频
  mp4: 'video-file.svg',
  mov: 'video-file.svg',
  avi: 'video-file.svg',
  webm: 'video-file.svg',
  mkv: 'video-file.svg',
  wmv: 'video-file.svg',
  flv: 'video-file.svg',

  // 音频
  mp3: 'music.svg',
  wav: 'music.svg',
  flac: 'music.svg',
  aac: 'music.svg',
  m4a: 'music.svg',
  ogg: 'music.svg',

  // 文档
  pdf: 'ptf-file.svg', // 项目现有命名
  doc: 'word-file.svg',
  docx: 'word-file.svg',
  // 表格
  xls: 'excel-file.svg',
  xlsx: 'excel-file.svg',
  csv: 'excel-file.svg',
  // 演示
  ppt: 'ppt-file.svg',
  pptx: 'ppt-file.svg',

  // 压缩
  zip: 'zip.svg',
  rar: 'zip.svg',
  '7z': 'zip.svg',
  tar: 'zip.svg',
  gz: 'zip.svg',

  // 安装包 / 可执行
  apk: 'apk.svg',
  exe: 'exe.svg',
  dmg: 'dmg.svg',
  msi: 'msi.svg',
  ipa: 'ipa.svg',

  // 文本
  txt: 'txt-file.svg',
  md: 'txt-file.svg',
  log: 'txt-file.svg',

  // 链接
  url: 'link-file.svg',
  webloc: 'link-file.svg',
  lnk: 'link-file.svg',
}

const DEFAULT_SVG_FILE = 'unknown.svg'

/** 开发时 public 在根路径，部署后静态资源在 /share/ 下 */
const SVG_BASE = import.meta.env.DEV ? '' : '/share/'

/**
 * 根据文件名返回对应图标的 SVG 路径（可直接用于 img src）。
 */
export function getFileIconSvgPath(fileName: string): string {
  const ext = safeExtension(fileName)
  const svgFile = EXT_TO_SVG_FILE[ext] ?? DEFAULT_SVG_FILE
  return `${SVG_BASE}svg/${svgFile}`
}

export interface FileIconSvgProps {
  /** 文件名或扩展名，用于选择图标 */
  fileName: string
  /** 可选样式，如尺寸 */
  className?: string
  /** 可选 alt */
  alt?: string
}

function safeExtension(fileName: string): string {
  const trimmed = fileName.trim()
  if (!trimmed) return ''
  const dot = trimmed.lastIndexOf('.')
  if (dot <= 0 || dot === trimmed.length - 1) return ''
  return trimmed.slice(dot + 1).toLowerCase()
}
