import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../services/local_storage_service.dart';
import '../../services/logger_service.dart';

/// 与原先 Dio [Response] 常用字段对齐，便于上层少改代码。
class HttpServiceResponse<T> {
  HttpServiceResponse({
    required this.statusCode,
    this.data,
    this.statusMessage,
  });

  final int statusCode;
  final T? data;
  final String? statusMessage;
}

/// 基于 [dart:io] [HttpClient] 的 REST 封装（鉴权、日志原拦截器逻辑内联于此）。
class HttpService {
  HttpService({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _receiveTimeout = receiveTimeout {
    _client = HttpClient();
    _client.connectionTimeout = connectTimeout;
    _client.idleTimeout = receiveTimeout;
  }

  late final HttpClient _client;
  final String _baseUrl;
  final Duration _receiveTimeout;

  void dispose() {
    _client.close(force: true);
  }

  static String _normalizeBaseUrl(String url) {
    final t = url.trim();
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  Uri _uri(String path, Map<String, dynamic>? queryParameters) {
    final p = path.startsWith('/') ? path : '/$path';
    final u = Uri.parse('$_baseUrl$p');
    if (queryParameters == null || queryParameters.isEmpty) return u;
    return u.replace(
      queryParameters: queryParameters.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
    );
  }

  void _applyAuth(HttpClientRequest request) {
    final token = LocalStorageService.instance.get<String>(StorageKeys.authToken);
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
  }

  Future<void> _clearAuthIfUnauthorized(int statusCode) async {
    if (statusCode == HttpStatus.unauthorized) {
      await LocalStorageService.instance.remove(StorageKeys.authToken);
      await LocalStorageService.instance.remove(StorageKeys.userInfo);
    }
  }

  void _logRequest(String method, Uri uri, Object? body) {
    logger.d('➡️ $method $uri');
    logger.d('Data: $body');
  }

  void _logResponse(int statusCode, String preview) {
    logger.d('✅ Response [$statusCode] $preview');
  }

  void _logError(Object e, StackTrace? st) {
    logger.e('❌ Error: $e', error: e, stackTrace: st);
  }

  Object? _decodeJsonBody(String text) {
    if (text.isEmpty) return null;
    return jsonDecode(text);
  }

  Future<String> _readBody(HttpClientResponse response) async {
    final b = BytesBuilder(copy: false);
    await for (final part in response) {
      b.add(part);
    }
    return utf8.decode(b.takeBytes());
  }

  // 通用请求包装，带错误处理
  Future<HttpServiceResponse<T>> requestTryCatch<T>(
    Future<HttpServiceResponse<T>> Function() func,
  ) async {
    try {
      return await func();
    } on SocketException catch (e, st) {
      _logError(e, st);
      throw Exception('网络异常: $e');
    } on HttpException catch (e, st) {
      _logError(e, st);
      throw Exception(e.message);
    } on TimeoutException catch (e, st) {
      _logError(e, st);
      throw Exception('请求超时');
    } on FormatException catch (e, st) {
      _logError(e, st);
      throw Exception('响应解析失败');
    }
  }

  Future<HttpServiceResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return requestTryCatch(() async {
      final uri = _uri(path, queryParameters);
      _logRequest('GET', uri, null);
      final req = await _client.getUrl(uri);
      _applyAuth(req);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(_receiveTimeout);
      final text = await _readBody(res).timeout(_receiveTimeout);
      _logResponse(res.statusCode, text.length > 2048 ? '${text.substring(0, 2048)}…' : text);
      await _clearAuthIfUnauthorized(res.statusCode);
      if (res.statusCode >= 400) {
        throw Exception('服务器错误: ${res.statusCode}');
      }
      return HttpServiceResponse<T>(
        statusCode: res.statusCode,
        data: _decodeJsonBody(text) as T?,
      );
    });
  }

  Future<HttpServiceResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String contentTypeHeader = 'application/json',
  }) {
    return requestTryCatch(() async {
      final uri = _uri(path, queryParameters);
      _logRequest('POST', uri, data);
      final req = await _client.postUrl(uri);
      _applyAuth(req);
      req.headers.set(HttpHeaders.contentTypeHeader, contentTypeHeader);
      final bodyBytes = _encodeBody(data, contentTypeHeader);
      req.contentLength = bodyBytes.length;
      req.add(bodyBytes);
      final res = await req.close().timeout(_receiveTimeout);
      final text = await _readBody(res).timeout(_receiveTimeout);
      _logResponse(res.statusCode, text.length > 2048 ? '${text.substring(0, 2048)}…' : text);
      await _clearAuthIfUnauthorized(res.statusCode);
      if (res.statusCode >= 400) {
        throw Exception('服务器错误: ${res.statusCode}');
      }
      return HttpServiceResponse<T>(
        statusCode: res.statusCode,
        data: text.isEmpty ? null : _decodeJsonBody(text) as T?,
      );
    });
  }

  Future<HttpServiceResponse<T>> put<T>(
    String path, {
    dynamic data,
  }) {
    return requestTryCatch(() async {
      final uri = _uri(path, null);
      _logRequest('PUT', uri, data);
      final req = await _client.putUrl(uri);
      _applyAuth(req);
      req.headers.contentType = ContentType.json;
      final bodyBytes = utf8.encode(jsonEncode(data));
      req.contentLength = bodyBytes.length;
      req.add(bodyBytes);
      final res = await req.close().timeout(_receiveTimeout);
      final text = await _readBody(res).timeout(_receiveTimeout);
      _logResponse(res.statusCode, text.length > 2048 ? '${text.substring(0, 2048)}…' : text);
      await _clearAuthIfUnauthorized(res.statusCode);
      if (res.statusCode >= 400) {
        throw Exception('服务器错误: ${res.statusCode}');
      }
      return HttpServiceResponse<T>(
        statusCode: res.statusCode,
        data: text.isEmpty ? null : _decodeJsonBody(text) as T?,
      );
    });
  }

  Future<HttpServiceResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return requestTryCatch(() async {
      final uri = _uri(path, queryParameters);
      _logRequest('DELETE', uri, data);
      final req = await _client.openUrl('DELETE', uri);
      _applyAuth(req);
      if (data != null) {
        req.headers.contentType = ContentType.json;
        final bodyBytes = utf8.encode(jsonEncode(data));
        req.contentLength = bodyBytes.length;
        req.add(bodyBytes);
      }
      final res = await req.close().timeout(_receiveTimeout);
      final text = await _readBody(res).timeout(_receiveTimeout);
      _logResponse(res.statusCode, text.length > 2048 ? '${text.substring(0, 2048)}…' : text);
      await _clearAuthIfUnauthorized(res.statusCode);
      if (res.statusCode >= 400) {
        throw Exception('服务器错误: ${res.statusCode}');
      }
      return HttpServiceResponse<T>(
        statusCode: res.statusCode,
        data: text.isEmpty ? null : _decodeJsonBody(text) as T?,
      );
    });
  }

  List<int> _encodeBody(dynamic data, String contentType) {
    if (data == null) return [];
    if (contentType.contains('json')) {
      return utf8.encode(jsonEncode(data));
    }
    if (data is String) return utf8.encode(data);
    return utf8.encode(data.toString());
  }
}
