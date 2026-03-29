import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/resumable_transfer.dart';
import '../models/lan_share_payload.dart';

class LanTransferService {
  final Dio _dio;

  LanTransferService({Dio? dio}) : _dio = dio ?? Dio();

  Future<bool> ping(String ip, int port) async {
    try {
      final response = await _dio.get(
        'http://$ip:$port/ping',
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
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

  /// 查询对端已写入字节数（与 [sendFileStream] 使用相同的 `fileName` / `shareId` / `fileIndex`）。
  Future<int> fetchRemoteWrittenBytes({
    required String ip,
    required int port,
    required String fileName,
    String? shareId,
    int fileIndex = 0,
  }) async {
    final uri = Uri(
      scheme: 'http',
      host: ip,
      port: port,
      path: '/upload-state',
      queryParameters: <String, String>{
        'file': fileName,
        'shareId': shareId ?? '',
        'fileIndex': '$fileIndex',
      },
    );
    final response = await _dio.getUri(
      uri,
      options: Options(
        responseType: ResponseType.json,
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    dynamic data = response.data;
    if (data is String) {
      data = jsonDecode(data) as Map<String, dynamic>?;
    }
    if (data is! Map) return 0;
    final o = data['offset'];
    if (o is int) return o;
    if (o is num) return o.toInt();
    return 0;
  }

  Future<void> _postUploadOctetStream({
    required String url,
    required Stream<List<int>> fileStream,
    required Map<String, dynamic> headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    final uploadHeaders = Map<String, dynamic>.from(headers)
      ..[HttpHeaders.connectionHeader] = 'close';
    return _dio.post<void>(
      url,
      data: fileStream,
      options: Options(
        headers: uploadHeaders,
        sendTimeout: null,
        receiveTimeout: null,
        persistentConnection: false,
      ),
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
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

    /// 从源文件的该偏移开始发送（请求体长度为 fileSize - resumeFromOffset）。
    int resumeFromOffset = 0,
    Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = 'http://$ip:$port/upload';
    final total = batchTotalBytes > 0 ? batchTotalBytes : fileSize;
    final remaining = resumableRemainingBytes(
      totalSize: fileSize,
      resumeOffset: resumeFromOffset,
    );

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
        ResumableTransferHeaders.resumeOffset: resumeFromOffset.toString(),
        Headers.contentLengthHeader: remaining,
        Headers.contentTypeHeader: 'application/octet-stream',
      };
      if (shareId != null) {
        headers['X-Share-Id'] = shareId;
      }
      await _postUploadOctetStream(
        url: url,
        fileStream: fileStream,
        headers: headers,
        cancelToken: cancelToken,
        onSendProgress: (count, totalBytes) {
          if (totalBytes > 0 && onProgress != null) {
            onProgress(count / totalBytes);
          }
        },
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw Exception('传输已取消');
      }
      if (e.response?.statusCode == HttpStatus.forbidden) {
        throw Exception('对方拒绝了接收文件');
      }
      if (e.response?.statusCode == HttpStatus.conflict) {
        throw Exception('断点不一致，请重试: ${e.response?.data}');
      }
      throw Exception('传输失败: ${e.message}');
    }
  }

  /// 大文件：失败自动按对端已写字节续传；取消请使用 [cancelToken]。
  Future<void> sendLocalFileWithResume({
    required String ip,
    required int port,
    required String filePath,
    required String senderName,
    required int senderAvatar,
    required String senderDeviceId,
    String? shareId,
    int fileIndex = 0,
    int fileCount = 1,
    int batchTotalBytes = 0,
    Function(double fileInBatchProgress)? onProgress,
    CancelToken? cancelToken,
    int maxAttempts = 48,
  }) async {
    final f = File(filePath);
    if (!await f.exists()) {
      throw Exception('File not found');
    }
    final fileName = p.basename(filePath);
    final fileSize = await f.length();

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (cancelToken?.isCancelled == true) {
        throw Exception('传输已取消');
      }

      var start = 0;
      try {
        start = await fetchRemoteWrittenBytes(
          ip: ip,
          port: port,
          fileName: fileName,
          shareId: shareId,
          fileIndex: fileIndex,
        );
      } catch (_) {
        start = 0;
      }

      if (start < 0) start = 0;
      if (start > fileSize) start = fileSize;
      if (start == fileSize) {
        return;
      }

      final url = 'http://$ip:$port/upload';
      final total = batchTotalBytes > 0 ? batchTotalBytes : fileSize;
      final remaining = resumableRemainingBytes(
        totalSize: fileSize,
        resumeOffset: start,
      );
      final headers = <String, dynamic>{
        'X-File-Name': Uri.encodeComponent(fileName),
        'X-Sender-Name': Uri.encodeComponent(senderName),
        'X-Sender-Avatar': senderAvatar.toString(),
        'X-Sender-Device-Id': senderDeviceId,
        'X-File-Size': fileSize.toString(),
        'X-File-Index': fileIndex.toString(),
        'X-File-Count': fileCount.toString(),
        'X-Batch-Total-Bytes': total.toString(),
        ResumableTransferHeaders.resumeOffset: start.toString(),
        Headers.contentLengthHeader: remaining,
        Headers.contentTypeHeader: 'application/octet-stream',
      };
      if (shareId != null) {
        headers['X-Share-Id'] = shareId;
      }

      try {
        await _postUploadOctetStream(
          url: url,
          fileStream: f.openRead(start),
          headers: headers,
          cancelToken: cancelToken,
          onSendProgress: (count, totalBytes) {
            if (totalBytes > 0 && onProgress != null) {
              onProgress(count / totalBytes);
            }
          },
        );
        return;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          throw Exception('传输已取消');
        }
        if (e.response?.statusCode == HttpStatus.forbidden) {
          throw Exception('对方拒绝了接收文件');
        }
        if (attempt >= maxAttempts - 1) {
          if (e.response?.statusCode == HttpStatus.conflict) {
            throw Exception('断点不一致，请重试: ${e.response?.data}');
          }
          throw Exception('传输失败: ${e.message}');
        }
        await Future<void>.delayed(Duration(milliseconds: 200 + attempt * 100));
      }
    }
  }
}
