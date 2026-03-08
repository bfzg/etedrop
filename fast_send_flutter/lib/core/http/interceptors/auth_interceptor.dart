import 'dart:io';

import 'package:dio/dio.dart';

import '../../../services/local_storage_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = LocalStorageService.instance.get<String>(StorageKeys.authToken);
    if (token != null && token.isNotEmpty) {
      options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await LocalStorageService.instance.remove(StorageKeys.authToken);
      await LocalStorageService.instance.remove(StorageKeys.userInfo);
    }
    super.onError(err, handler);
  }
}
