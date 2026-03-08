import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/device_manager.dart';

export 'package:hooks_riverpod/hooks_riverpod.dart' show Ref;

/// DeviceManager 全局实例（应用生命周期内不销毁）
final _globalManager = DeviceManager();

/// DeviceManager Provider —— 用 StreamProvider 监听状态变化
/// 每次 DeviceManager.notifyListeners() 都会触发 stream 更新
final deviceManagerProvider = Provider<DeviceManager>((ref) {
  return _globalManager;
});

/// 监听 DeviceManager 状态变化的 stream，UI rebuild 依赖它
final _deviceStateStreamProvider = StreamProvider<void>((ref) {
  final manager = ref.watch(deviceManagerProvider);
  return manager.stateStream;
});

/// 设备是否已连接
final deviceConnectedProvider = Provider<bool>((ref) {
  ref.watch(_deviceStateStreamProvider);
  return ref.read(deviceManagerProvider).isConnected;
});

/// 设备是否正在连接
final deviceConnectingProvider = Provider<bool>((ref) {
  ref.watch(_deviceStateStreamProvider);
  return ref.read(deviceManagerProvider).isConnecting;
});

/// 最近一次连接错误（null = 无错误）
final deviceLastConnectionErrorProvider = Provider<String?>((ref) {
  ref.watch(_deviceStateStreamProvider);
  return ref.read(deviceManagerProvider).lastError;
});

/// 设备 ID
final deviceIdProvider = Provider<String?>((ref) {
  ref.watch(_deviceStateStreamProvider);
  return ref.read(deviceManagerProvider).config?.deviceId;
});

/// 设备名称
final deviceNameProvider = Provider<String>((ref) {
  ref.watch(_deviceStateStreamProvider);
  return ref.read(deviceManagerProvider).config?.deviceName ?? '未知设备';
});

/// 连接状态枚举
final deviceConnectionStateProvider = Provider<DeviceConnectionState>((ref) {
  ref.watch(_deviceStateStreamProvider);
  return ref.read(deviceManagerProvider).state;
});
