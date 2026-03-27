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
