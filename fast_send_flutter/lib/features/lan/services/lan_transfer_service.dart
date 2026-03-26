import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class LanTransferService {
  final Dio _dio;

  LanTransferService({Dio? dio}) : _dio = dio ?? Dio();

  Future<bool> ping(String ip, int port) async {
    try {
      final response = await _dio.get(
        'http://$ip:$port/ping',
        options: Options(sendTimeout: const Duration(seconds: 2), receiveTimeout: const Duration(seconds: 2)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendFile({
    required String ip,
    required int port,
    required String filePath,
    required String senderName,
    Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found');
    }

    final fileName = p.basename(filePath);
    final fileSize = await file.length();

    await sendFileStream(
      ip: ip,
      port: port,
      fileStream: file.openRead(),
      fileName: fileName,
      fileSize: fileSize,
      senderName: senderName,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> sendFileStream({
    required String ip,
    required int port,
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderName,
    Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = 'http://$ip:$port/upload';

    try {
      await _dio.post(
        url,
        data: fileStream,
        options: Options(
          headers: {
            'X-File-Name': Uri.encodeComponent(fileName),
            'X-Sender-Name': Uri.encodeComponent(senderName),
            'X-File-Size': fileSize.toString(),
            Headers.contentLengthHeader: fileSize,
            Headers.contentTypeHeader: 'application/octet-stream',
          },
          // Disable timeouts for large files
          sendTimeout: null,
          receiveTimeout: null,
        ),
        cancelToken: cancelToken,
        onSendProgress: (count, total) {
          if (total > 0 && onProgress != null) {
            onProgress(count / total);
          }
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == HttpStatus.forbidden) {
        throw Exception('对方拒绝了接收文件');
      }
      throw Exception('传输失败: ${e.message}');
    }
  }
}
