/// 轻量取消标记（替代 Dio [CancelToken]，不依赖 dio 包）。
class LanCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }
}
