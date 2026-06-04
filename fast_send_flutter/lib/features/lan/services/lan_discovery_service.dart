import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/lan_device.dart';
import 'lan_discovery_network.dart';
import 'lan_presence_config.dart';

/// 局域网 UDP 发现：被动多播/子网宣告 + 单播 probe 拉活（见 [LanPresenceConfig]）。
///
/// 仍使用既有 JSON 载荷（可选 `bootId`），与旧版客户端互通。
class LanDiscoveryService {
  static final Random _rng = Random();
  static const int _byeBurstPerSocket = 5;

  static const MethodChannel _androidMulticastLockChannel = MethodChannel(
    'com.etedrop.app/lan_multicast_lock',
  );
  static const bool _androidForceUnifiedBind = true;

  final String deviceId;
  final int httpPort;
  final String os;
  final String bootId;
  String deviceName;
  int avatar;

  final _deviceController = StreamController<LanDevice>.broadcast();
  Stream<LanDevice> get onDeviceFound => _deviceController.stream;

  final _goneController = StreamController<String>.broadcast();
  Stream<String> get onDeviceGone => _goneController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _heartbeatTimer;
  Timer? _networkPollTimer;
  Timer? _startupForceRebindTimer;

  /// 避免轮询与 connectivity 同时触发时并发 `_disposeBindings` / bind。
  Future<void> _recreateChain = Future<void>.value();

  /// [stop] 时递增，使进行中的 `_recreateBindingsBody` 在 await 后放弃并释放半初始化 socket。
  int _lifecycleEpoch = 0;

  /// 避免启动时 connectivity + start 连续 force 重建时重复打印相同一行。
  String _lastUdpBindLogKey = '';
  int _lastIgnoredSocketErrorLogAtMs = 0;
  int _heartbeatTickCount = 0;

  /// 对端 `unicastProbe` 回显节流，防止双向互 ping。
  final Map<String, int> _lastEchoAtMsByPeerId = {};
  static const int _minEchoIntervalMs = 2000;

  final List<_LanDiscoveryBinding> _bindings = [];
  List<NetworkInterface> _lastEligibleIfaces = [];
  String _ifaceFingerprint = '';

  LanDiscoveryService({
    required this.deviceId,
    required this.deviceName,
    required this.httpPort,
    required this.os,
    this.avatar = 1,
    String? bootId,
  }) : bootId = bootId ?? _newBootId();

  static String _newBootId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  void updateLocalInfo({String? deviceName, int? avatar}) {
    var changed = false;
    if (deviceName != null &&
        deviceName.isNotEmpty &&
        deviceName != this.deviceName) {
      this.deviceName = deviceName;
      changed = true;
    }
    if (avatar != null && avatar > 0 && avatar != this.avatar) {
      this.avatar = avatar;
      changed = true;
    }
    if (changed) {
      announcePresence(includeGlobalBroadcast: true);
    }
  }

  /// 主动广播本机 presence（新对端、重绑、用户改昵称等）。
  void announcePresence({bool includeGlobalBroadcast = false}) {
    _announceAll(
      includeGlobalBroadcast: includeGlobalBroadcast,
      includeSubnetBroadcast: true,
    );
  }

  /// 短 burst：加速上线/重绑后的互相发现。
  void schedulePresenceBurst({String reason = 'burst'}) {
    _schedulePresenceBurst(reason: reason);
  }

  /// 向已知 IPv4 发 probe，对端回显 presence。
  void probeIpv4Addresses(Iterable<String> addresses) {
    for (final raw in addresses) {
      final ip = InternetAddress.tryParse(raw.trim());
      if (ip == null || ip.type != InternetAddressType.IPv4) continue;
      sendUnicastProbe(ip);
    }
  }

  /// 启动或重绑后：多轮 probe 拉活本地记住的设备。
  void scheduleStartupPeerProbes(Iterable<String> addresses) {
    final ips = addresses
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    if (ips.isEmpty || _bindings.isEmpty) return;
    for (final delayMs in LanPresenceConfig.startupProbeDelaysMs) {
      if (delayMs == 0) {
        probeIpv4Addresses(ips);
      } else {
        Future<void>.delayed(Duration(milliseconds: delayMs), () {
          if (_bindings.isEmpty) return;
          probeIpv4Addresses(ips);
        });
      }
    }
  }

  Future<void> start() async {
    try {
      await _setAndroidMulticastLock(true);
      _startupForceRebindTimer?.cancel();
      await _recreateBindings(force: true);
      _watchConnectivity();
      _networkPollTimer?.cancel();
      _networkPollTimer = Timer.periodic(
        LanPresenceConfig.networkPollInterval,
        (_) {
          unawaited(_recreateBindings(force: false));
        },
      );
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        LanPresenceConfig.heartbeatInterval,
        (_) {
          _heartbeatTick();
        },
      );
      _heartbeatTickCount = 0;
      _heartbeatTick();
      _schedulePresenceBurst(reason: 'start');
      _scheduleStartupForceRebindIfNeeded();
    } catch (e) {
      await _setAndroidMulticastLock(false);
      debugPrint('LAN Discovery start failed: $e');
    }
  }

  /// macOS 首次启动常见场景：本地网络权限刚放行后，已绑定的 UDP socket 仍处于“旧状态”，
  /// 发现会短时间无响应；周期性强制重绑几轮可避免“必须手动重启应用”。
  void _scheduleStartupForceRebindIfNeeded() {
    if (!Platform.isMacOS) return;
    _startupForceRebindTimer?.cancel();
    var rounds = 0;
    _startupForceRebindTimer = Timer.periodic(
      LanPresenceConfig.macosStartupRebindInterval,
      (timer) {
        rounds++;
        unawaited(_recreateBindings(force: true));
        if (rounds >= LanPresenceConfig.macosStartupRebindRounds) {
          timer.cancel();
          _startupForceRebindTimer = null;
        }
      },
    );
  }

  static Future<void> _setAndroidMulticastLock(bool acquire) async {
    if (!Platform.isAndroid) return;
    try {
      await _androidMulticastLockChannel.invokeMethod<void>(
        acquire ? 'acquire' : 'release',
      );
      if (kDebugMode) {
        debugPrint(
          'Android multicast lock ${acquire ? 'acquired' : 'released'}',
        );
      }
    } catch (e) {
      debugPrint(
        'Android multicast lock ${acquire ? 'acquire' : 'release'}: $e',
      );
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
    try {
      await _recreateBindingsBodyImpl(force: force);
    } catch (e, st) {
      debugPrint('[LAN discovery] recreate bindings failed: $e\n$st');
    }
  }

  Future<void> _recreateBindingsBodyImpl({required bool force}) async {
    final gen = _lifecycleEpoch;
    final ifaces = await LanDiscoveryNetwork.listDiscoveryInterfaces();
    if (gen != _lifecycleEpoch) return;

    final prevFp = _ifaceFingerprint;
    final fp = LanDiscoveryNetwork.interfaceSetFingerprint(ifaces);
    if (!force && fp == prevFp && _bindings.isNotEmpty) {
      return;
    }
    if (gen != _lifecycleEpoch) return;

    _ifaceFingerprint = fp;
    _lastEligibleIfaces = ifaces;
    _disposeBindings();
    // LocalSend：关闭 listener 后等待资源释放再绑端口（Windows 上可减轻 1450 / 意外断网类错误）
    if (Platform.isWindows) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (gen != _lifecycleEpoch) return;

    // macOS：按「每网卡独立 socket」绑定时，多播/子网广播常被内核投递异常；统一 bind 0.0.0.0 + 各接口
    // joinMulticast 可恢复双向发现。
    //
    // Windows：同样走单 socket。否则每块网卡（含 Hyper-V / WSL / VPN / 虚拟适配器）各开一个 UDP，
    // 易触发 ERROR_NO_SYSTEM_RESOURCES（errno 1450，中文「系统资源不足」），且每 10s 整组销毁再建会放大问题。
    var usedUnifiedBind = false;
    if (Platform.isMacOS ||
        Platform.isWindows ||
        (Platform.isAndroid && _androidForceUnifiedBind)) {
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

    final logKey = '$fp|${_bindings.length}|${_bindings.isNotEmpty}';
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

    _announceAll(includeGlobalBroadcast: false, includeSubnetBroadcast: true);
    if (force && _bindings.isNotEmpty) {
      _schedulePresenceBurst(reason: 'rebind');
    }
  }

  void _heartbeatTick() {
    _heartbeatTickCount++;
    final includeGlobal = _heartbeatTickCount %
            LanPresenceConfig.fullBroadcastEveryNHeartbeats ==
        0;
    _announceAll(
      includeGlobalBroadcast: includeGlobal,
      includeSubnetBroadcast: true,
    );
  }

  /// 短 burst：仅多播 + 子网定向，不含 255.255.255.255；包间随机间隔防抖风暴。
  void _schedulePresenceBurst({required String reason}) {
    if (_bindings.isEmpty) return;
    var n = 0;
    void sendOne() {
      if (n >= LanPresenceConfig.presenceBurstCount) return;
      n++;
      _announceAll(includeGlobalBroadcast: false, includeSubnetBroadcast: true);
      if (n < LanPresenceConfig.presenceBurstCount) {
        final ms = 60 + _rng.nextInt(120);
        Future<void>.delayed(Duration(milliseconds: ms), sendOne);
      } else if (kDebugMode) {
        debugPrint('[LAN discovery] presence burst done ($reason)');
      }
    }

    sendOne();
  }

  /// 向已知 IPv4 单播探测包（带 [unicastProbe]），对端可选回显，用于加速互相刷新 lastSeen。
  void sendUnicastProbe(InternetAddress ipv4) {
    if (ipv4.type != InternetAddressType.IPv4) return;
    if (_bindings.isEmpty) return;
    final bytes = utf8.encode(jsonEncode(_presenceMap(unicastProbe: true)));
    try {
      _bindings.first.socket.send(bytes, ipv4, LanPresenceConfig.udpPort);
    } catch (e) {
      debugPrint('LAN unicast probe → ${ipv4.address}: $e');
    }
  }

  /// 避免 RawDatagramSocket 错误进 Zone 未捕获导致进程退出。
  StreamSubscription<RawSocketEvent> _listenUdpSocket(
    RawDatagramSocket socket,
  ) {
    return socket.listen(
      (RawSocketEvent event) {
        if (event != RawSocketEvent.read) return;
        while (true) {
          final datagram = socket.receive();
          if (datagram == null) break;
          _handleMessage(datagram);
        }
      },
      onError: (Object e, StackTrace st) {
        if (_shouldIgnoreSocketError(e)) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastIgnoredSocketErrorLogAtMs > 5000) {
            _lastIgnoredSocketErrorLogAtMs = now;
            debugPrint(
              '[LAN discovery] UDP socket transient error (ignored): $e',
            );
          }
          return;
        }
        debugPrint('[LAN discovery] UDP socket error: $e\n$st');
        unawaited(_recreateBindings(force: true));
      },
      cancelOnError: false,
    );
  }

  static bool _shouldIgnoreSocketError(Object e) {
    if (e is SocketException) {
      final errno = e.osError?.errorCode;
      // macOS / BSD: 51 ENETUNREACH. Linux / Android: 101 ENETUNREACH.
      if (errno == 51 || errno == 101) return true;
      final msg = e.osError?.message.toLowerCase() ?? e.message.toLowerCase();
      if (msg.contains('network is unreachable')) return true;
      // Some stacks report "no route to host" for multicast/broadcast transiently.
      if (msg.contains('no route') || msg.contains('unreachable')) return true;
    }
    return false;
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
          LanPresenceConfig.udpPort,
          reuseAddress: true,
        );
        _setBroadcastEnabledBestEffort(socket);
        try {
          socket.joinMulticast(
            InternetAddress(LanPresenceConfig.multicastGroupIpv4),
            ni,
          );
        } catch (e) {
          debugPrint('LAN joinMulticast ${ni.name}: $e');
        }
        socket.multicastHops = 1;
        final sub = _listenUdpSocket(socket);
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
        LanPresenceConfig.udpPort,
        reuseAddress: true,
      );
      _setBroadcastEnabledBestEffort(socket);
      // Helpful for debugging discovery locally on Android; some stacks default this off.
      try {
        socket.multicastLoopback = true;
      } catch (_) {}
      for (final ni in _lastEligibleIfaces) {
        try {
          socket.joinMulticast(
            InternetAddress(LanPresenceConfig.multicastGroupIpv4),
            ni,
          );
        } catch (e) {
          debugPrint('LAN fallback joinMulticast ${ni.name}: $e');
        }
      }
      socket.multicastHops = 1;
      final sub = _listenUdpSocket(socket);
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

  Map<String, dynamic> _presenceMap({bool unicastProbe = false}) {
    final m = <String, dynamic>{
      'deviceId': deviceId,
      'deviceName': deviceName,
      'port': httpPort,
      'os': os,
      'avatar': avatar,
      'bootId': bootId,
    };
    if (unicastProbe) {
      m['unicastProbe'] = true;
    }
    return m;
  }

  void _announceAll({
    required bool includeGlobalBroadcast,
    bool includeSubnetBroadcast = true,
  }) {
    final bytes = utf8.encode(jsonEncode(_presenceMap()));
    var first = true;
    for (final b in _bindings) {
      _sendPayload(
        b,
        bytes,
        includeGlobalBroadcast: includeGlobalBroadcast && first,
        includeSubnetBroadcast: includeSubnetBroadcast,
      );
      first = false;
    }
  }

  void _sendPayload(
    _LanDiscoveryBinding b,
    List<int> bytes, {
    required bool includeGlobalBroadcast,
    bool includeSubnetBroadcast = true,
  }) {
    final socket = b.socket;
    void sendTo(InternetAddress addr) {
      try {
        if (addr.type == InternetAddressType.IPv4 &&
            addr.address == '0.0.0.0') {
          return;
        }
        socket.send(bytes, addr, LanPresenceConfig.udpPort);
      } catch (e) {
        debugPrint('LAN send ${addr.address}: $e');
      }
    }

    if (includeGlobalBroadcast) {
      sendTo(InternetAddress('255.255.255.255'));
    }
    sendTo(InternetAddress(LanPresenceConfig.multicastGroupIpv4));

    if (!includeSubnetBroadcast) {
      return;
    }

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

  void _maybeEchoUnicastProbe(
    Map<String, dynamic> map,
    String peerId,
    InternetAddress sourceAddr,
    int sourcePort,
  ) {
    if (map['unicastProbe'] != true) return;
    if (peerId == deviceId) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastEchoAtMsByPeerId[peerId] ?? 0;
    if (now - last < _minEchoIntervalMs) return;
    _lastEchoAtMsByPeerId[peerId] = now;
    if (_lastEchoAtMsByPeerId.length > 80) {
      _lastEchoAtMsByPeerId.removeWhere((_, t) => now - t > 120000);
    }
    final bytes = utf8.encode(jsonEncode(_presenceMap()));
    if (_bindings.isEmpty) return;
    try {
      _bindings.first.socket.send(bytes, sourceAddr, sourcePort);
    } catch (e) {
      debugPrint('LAN echo presence: $e');
    }
  }

  void _handleMessage(Datagram datagram) {
    final data = datagram.data;
    if (data.isEmpty) return;

    // 53317/多播上可能有其它程序的二进制流量；非 UTF-8 会触发 FormatException，与「本应用发现」无关，直接忽略。
    var i = 0;
    while (i < data.length &&
        (data[i] == 0x20 ||
            data[i] == 0x09 ||
            data[i] == 0x0a ||
            data[i] == 0x0d)) {
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

    _maybeEchoUnicastProbe(map, id, datagram.address, datagram.port);

    final device = LanDevice(
      deviceId: id,
      deviceName: map['deviceName'] as String? ?? 'Unknown',
      ip: datagram.address.address,
      port: _jsonInt(map['port'], fallback: 53318),
      os: map['os'] as String? ?? 'unknown',
      lastSeen: DateTime.now().millisecondsSinceEpoch,
      avatar: _jsonInt(map['avatar'], fallback: 1),
      isOnline: true,
      isPresenceWeak: false,
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
    unawaited(_setAndroidMulticastLock(false));

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
          includeSubnetBroadcast: true,
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
    _startupForceRebindTimer?.cancel();
    _startupForceRebindTimer = null;
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
