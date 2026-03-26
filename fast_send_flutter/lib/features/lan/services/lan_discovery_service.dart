import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/lan_device.dart';

class LanDiscoveryService {
  static const int _broadcastPort = 53317;
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  
  final String deviceId;
  final String deviceName;
  final int httpPort;
  final String os;

  final _deviceController = StreamController<LanDevice>.broadcast();
  Stream<LanDevice> get onDeviceFound => _deviceController.stream;

  LanDiscoveryService({
    required this.deviceId,
    required this.deviceName,
    required this.httpPort,
    required this.os,
  });

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handleMessage(datagram);
          }
        }
      });

      _startBroadcasting();
    } catch (e) {
      debugPrint('LAN Discovery start failed: $e');
    }
  }

  void _startBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _broadcastPresence();
    });
    _broadcastPresence(); // immediate first broadcast
  }

  void _broadcastPresence() {
    if (_socket == null) return;

    final payload = jsonEncode({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'port': httpPort,
      'os': os,
    });

    final bytes = utf8.encode(payload);
    
    try {
      _socket!.send(bytes, InternetAddress('255.255.255.255'), _broadcastPort);
    } catch (e) {
      // Ignore broadcast errors (e.g. network unreachable)
    }
  }

  void _handleMessage(Datagram datagram) {
    try {
      final jsonStr = utf8.decode(datagram.data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final id = map['deviceId'] as String?;
      if (id == null) return; 
      
      // TODO: 生产环境应过滤掉自己，开发测试时可注释掉此行以便单机调试
      // if (id == deviceId) return;

      final device = LanDevice(
        deviceId: id,
        deviceName: map['deviceName'] as String? ?? 'Unknown',
        ip: datagram.address.address,
        port: map['port'] as int? ?? 53318,
        os: map['os'] as String? ?? 'unknown',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      );

      _deviceController.add(device);
    } catch (e) {
      // Ignore invalid messages
    }
  }

  void stop() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
  }
}
