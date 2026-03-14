/** 文件大小友好显示 */
export function formatBytes(b: number): string {
  if (b < 1024) return b + ' B'
  if (b < 1048576) return (b / 1024).toFixed(1) + ' KB'
  if (b < 1073741824) return (b / 1048576).toFixed(1) + ' MB'
  return (b / 1073741824).toFixed(2) + ' GB'
}

const EXT_ICONS: Record<string, string> = {
  pdf: '📕',
  doc: '📘',
  docx: '📘',
  xls: '📗',
  xlsx: '📗',
  ppt: '📙',
  pptx: '📙',
  zip: '📄',
  rar: '📄',
  jpg: '🖼',
  jpeg: '🖼',
  png: '🖼',
  gif: '🖼',
  svg: '🖼',
  webp: '🖼',
  mp4: '🎬',
  mov: '🎬',
  mp3: '🎵',
  wav: '🎵',
  txt: '📝',
  md: '📝',
  json: '📝',
  js: '💻',
  ts: '💻',
  py: '💻',
  dart: '💻',
}

/** 根据文件名返回 emoji 图标 */
export function fileIcon(fileName: string): string {
  const ext = (fileName.split('.').pop() || '').toLowerCase()
  return EXT_ICONS[ext] ?? '📄'
}
