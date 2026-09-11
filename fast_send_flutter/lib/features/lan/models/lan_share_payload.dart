import 'dart:convert';

/// 单次局域网批量分享（多文件合并为一条消息）
class LanShareFileMeta {
  final String name;
  final int size;

  const LanShareFileMeta({required this.name, required this.size});

  Map<String, dynamic> toJson() => {'name': name, 'size': size};

  static LanShareFileMeta fromJson(Map<String, dynamic> json) {
    return LanShareFileMeta(
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
    );
  }
}

/// 发送方 → 接收方：仅元数据，不传文件
class LanShareOfferPayload {
  final String shareId;
  final String senderDeviceId;
  final String senderName;
  final int senderAvatar;

  /// 发送方 HTTP 服务地址（供接收方回调「接受」）
  final String senderHost;
  final int senderPort;
  final List<LanShareFileMeta> files;
  final int expiresAtMs;

  /// 可选附言（旧版客户端忽略）
  final String? caption;
  final String? chatMessageId;
  final String? chatConversationId;
  final String? chatConversationTitle;
  final List<String> chatMemberIds;

  const LanShareOfferPayload({
    required this.shareId,
    required this.senderDeviceId,
    required this.senderName,
    required this.senderAvatar,
    required this.senderHost,
    required this.senderPort,
    required this.files,
    required this.expiresAtMs,
    this.caption,
    this.chatMessageId,
    this.chatConversationId,
    this.chatConversationTitle,
    this.chatMemberIds = const [],
  });

  bool get isChatFile => chatMessageId != null && chatConversationId != null;

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'senderDeviceId': senderDeviceId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'senderHost': senderHost,
    'senderPort': senderPort,
    'files': files.map((e) => e.toJson()).toList(),
    'expiresAtMs': expiresAtMs,
    if (caption != null && caption!.isNotEmpty) 'caption': caption,
    if (chatMessageId != null) 'chatMessageId': chatMessageId,
    if (chatConversationId != null) 'chatConversationId': chatConversationId,
    if (chatConversationTitle != null && chatConversationTitle!.isNotEmpty)
      'chatConversationTitle': chatConversationTitle,
    if (chatMemberIds.isNotEmpty) 'chatMemberIds': chatMemberIds,
  };

  static LanShareOfferPayload fromJson(Map<String, dynamic> json) {
    final list = json['files'] as List<dynamic>? ?? [];
    return LanShareOfferPayload(
      shareId: json['shareId'] as String,
      senderDeviceId: json['senderDeviceId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: (json['senderAvatar'] as num?)?.toInt() ?? 1,
      senderHost: json['senderHost'] as String,
      senderPort: (json['senderPort'] as num).toInt(),
      files: list
          .map((e) => LanShareFileMeta.fromJson(e as Map<String, dynamic>))
          .toList(),
      expiresAtMs: (json['expiresAtMs'] as num).toInt(),
      caption: json['caption'] as String?,
      chatMessageId: json['chatMessageId'] as String?,
      chatConversationId: json['chatConversationId'] as String?,
      chatConversationTitle: json['chatConversationTitle'] as String?,
      chatMemberIds: (json['chatMemberIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static String encode(LanShareOfferPayload p) => jsonEncode(p.toJson());

  static LanShareOfferPayload decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// 接收方 → 发送方：用户已接受 / 拒绝
class LanShareAcceptPayload {
  final String shareId;
  final String receiverDeviceId;
  final bool accepted;

  const LanShareAcceptPayload({
    required this.shareId,
    required this.receiverDeviceId,
    required this.accepted,
  });

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'receiverDeviceId': receiverDeviceId,
    'accepted': accepted,
  };

  static LanShareAcceptPayload fromJson(Map<String, dynamic> json) {
    return LanShareAcceptPayload(
      shareId: json['shareId'] as String,
      receiverDeviceId: json['receiverDeviceId'] as String,
      accepted: json['accepted'] as bool,
    );
  }
}

/// 发送方 → 接收方：取消分享（对端待处理消息可关闭）
class LanShareCancelPayload {
  final String shareId;

  const LanShareCancelPayload({required this.shareId});

  Map<String, dynamic> toJson() => {'shareId': shareId};

  static LanShareCancelPayload fromJson(Map<String, dynamic> json) {
    return LanShareCancelPayload(shareId: json['shareId'] as String);
  }
}
