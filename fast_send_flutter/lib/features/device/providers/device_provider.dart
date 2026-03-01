import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/device_config.dart';
import '../services/device_manager.dart';

part 'device_provider.g.dart';

/// DeviceManager 单例 Provider
@riverpod
class DeviceManagerNotifier extends _$DeviceManagerNotifier {
  final DeviceManager _manager = DeviceManager();

  @override
  DeviceManager build() {
    ref.onDispose(() {
      _manager.disconnect();
    });
    return _manager;
  }

  Future<DeviceConfig> loadConfig() async {
    return _manager.loadConfig();
  }

  Future<void> connectToServer() async {
    await _manager.connectToServer();
    ref.invalidateSelf();
  }

  void disconnect() {
    _manager.disconnect();
    ref.invalidateSelf();
  }

  Future<void> setDeviceName(String name) async {
    await _manager.setDeviceName(name);
    ref.invalidateSelf();
  }
}

/// 设备连接状态
@riverpod
bool deviceConnected(Ref ref) {
  final manager = ref.watch(deviceManagerProvider);
  return manager.isConnected;
}

/// 设备 ID
@riverpod
String? deviceId(Ref ref) {
  final manager = ref.watch(deviceManagerProvider);
  return manager.config?.deviceId;
}

/// 设备名称
@riverpod
String deviceName(Ref ref) {
  final manager = ref.watch(deviceManagerProvider);
  return manager.config?.deviceName ?? '未知设备';
}
