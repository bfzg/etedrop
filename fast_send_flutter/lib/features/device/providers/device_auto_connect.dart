import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'device_provider.dart';

/// 应用启动后自动连接信令服务器。在 App.build 里 ref.read 触发。
final deviceAutoConnectProvider = Provider<void>((ref) {
  final manager = ref.read(deviceManagerProvider);
  if (!manager.isConnected && !manager.isConnecting) {
    Future.microtask(() => manager.connectToServer());
  }
});
