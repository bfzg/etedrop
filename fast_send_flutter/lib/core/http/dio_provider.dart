import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/constants.dart';
import 'http_service.dart';

part 'dio_provider.g.dart';

@riverpod
HttpService httpService(Ref ref) {
  final service = HttpService(baseUrl: AppConstants.apiBaseUrl);
  ref.onDispose(service.dispose);
  return service;
}
