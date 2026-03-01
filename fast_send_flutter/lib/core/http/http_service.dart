import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';

class HttpService {
  final Dio _dio;

  HttpService(this._dio);

  Dio get client => _dio;

  // 通用请求包装，带错误处理
  Future<Response<T>> requestTryCatch<T>(Future<Response<T>> Function() func) async {
    try {
      return await func();
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          throw Exception("连接超时");
        case DioExceptionType.receiveTimeout:
          throw Exception("响应超时");
        case DioExceptionType.badResponse:
          throw Exception("服务器错误: ${e.response?.statusCode}");
        default:
          throw Exception(e.message ?? "网络异常");
      }
    }
  }

  // GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return requestTryCatch(
      () => _dio.get<T>(path, queryParameters: queryParameters),
    );
  }

  // POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String contentTypeHeader = Headers.jsonContentType,
  }) {
    return requestTryCatch(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {HttpHeaders.contentTypeHeader: contentTypeHeader},
        ),
      ),
    );
  }

  // PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) {
    return requestTryCatch(
      () => _dio.put<T>(path, data: data),
    );
  }

  // DELETE
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return requestTryCatch(
      () => _dio.delete<T>(path, data: data, queryParameters: queryParameters),
    );
  }

  // 处理 Uint8List 响应
  Response parseResponse(Response r) {
    if (r.data is Uint8List) {
      Map<String, dynamic> str = json.decode(utf8.decode(r.data as Uint8List));
      r.data = str;
    }
    return r;
  }
}
