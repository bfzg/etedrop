import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_receive_speed_provider.g.dart';

/// 接收中瞬时速度（字节/秒），按 shareId 或单条消息 id 索引；传完需 [clear]。
@Riverpod(keepAlive: true)
class TransferReceiveSpeed extends _$TransferReceiveSpeed {
  final Map<String, (DateTime t, double approxBytes)> _lastSample = {};

  @override
  Map<String, double> build() => {};

  void tick(String key, double batchProgress01, int byteBasis) {
    if (byteBasis <= 0 || key.isEmpty) return;
    final approx = batchProgress01 * byteBasis;
    final now = DateTime.now();
    final prev = _lastSample[key];
    if (prev != null) {
      final dt = now.difference(prev.$1).inMicroseconds / 1e6;
      if (dt >= 0.45) {
        final dBytes = approx - prev.$2;
        if (dBytes >= 0 && dt > 0) {
          state = {...state, key: dBytes / dt};
        }
        _lastSample[key] = (now, approx);
      }
    } else {
      _lastSample[key] = (now, approx);
    }
  }

  void clear(String key) {
    _lastSample.remove(key);
    if (!state.containsKey(key)) return;
    final next = Map<String, double>.from(state)..remove(key);
    state = next;
  }
}
