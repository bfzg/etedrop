/**
 * 根据文件信息返回 public/svg 下对应的图标 SVG 路径。
 * 开发与部署均使用根路径 /svg/xxx，由 Vite / Nest 静态目录提供。
 */
const SVG_PREFIX = 'wenjianleixing-biaozhuntu-'

const EXT_TO_SVG: Record<string, string> = {
  // 文档
  pdf: 'PDFwendang',
  doc: 'Wordwendang',
  docx: 'Wordwendang',
  // 表格
  xls: 'gongzuobiao',
  xlsx: 'gongzuobiao',
  csv: 'gongzuobiao',
  // 演示
  ppt: 'huandengpian',
  pptx: 'huandengpian',
  // 压缩
  zip: 'yasuowenjian',
  rar: 'yasuowenjian',
  '7z': 'yasuowenjian',
  tar: 'yasuowenjian',
  gz: 'yasuowenjian',
  // 图片
  jpg: 'tupianwenjian',
  jpeg: 'tupianwenjian',
  png: 'tupianwenjian',
  gif: 'tupianwenjian',
  webp: 'tupianwenjian',
  bmp: 'tupianwenjian',
  ico: 'tupianwenjian',
  svg: 'tupianwenjian',
  // 视频
  mp4: 'shipinwenjian',
  mov: 'shipinwenjian',
  avi: 'shipinwenjian',
  webm: 'shipinwenjian',
  mkv: 'shipinwenjian',
  wmv: 'shipinwenjian',
  flv: 'shipinwenjian',
  // 音频
  mp3: 'shengyinwenjian',
  wav: 'shengyinwenjian',
  flac: 'shengyinwenjian',
  aac: 'shengyinwenjian',
  m4a: 'shengyinwenjian',
  // 文本/代码
  txt: 'jishiben',
  md: 'jishiben',
  json: 'jishiben',
  js: 'jishiben',
  ts: 'jishiben',
  jsx: 'jishiben',
  tsx: 'jishiben',
  py: 'jishiben',
  dart: 'jishiben',
  html: 'jishiben',
  css: 'jishiben',
  xml: 'jishiben',
  yaml: 'jishiben',
  yml: 'jishiben',
}

const DEFAULT_SVG = 'weizhiwenjian'

/** 开发时 public 在根路径，部署后静态资源在 /share/ 下 */
const SVG_BASE = import.meta.env.DEV ? '' : '/share/'

/**
 * 根据文件名返回对应图标的 SVG 路径（可直接用于 img src）。
 */
export function getFileIconSvgPath(fileName: string): string {
  const ext = (fileName.split('.').pop() || '').toLowerCase()
  const name = EXT_TO_SVG[ext] ?? DEFAULT_SVG
  return `${SVG_BASE}svg/${SVG_PREFIX}${name}.svg`
}

export interface FileIconSvgProps {
  /** 文件名或扩展名，用于选择图标 */
  fileName: string
  /** 可选样式，如尺寸 */
  className?: string
  /** 可选 alt */
  alt?: string
}
