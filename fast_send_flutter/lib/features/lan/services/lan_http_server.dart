import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class LanHttpServer {
  HttpServer? _server;
  final String saveDirectory;
  final String deviceId;
  final Future<bool> Function({
    required String fileName,
    required String senderName,
    required int fileSize,
    required int senderAvatar,
  })? onReceiveRequest;
  final Function(String fileName, double progress)? onProgress;
  final Function(String fileName)? onComplete;
  final Function(String fileName, String error)? onError;

  LanHttpServer({
    required this.saveDirectory,
    required this.deviceId,
    this.onReceiveRequest,
    this.onProgress,
    this.onComplete,
    this.onError,
  });

  Future<int> start({int port = 0}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    debugPrint('LAN HTTP Server listening on port ${_server!.port}');

    _server!.listen(_handleRequest);
    return _server!.port;
  }

  void stop() {
    _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      if (request.method == 'GET' && request.uri.path == '/ping') {
        _handlePing(request);
      } else if (request.method == 'POST' && request.uri.path == '/upload') {
        await _handleUpload(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (e) {
      debugPrint('HTTP Server Error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  void _handlePing(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'status': 'ok', 'deviceId': deviceId}));
    request.response.close();
  }

  Future<void> _handleUpload(HttpRequest request) async {
    final fileNameEncoded = request.headers.value('X-File-Name');
    final senderNameEncoded = request.headers.value('X-Sender-Name');
    final senderAvatarStr = request.headers.value('X-Sender-Avatar');
    final fileSizeStr = request.headers.value('X-File-Size');

    if (fileNameEncoded == null || senderNameEncoded == null) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing headers');
      await request.response.close();
      return;
    }

    final fileName = Uri.decodeComponent(fileNameEncoded);
    final senderName = Uri.decodeComponent(senderNameEncoded);
    final fileSize = int.tryParse(fileSizeStr ?? '0') ?? 0;
    final senderAvatar = int.tryParse(senderAvatarStr ?? '1') ?? 1;

    // Ask user for permission (if callback provided)
    if (onReceiveRequest != null) {
      final accepted = await onReceiveRequest!(
        fileName: fileName,
        senderName: senderName,
        fileSize: fileSize,
        senderAvatar: senderAvatar,
      );
      if (accepted != true) {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.write('Rejected by user');
        await request.response.close();
        return;
      }
    }

    final savePath = p.join(saveDirectory, fileName);
    final file = File(savePath);
    final sink = file.openWrite();

    int receivedBytes = 0;

    try {
      await for (final chunk in request) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (fileSize > 0 && onProgress != null) {
          onProgress!(fileName, receivedBytes / fileSize);
        }
      }
      await sink.close();

      request.response.statusCode = HttpStatus.ok;
      request.response.write('Success');
      await request.response.close();

      onComplete?.call(fileName);
    } catch (e) {
      await sink.close();
      onError?.call(fileName, e.toString());
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }
}
