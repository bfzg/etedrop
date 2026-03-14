import { getFileIconSvgPath, type FileIconSvgProps } from '../utils/fileIconSvg'

/**
 * 根据文件信息显示对应的 SVG 图标（img 标签）。
 */
export function FileIconSvg({ fileName, className, alt = '' }: FileIconSvgProps) {
  const src = getFileIconSvgPath(fileName)
  return <img src={src} alt={alt} className={className} />
}
