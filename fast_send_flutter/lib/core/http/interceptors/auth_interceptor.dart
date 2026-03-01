import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/local_storeage_service.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;
  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await LocalStorageService.instance.get(StorageKeys.authToken);
    if (token != null && token.isNotEmpty) {
      options.headers[HttpHeaders.authorizationHeader] = "Bearer $token";
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // token过期，清理 & 跳转登录
      await LocalStorageService.instance.remove(StorageKeys.authToken);
      await LocalStorageService.instance.remove(StorageKeys.userInfo);
    }
    super.onError(err, handler);
  }
}
