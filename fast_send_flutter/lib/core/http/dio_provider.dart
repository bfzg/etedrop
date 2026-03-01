import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'http_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/log_interceptor.dart';

part 'dio_provider.g.dart';

// 全局 http 服务 provider
@riverpod
HttpService httpService(Ref ref) {
  // 创建 Dio 实例
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://xxx.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  // 添加拦截器
  dio.interceptors.addAll([AuthInterceptor(ref), AppLogInterceptor()]);

  return HttpService(dio);
}
