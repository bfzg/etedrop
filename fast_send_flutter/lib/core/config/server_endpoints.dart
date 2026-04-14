import 'dart:ui';

/// 用户选择的线路（持久化）
enum ServerLinePreference {
  /// 按语言/地区自动：简体/大陆倾向走 api-cn，其余走全球
  auto,

  /// 全球节点（如 api.etedrop.com）
  global,

  /// 大陆优化节点（如 api-cn.etedrop.com）
  mainland,
}

/// 当前解析后的 API / WebSocket 地址（与 [AppConstants] 中默认主机一致时可只改 constants）
class ServerEndpoints {
  const ServerEndpoints({
    required this.apiBaseUrl,
    required this.shareServerUrl,
    required this.signalingServerUrl,
    required this.mainlandStunPreferred,
  });

  final String apiBaseUrl;
  final String shareServerUrl;
  final String signalingServerUrl;

  /// 与当前解析出的 API 线路一致：选到大陆节点时为 true，用于 STUN 列表优先境内可达服务器。
  final bool mainlandStunPreferred;

  /// 由 HTTPS 基址推导 `wss://host/...` 与 `ws://host/...`
  static String wsShareUrlFromApiBase(String apiBase) {
    final u = apiBase.trim();
    if (u.startsWith('https://')) {
      return 'wss://${u.substring(8)}/api/share';
    }
    if (u.startsWith('http://')) {
      return 'ws://${u.substring(7)}/api/share';
    }
    return '${apiBase}/api/share';
  }

  static String wsConnectUrlFromApiBase(String apiBase) {
    final u = apiBase.trim();
    if (u.startsWith('https://')) {
      return 'wss://${u.substring(8)}/api/connect';
    }
    if (u.startsWith('http://')) {
      return 'ws://${u.substring(7)}/api/connect';
    }
    return '${apiBase}/api/connect';
  }

  /// 全球节点（HTTPS）
  static String get _globalApiBase => const String.fromEnvironment(
    'API_BASE_GLOBAL',
    defaultValue: 'https://api.etedrop.com',
  );

  /// 大陆节点（HTTPS）
  static String get _mainlandApiBase => const String.fromEnvironment(
    'API_BASE_MAINLAND',
    defaultValue: 'https://api-cn.etedrop.com',
  );

  /// 根据偏好与界面语言解析最终线路
  static ServerEndpoints resolve({
    required ServerLinePreference preference,
    required Locale resolvedLocale,
  }) {
    final globalBase = _globalApiBase;
    final mainlandBase = _mainlandApiBase;

    String pick;
    switch (preference) {
      case ServerLinePreference.global:
        pick = globalBase;
        break;
      case ServerLinePreference.mainland:
        pick = mainlandBase;
        break;
      case ServerLinePreference.auto:
        pick = _autoPickApiBase(
          locale: resolvedLocale,
          globalBase: globalBase,
          mainlandBase: mainlandBase,
        );
        break;
    }

    return ServerEndpoints(
      apiBaseUrl: pick,
      shareServerUrl: wsShareUrlFromApiBase(pick),
      signalingServerUrl: wsConnectUrlFromApiBase(pick),
      mainlandStunPreferred: pick == mainlandBase,
    );
  }

  /// 自动：`zh` 且非港澳台 → 大陆线；否则全球
  static String _autoPickApiBase({
    required Locale locale,
    required String globalBase,
    required String mainlandBase,
  }) {
    final lang = locale.languageCode;
    final c = locale.countryCode;
    if (lang != 'zh') return globalBase;
    if (c == null || c.isEmpty) {
      return mainlandBase;
    }
    const nonMainlandZh = {'TW', 'HK', 'MO'};
    if (nonMainlandZh.contains(c)) return globalBase;
    if (c == 'CN') return mainlandBase;
    return globalBase;
  }
}
