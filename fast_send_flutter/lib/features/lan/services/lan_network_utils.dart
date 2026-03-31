import 'dart:io';

/// 获取本机局域网 IPv4（用于分享回调地址）
Future<String?> getLanIPv4() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    for (final ni in interfaces) {
      for (final addr in ni.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
  } catch (_) {}
  return null;
}

/// 获取“到对端 [peerIpv4] 这条路由上”本机实际会使用的 IPv4。
///
/// 目的：多网卡/虚拟网卡环境下，避免拿到错误的本机 IP（例如 VPN/TUN/虚拟适配器），
/// 导致接收方回调 `senderHost:senderPort` 时连错地址、出现 Connection refused。
Future<String?> getOutboundLocalIPv4ForPeer(String peerIpv4) async {
  try {
    final peerParts = peerIpv4.split('.');
    if (peerParts.length != 4) return null;
    final peerPrefix = '${peerParts[0]}.${peerParts[1]}.${peerParts[2]}.';

    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );

    String? fallback;
    for (final ni in interfaces) {
      for (final addr in ni.addresses) {
        if (addr.type != InternetAddressType.IPv4) continue;
        if (addr.isLoopback) continue;
        final ip = addr.address;
        if (ip == '0.0.0.0') continue;
        if (ip.startsWith('169.254.')) continue;
        fallback ??= ip;
        // Best-effort heuristic: prefer same /24 as peer (typical home/office LAN)
        if (ip.startsWith(peerPrefix)) return ip;
      }
    }
    return fallback;
  } catch (_) {
    return null;
  }
}
