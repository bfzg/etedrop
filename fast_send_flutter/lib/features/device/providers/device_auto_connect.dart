import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../settings/providers/server_line_provider.dart';
import 'device_provider.dart';

/// 应用启动后按当前线路注入地址并连接信令服务器。在 App.build 里 ref.read 触发。
final deviceAutoConnectProvider = Provider<void>((ref) {
  final endpoints = ref.read(serverEndpointsProvider);
  ref.read(deviceManagerProvider).applyEndpoints(endpoints);
  final manager = ref.read(deviceManagerProvider);
  if (!manager.isConnected && !manager.isConnecting) {
    Future.microtask(() => manager.connectToServer());
  }
});
