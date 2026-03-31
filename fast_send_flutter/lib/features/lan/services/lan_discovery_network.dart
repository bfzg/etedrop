import 'dart:io';

/// 局域网发现用的网卡筛选与地址工具。
///
/// 设计参考 LocalSend（`common/lib/util/network_interfaces.dart` + 每网卡独立 UDP）：
/// 排除易抖动或无关接口，减少误触发重绑；仅保留适合参与发现的 IPv4。
abstract final class LanDiscoveryNetwork {
  LanDiscoveryNetwork._();

  static bool isIgnoredInterfaceName(String name) {
    final n = name.toLowerCase();
    if (n.startsWith('utun')) return true;
    if (n.contains('awdl')) return true;
    if (n.startsWith('llw')) return true;
    if (n.startsWith('bridge')) return true;
    if (n.startsWith('docker')) return true;
    if (n.startsWith('br-') || n.startsWith('veth')) return true;
    if (n.startsWith('virbr')) return true;
    if (n == 'gif0' || n == 'stf0') return true;
    // Windows：Clash for Windows 等 TAP/TUN，绑定其 IP 常 errno 10049，且不应参与局域网发现
    if (n.contains('cfw-tap')) return true;
    if (n.contains('wintun')) return true;
    if (n.contains('sing-tun')) return true;
    // sing-box / Clash.Meta 等常见 TUN 名（如 singbox_tun）；参与发现会导致 fp 抖动、1450/errno 59
    if (n.contains('singbox')) return true;
    if (n.contains('mihomo')) return true;
    if (n.contains('zerotier')) return true;
    if (n.contains('wireguard')) return true;
    if (n.contains('nordlynx')) return true;
    if (n.contains('openvpn')) return true;
    if (n.contains('tap-windows')) return true;
    return false;
  }

  static bool isEligibleIpv4(InternetAddress a) {
    if (a.type != InternetAddressType.IPv4 || a.isLoopback) return false;
    // Some environments report placeholder 0.0.0.0 addresses; never usable for LAN discovery.
    if (a.address == '0.0.0.0') return false;
    if (a.address.startsWith('169.254.')) return false;
    return true;
  }

  static List<InternetAddress> eligibleIpv4On(NetworkInterface ni) {
    final out = <InternetAddress>[];
    for (final a in ni.addresses) {
      if (isEligibleIpv4(a)) out.add(a);
    }
    return out;
  }

  /// 参与发现的网卡列表（有至少一个可用 IPv4）。
  static Future<List<NetworkInterface>> listDiscoveryInterfaces() async {
    final all = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    var picked = all
        .where((ni) => !isIgnoredInterfaceName(ni.name))
        .where((ni) => eligibleIpv4On(ni).isNotEmpty)
        .toList();
    if (picked.isEmpty) {
      picked = all.where((ni) => eligibleIpv4On(ni).isNotEmpty).toList();
    }
    return picked;
  }

  /// 用于判断是否需要重建 UDP 绑定（网卡增删或地址变化）。
  static String interfaceSetFingerprint(List<NetworkInterface> ifaces) {
    final parts = <String>[];
    for (final ni in ifaces) {
      final ips = eligibleIpv4On(ni).map((a) => a.address).toList()..sort();
      if (ips.isEmpty) continue;
      parts.add('${ni.name}:${ips.join(',')}');
    }
    parts.sort();
    return parts.join('|');
  }

  /// 常见家用 /24 子网定向广播（如 192.168.1.10 → 192.168.1.255）。
  static String? ipv4SubnetBroadcast24(String dotted) {
    final parts = dotted.split('.');
    if (parts.length != 4) return null;
    for (final s in parts) {
      final n = int.tryParse(s);
      if (n == null || n < 0 || n > 255) return null;
    }
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }
}
