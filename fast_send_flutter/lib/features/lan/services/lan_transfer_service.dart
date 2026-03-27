import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../models/lan_share_payload.dart';

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
    required int senderAvatar,
    required String senderDeviceId,
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
      senderAvatar: senderAvatar,
      senderDeviceId: senderDeviceId,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> postShareOffer({
    required String ip,
    required int port,
    required LanShareOfferPayload payload,
  }) async {
    final url = 'http://$ip:$port/share-offer';
    await _dio.post(
      url,
      data: payload.toJson(),
      options: Options(
        headers: {Headers.contentTypeHeader: 'application/json'},
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  Future<void> postShareAccept({
    required String senderHost,
    required int senderPort,
    required LanShareAcceptPayload payload,
  }) async {
    final url = 'http://$senderHost:$senderPort/share-accept';
    await _dio.post(
      url,
      data: payload.toJson(),
      options: Options(
        headers: {Headers.contentTypeHeader: 'application/json'},
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  Future<void> postShareCancel({
    required String ip,
    required int port,
    required LanShareCancelPayload payload,
  }) async {
    final url = 'http://$ip:$port/share-cancel';
    await _dio.post(
      url,
      data: payload.toJson(),
      options: Options(
        headers: {Headers.contentTypeHeader: 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<void> sendFileStream({
    required String ip,
    required int port,
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderName,
    required int senderAvatar,
    required String senderDeviceId,
    String? shareId,
    int fileIndex = 0,
    int fileCount = 1,
    int batchTotalBytes = 0,
    Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = 'http://$ip:$port/upload';
    final total = batchTotalBytes > 0 ? batchTotalBytes : fileSize;

    try {
      final headers = <String, dynamic>{
        'X-File-Name': Uri.encodeComponent(fileName),
        'X-Sender-Name': Uri.encodeComponent(senderName),
        'X-Sender-Avatar': senderAvatar.toString(),
        'X-Sender-Device-Id': senderDeviceId,
        'X-File-Size': fileSize.toString(),
        'X-File-Index': fileIndex.toString(),
        'X-File-Count': fileCount.toString(),
        'X-Batch-Total-Bytes': total.toString(),
        Headers.contentLengthHeader: fileSize,
        Headers.contentTypeHeader: 'application/octet-stream',
      };
      if (shareId != null) {
        headers['X-Share-Id'] = shareId;
      }
      await _dio.post(
        url,
        data: fileStream,
        options: Options(
          headers: headers,
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
