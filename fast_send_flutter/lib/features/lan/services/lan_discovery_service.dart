import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/lan_device.dart';
import 'lan_discovery_network.dart';

/// 局域网 UDP 发现（与 LocalSend 同类方案：每块网卡独立 socket + 多播成员，避免单 socket 上频繁 leave/join 丢包）。
///
/// 仍使用既有 JSON 载荷，与旧版客户端互通。
class LanDiscoveryService {
  static const int _udpPort = 53317;
  static const String _multicastGroupIpv4 = '239.255.88.117';

  /// 与 [LanManager] 中 `_lanDeviceStaleMs` 配合：需明显小于离线阈值、留足丢包容忍。
  static const Duration _heartbeatInterval = Duration(seconds: 3);
  static const Duration _networkPollInterval = Duration(seconds: 10);
  static const int _byeBurstPerSocket = 5;

  final String deviceId;
  final int httpPort;
  final String os;
  String deviceName;
  int avatar;

  final _deviceController = StreamController<LanDevice>.broadcast();
  Stream<LanDevice> get onDeviceFound => _deviceController.stream;

  final _goneController = StreamController<String>.broadcast();
  Stream<String> get onDeviceGone => _goneController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _heartbeatTimer;
  Timer? _networkPollTimer;

  /// 避免轮询与 connectivity 同时触发时并发 `_disposeBindings` / bind。
  Future<void> _recreateChain = Future<void>.value();

  /// [stop] 时递增，使进行中的 `_recreateBindingsBody` 在 await 后放弃并释放半初始化 socket。
  int _lifecycleEpoch = 0;

  /// 避免启动时 connectivity + start 连续 force 重建时重复打印相同一行。
  String _lastUdpBindLogKey = '';

  final List<_LanDiscoveryBinding> _bindings = [];
  List<NetworkInterface> _lastEligibleIfaces = [];
  String _ifaceFingerprint = '';

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
      _announceAll(includeGlobalBroadcast: true);
    }
  }

  Future<void> start() async {
    try {
      await _recreateBindings(force: true);
      _watchConnectivity();
      _networkPollTimer?.cancel();
      _networkPollTimer = Timer.periodic(_networkPollInterval, (_) {
        unawaited(_recreateBindings(force: false));
      });
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
        _announceAll(includeGlobalBroadcast: true);
      });
      _announceAll(includeGlobalBroadcast: true);
    } catch (e) {
      debugPrint('LAN Discovery start failed: $e');
    }
  }

  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> _) {
        unawaited(_recreateBindings(force: true));
      },
      onError: (Object e, StackTrace _) {
        debugPrint('LAN connectivity watch error: $e');
      },
    );
  }

  /// 网卡集合变化时整组关闭再建（对齐 LocalSend `restartListener` 思路，无热插拔 leave/join 风暴）。
  Future<void> _recreateBindings({required bool force}) {
    final run = _recreateChain.then((_) => _recreateBindingsBody(force: force));
    _recreateChain = run.catchError((Object e, StackTrace _) {
      debugPrint('LAN recreate bindings: $e');
    });
    return run;
  }

  Future<void> _recreateBindingsBody({required bool force}) async {
    final gen = _lifecycleEpoch;
    final ifaces = await LanDiscoveryNetwork.listDiscoveryInterfaces();
    if (gen != _lifecycleEpoch) return;

    final fp = LanDiscoveryNetwork.interfaceSetFingerprint(ifaces);
    if (!force && fp == _ifaceFingerprint && _bindings.isNotEmpty) {
      return;
    }
    if (gen != _lifecycleEpoch) return;

    _ifaceFingerprint = fp;
    _lastEligibleIfaces = ifaces;
    _disposeBindings();
    if (gen != _lifecycleEpoch) return;

    // macOS：按「每网卡独立 socket」绑定时，多播/子网广播常被内核投递异常；统一 bind 0.0.0.0 + 各接口
    // joinMulticast 可恢复双向发现。
    //
    // Windows：同样走单 socket。否则每块网卡（含 Hyper-V / WSL / VPN / 虚拟适配器）各开一个 UDP，
    // 易触发 ERROR_NO_SYSTEM_RESOURCES（errno 1450，中文「系统资源不足」），且每 10s 整组销毁再建会放大问题。
    var usedUnifiedBind = false;
    if (Platform.isMacOS || Platform.isWindows) {
      await _openFallbackBinding();
      usedUnifiedBind = _bindings.isNotEmpty;
      if (gen != _lifecycleEpoch) return;
    }

    if (!usedUnifiedBind) {
      for (final ni in ifaces) {
        if (gen != _lifecycleEpoch) return;
        final b = await _openBindingForInterface(ni);
        if (b != null) {
          _bindings.add(b);
        }
      }

      if (_bindings.isEmpty) {
        await _openFallbackBinding();
      }
    }
    if (gen != _lifecycleEpoch) {
      _disposeBindings();
      return;
    }

    final logKey =
        '$fp|${_bindings.length}|${_bindings.isNotEmpty}';
    if (logKey != _lastUdpBindLogKey) {
      _lastUdpBindLogKey = logKey;
      if (_bindings.isNotEmpty) {
        debugPrint(
          'LAN discovery: UDP bound on ${_bindings.length} path(s), fp=$fp',
        );
      } else {
        debugPrint('LAN discovery: no UDP bindings available');
      }
    }

    _announceAll(includeGlobalBroadcast: true);
  }

  static void _setBroadcastEnabledBestEffort(RawDatagramSocket socket) {
    try {
      socket.broadcastEnabled = true;
    } catch (e) {
      if (Platform.isMacOS) {
        debugPrint('LAN broadcastEnabled skipped on macOS: $e');
      } else {
        rethrow;
      }
    }
  }

  Future<_LanDiscoveryBinding?> _openBindingForInterface(
    NetworkInterface ni,
  ) async {
    final ips = LanDiscoveryNetwork.eligibleIpv4On(ni);
    for (final ip in ips) {
      try {
        final socket = await RawDatagramSocket.bind(
          ip,
          _udpPort,
          reuseAddress: true,
        );
        _setBroadcastEnabledBestEffort(socket);
        try {
          socket.joinMulticast(
            InternetAddress(_multicastGroupIpv4),
            ni,
          );
        } catch (e) {
          debugPrint('LAN joinMulticast ${ni.name}: $e');
        }
        socket.multicastHops = 1;
        final sub = socket.listen(
          (RawSocketEvent event) {
            if (event != RawSocketEvent.read) return;
            while (true) {
              final datagram = socket.receive();
              if (datagram == null) break;
              _handleMessage(datagram);
            }
          },
        );
        return _LanDiscoveryBinding(
          mode: _LanDiscoveryBindingMode.perInterface,
          networkInterface: ni,
          socket: socket,
          subscription: sub,
        );
      } catch (e) {
        debugPrint('LAN bind ${ip.address} (${ni.name}): $e');
      }
    }
    return null;
  }

  Future<void> _openFallbackBinding() async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _udpPort,
        reuseAddress: true,
      );
      _setBroadcastEnabledBestEffort(socket);
      for (final ni in _lastEligibleIfaces) {
        try {
          socket.joinMulticast(
            InternetAddress(_multicastGroupIpv4),
            ni,
          );
        } catch (e) {
          debugPrint('LAN fallback joinMulticast ${ni.name}: $e');
        }
      }
      socket.multicastHops = 1;
      final sub = socket.listen(
        (RawSocketEvent event) {
          if (event != RawSocketEvent.read) return;
          while (true) {
            final datagram = socket.receive();
            if (datagram == null) break;
            _handleMessage(datagram);
          }
        },
      );
      _bindings.add(
        _LanDiscoveryBinding(
          mode: _LanDiscoveryBindingMode.fallbackAny,
          networkInterface: null,
          socket: socket,
          subscription: sub,
        ),
      );
    } catch (e) {
      debugPrint('LAN fallback bind: $e');
    }
  }

  void _disposeBindings() {
    for (final b in _bindings) {
      b.subscription.cancel();
      b.socket.close();
    }
    _bindings.clear();
  }

  Map<String, dynamic> _presenceMap() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'port': httpPort,
        'os': os,
        'avatar': avatar,
      };

  void _announceAll({required bool includeGlobalBroadcast}) {
    final bytes = utf8.encode(jsonEncode(_presenceMap()));
    var first = true;
    for (final b in _bindings) {
      _sendPayload(
        b,
        bytes,
        includeGlobalBroadcast: includeGlobalBroadcast && first,
      );
      first = false;
    }
  }

  void _sendPayload(
    _LanDiscoveryBinding b,
    List<int> bytes, {
    required bool includeGlobalBroadcast,
  }) {
    final socket = b.socket;
    void sendTo(InternetAddress addr) {
      try {
        socket.send(bytes, addr, _udpPort);
      } catch (e) {
        debugPrint('LAN send ${addr.address}: $e');
      }
    }

    if (includeGlobalBroadcast) {
      sendTo(InternetAddress('255.255.255.255'));
    }
    sendTo(InternetAddress(_multicastGroupIpv4));

    final seenBcast = <String>{};
    final ifaces = b.mode == _LanDiscoveryBindingMode.fallbackAny
        ? _lastEligibleIfaces
        : [b.networkInterface!];
    for (final ni in ifaces) {
      for (final a in ni.addresses) {
        if (!LanDiscoveryNetwork.isEligibleIpv4(a)) continue;
        final bc = LanDiscoveryNetwork.ipv4SubnetBroadcast24(a.address);
        if (bc == null || seenBcast.contains(bc)) continue;
        seenBcast.add(bc);
        sendTo(InternetAddress(bc));
      }
    }
  }

  void _handleMessage(Datagram datagram) {
    final data = datagram.data;
    if (data.isEmpty) return;

    // 53317/多播上可能有其它程序的二进制流量；非 UTF-8 会触发 FormatException，与「本应用发现」无关，直接忽略。
    var i = 0;
    while (i < data.length && (data[i] == 0x20 || data[i] == 0x09 || data[i] == 0x0a || data[i] == 0x0d)) {
      i++;
    }
    if (i >= data.length || data[i] != 0x7b) {
      return; // 本协议为 JSON 对象，必须以 `{` 开头
    }

    final String jsonStr;
    try {
      jsonStr = utf8.decode(data.sublist(i));
    } on FormatException {
      return;
    }

    final Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return;
      map = Map<String, dynamic>.from(decoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LAN discovery JSON error: $e');
      }
      return;
    }

    final id = map['deviceId'] as String?;
    if (id == null) return;

    final bye = map['bye'];
    if (bye == true || bye == 1) {
      _goneController.add(id);
      return;
    }

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
  }

  static int _jsonInt(Object? value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  void stop() {
    final snapshot = List<_LanDiscoveryBinding>.from(_bindings);
    final byeBytes = utf8.encode(
      jsonEncode({'deviceId': deviceId, 'bye': true}),
    );
    var isFirstBinding = true;
    for (final b in snapshot) {
      for (var i = 0; i < _byeBurstPerSocket; i++) {
        _sendPayload(
          b,
          byeBytes,
          includeGlobalBroadcast: isFirstBinding && i == 0,
        );
      }
      isFirstBinding = false;
    }

    _lifecycleEpoch++;
    _lastUdpBindLogKey = '';

    _connectivitySub?.cancel();
    _connectivitySub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _networkPollTimer?.cancel();
    _networkPollTimer = null;
    _disposeBindings();
    _ifaceFingerprint = '';
    _lastEligibleIfaces = [];
  }
}

enum _LanDiscoveryBindingMode { perInterface, fallbackAny }

class _LanDiscoveryBinding {
  _LanDiscoveryBinding({
    required this.mode,
    required this.networkInterface,
    required this.socket,
    required this.subscription,
  });

  final _LanDiscoveryBindingMode mode;
  final NetworkInterface? networkInterface;
  final RawDatagramSocket socket;
  final StreamSubscription<RawSocketEvent> subscription;
}
