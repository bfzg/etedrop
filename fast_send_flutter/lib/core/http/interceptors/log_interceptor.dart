import 'package:dio/dio.dart';
import '../../../services/logger_service.dart';

class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d("➡️ ${options.method} ${options.uri}");
    logger.d("Headers: ${options.headers}");
    logger.d("Data: ${options.data}");
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d("✅ Response [${response.statusCode}] ${response.data}");
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e("❌ Error: ${err.message}", error: err.error, stackTrace: err.stackTrace);
    super.onError(err, handler);
  }
}