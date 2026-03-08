/// 格式化工具方法
class FormatUtils {
  FormatUtils._();

  /// 将字节数转换为人类可读的格式，如 "1.5 MB"
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 将毫秒时间戳转换为 "yyyy-MM-dd HH:mm" 格式
  static String dateTime(int milliseconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
