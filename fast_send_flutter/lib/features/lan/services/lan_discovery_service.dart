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
  final int httpPort;
  final String os;
  String deviceName;
  int avatar;

  final _deviceController = StreamController<LanDevice>.broadcast();
  Stream<LanDevice> get onDeviceFound => _deviceController.stream;

  LanDiscoveryService({
    required this.deviceId,
    required this.deviceName,
    required this.httpPort,
    required this.os,
    this.avatar = 1,
  });

  void updateLocalInfo({String? deviceName, int? avatar}) {
    var changed = false;
    if (deviceName != null && deviceName.isNotEmpty && deviceName != this.deviceName) {
      this.deviceName = deviceName;
      changed = true;
    }
    if (avatar != null && avatar > 0 && avatar != this.avatar) {
      this.avatar = avatar;
      changed = true;
    }
    if (changed) {
      unawaited(_broadcastPresence());
    }
  }

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
      unawaited(_broadcastPresence());
    });
    unawaited(_broadcastPresence());
  }

  Future<void> _broadcastPresence() async {
    if (_socket == null) return;

    final payload = jsonEncode({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'port': httpPort,
      'os': os,
      'avatar': avatar,
    });

    final bytes = utf8.encode(payload);
    final socket = _socket!;

    void sendTo(InternetAddress addr) {
      try {
        socket.send(bytes, addr, _broadcastPort);
      } catch (e) {
        debugPrint('LAN broadcast to ${addr.address} failed: $e');
      }
    }

    // 全局广播（部分路由器/系统会丢弃）
    sendTo(InternetAddress('255.255.255.255'));

    // 各网卡子网定向广播（/24），显著改善 macOS ↔ Windows 等跨平台发现
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final seen = <String>{};
      for (final ni in ifaces) {
        for (final a in ni.addresses) {
          if (a.type != InternetAddressType.IPv4 || a.isLoopback) continue;
          final bcast = _ipv4SubnetBroadcast24(a.address);
          if (bcast == null || seen.contains(bcast)) continue;
          seen.add(bcast);
          try {
            sendTo(InternetAddress(bcast));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('LAN NetworkInterface.list for broadcast: $e');
    }
  }

  /// 按常见家用局域网 /24 计算定向广播地址（如 192.168.1.10 → 192.168.1.255）
  static String? _ipv4SubnetBroadcast24(String dotted) {
    final parts = dotted.split('.');
    if (parts.length != 4) return null;
    for (final s in parts) {
      final n = int.tryParse(s);
      if (n == null || n < 0 || n > 255) return null;
    }
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }

  void _handleMessage(Datagram datagram) {
    try {
      final jsonStr = utf8.decode(datagram.data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final id = map['deviceId'] as String?;
      if (id == null) return;

      // 不过滤本机：环回/反射的广播会让单机也能在列表里看到自己（网格里用「You」区分）
      final device = LanDevice(
        deviceId: id,
        deviceName: map['deviceName'] as String? ?? 'Unknown',
        ip: datagram.address.address,
        port: _jsonInt(map['port'], fallback: 53318),
        os: map['os'] as String? ?? 'unknown',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        avatar: _jsonInt(map['avatar'], fallback: 1),
      );

      _deviceController.add(device);
    } catch (e) {
      debugPrint('LAN discovery parse error: $e');
    }
  }

  static int _jsonInt(Object? value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  void stop() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
  }
}
