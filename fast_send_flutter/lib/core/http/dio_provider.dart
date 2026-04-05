import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/settings/providers/server_line_provider.dart';
import 'http_service.dart';

part 'dio_provider.g.dart';

@riverpod
HttpService httpService(Ref ref) {
  final base = ref.watch(serverEndpointsProvider).apiBaseUrl;
  final service = HttpService(baseUrl: base);
  ref.onDispose(service.dispose);
  return service;
}
