import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/constants.dart';
import 'http_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/log_interceptor.dart';

part 'dio_provider.g.dart';

@riverpod
HttpService httpService(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.addAll([AuthInterceptor(), AppLogInterceptor()]);

  return HttpService(dio);
}
