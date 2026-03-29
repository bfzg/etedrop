import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/lan_device.dart';

class LanDiscoveryService {
  static const int _broadcastPort = 53317;
  /// 子网广播地址列表缓存 TTL，避免每轮广播都 `NetworkInterface.list`。
  static const Duration _subnetBcastCacheTtl = Duration(seconds: 45);
  /// 启动后一段时间内较快发心跳，便于新设备尽快出现在列表。
  static const Duration _fastHeartbeatPhase = Duration(seconds: 90);
  static const Duration _fastHeartbeatInterval = Duration(seconds: 2);
  /// 稳定后降频；离线阈值见 `lan_provider` 的 `_lanDeviceStaleMs`，需明显大于本间隔。
  static const Duration _steadyHeartbeatInterval = Duration(seconds: 5);
  /// `connectivity_plus` 在「Wi‑Fi → Wi‑Fi」时常不派发事件（结果仍为 wifi），用网卡 IPv4 指纹轮询补齐。
  static const Duration _ifaceFingerprintPollInterval = Duration(seconds: 3);

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _ifacePollTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  DateTime? _heartbeatPhaseStartedAt;
  DateTime? _subnetBcastCacheAt;
  List<String> _subnetBroadcastAddresses = const [];
  String _ifaceFingerprint = '';

  final String deviceId;
  final int httpPort;
  final String os;
  String deviceName;
  int avatar;

  final _deviceController = StreamController<LanDevice>.broadcast();
  Stream<LanDevice> get onDeviceFound => _deviceController.stream;

  final _goneController = StreamController<String>.broadcast();
  /// 对端正常退出时广播 `bye`，此处收到 [deviceId] 后应从列表立即移除。
  Stream<String> get onDeviceGone => _goneController.stream;

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
      unawaited(_broadcastPresence(forceSubnetRefresh: false));
    }
  }

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          // 一次 read 事件里可能积压多包，需排空队列，否则会漏更新 lastSeen 导致误判离线
          while (true) {
            final datagram = _socket!.receive();
            if (datagram == null) break;
            _handleMessage(datagram);
          }
        }
      });

      _startBroadcasting();
      _watchConnectivity();
      _startIfaceFingerprintPolling();
    } catch (e) {
      debugPrint('LAN Discovery start failed: $e');
    }
  }

  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> _) {
        if (_socket == null) return;
        // Wi‑Fi / 网络切换后子网会变：强制重算定向广播并重发，避免卡在旧缓存
        _heartbeatPhaseStartedAt = DateTime.now();
        unawaited(_broadcastPresence(forceSubnetRefresh: true));
      },
      onError: (Object e, StackTrace _) {
        debugPrint('LAN connectivity watch error: $e');
      },
    );
  }

  void _startIfaceFingerprintPolling() {
    _ifacePollTimer?.cancel();
    _ifacePollTimer = Timer.periodic(_ifaceFingerprintPollInterval, (_) {
      unawaited(_pollIfaceFingerprintIfChanged());
    });
  }

  Future<void> _pollIfaceFingerprintIfChanged() async {
    if (_socket == null) return;
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final fp = _fingerprintForIfaces(ifaces);
      if (fp == _ifaceFingerprint) return;
      _ifaceFingerprint = fp;
      _subnetBroadcastAddresses = _subnetBcastsFromIfaces(ifaces);
      _subnetBcastCacheAt = DateTime.now();
      _heartbeatPhaseStartedAt = DateTime.now();
      _emitPresencePayload();
    } catch (e) {
      debugPrint('LAN iface fingerprint poll: $e');
    }
  }

  void _startBroadcasting() {
    _broadcastTimer?.cancel();
    _heartbeatPhaseStartedAt = DateTime.now();
    unawaited(_broadcastPresence(forceSubnetRefresh: true));
    _scheduleNextHeartbeat();
  }

  void _scheduleNextHeartbeat() {
    _broadcastTimer?.cancel();
    final started = _heartbeatPhaseStartedAt;
    final interval = started != null &&
            DateTime.now().difference(started) < _fastHeartbeatPhase
        ? _fastHeartbeatInterval
        : _steadyHeartbeatInterval;
    _broadcastTimer = Timer(interval, () {
      unawaited(_broadcastPresence(forceSubnetRefresh: false));
      _scheduleNextHeartbeat();
    });
  }

  Future<void> _refreshSubnetBroadcastTargets({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _subnetBcastCacheAt != null &&
        now.difference(_subnetBcastCacheAt!) < _subnetBcastCacheTtl) {
      return;
    }
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      _ifaceFingerprint = _fingerprintForIfaces(ifaces);
      _subnetBroadcastAddresses = _subnetBcastsFromIfaces(ifaces);
      _subnetBcastCacheAt = now;
    } catch (e) {
      debugPrint('LAN NetworkInterface.list for broadcast: $e');
    }
  }

  Future<void> _broadcastPresence({required bool forceSubnetRefresh}) async {
    if (_socket == null) return;
    await _refreshSubnetBroadcastTargets(force: forceSubnetRefresh);
    _emitPresencePayload();
  }

  void _emitPresencePayload() {
    _sendJsonToLan({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'port': httpPort,
      'os': os,
      'avatar': avatar,
    });
  }

  void _sendJsonToLan(Map<String, dynamic> map) {
    final socket = _socket;
    if (socket == null) return;

    final bytes = utf8.encode(jsonEncode(map));

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
    for (final bcast in _subnetBroadcastAddresses) {
      try {
        sendTo(InternetAddress(bcast));
      } catch (_) {}
    }
  }

  static String _fingerprintForIfaces(List<NetworkInterface> ifaces) {
    final ips = <String>[];
    for (final ni in ifaces) {
      for (final a in ni.addresses) {
        if (a.type != InternetAddressType.IPv4 || a.isLoopback) continue;
        ips.add(a.address);
      }
    }
    ips.sort();
    return ips.join('|');
  }

  static List<String> _subnetBcastsFromIfaces(List<NetworkInterface> ifaces) {
    final seen = <String>{};
    final next = <String>[];
    for (final ni in ifaces) {
      for (final a in ni.addresses) {
        if (a.type != InternetAddressType.IPv4 || a.isLoopback) continue;
        final bcast = _ipv4SubnetBroadcast24(a.address);
        if (bcast == null || seen.contains(bcast)) continue;
        seen.add(bcast);
        next.add(bcast);
      }
    }
    return next;
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

      final bye = map['bye'];
      if (bye == true || bye == 1) {
        _goneController.add(id);
        return;
      }

      // 不过滤本机：环回/反射的广播会让单机也能在列表里看到自己（网格里用「You」区分）
      final device = LanDevice(
        deviceId: id,
        deviceName: map['deviceName'] as String? ?? 'Unknown',
        ip: datagram.address.address,
        port: _jsonInt(map['port'], fallback: 53318),
        os: map['os'] as String? ?? 'unknown',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
        avatar: _jsonInt(map['avatar'], fallback: 1),
        isOnline: true,
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
    // 正常退出时通知局域网内其他实例立即摘牌（崩溃/强杀则仍依赖对端超时）
    _sendJsonToLan({'deviceId': deviceId, 'bye': true});

    _connectivitySub?.cancel();
    _connectivitySub = null;
    _ifacePollTimer?.cancel();
    _ifacePollTimer = null;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _heartbeatPhaseStartedAt = null;
    _subnetBcastCacheAt = null;
    _subnetBroadcastAddresses = const [];
    _ifaceFingerprint = '';
    _socket?.close();
    _socket = null;
  }
}
