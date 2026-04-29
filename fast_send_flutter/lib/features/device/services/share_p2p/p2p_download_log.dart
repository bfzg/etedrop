import 'package:flutter/foundation.dart';

bool get shareP2pDownloadDiagEnabled =>
    kDebugMode ||
    const bool.fromEnvironment('SHARE_P2P_DL_LOG', defaultValue: false);

void shareP2pDownloadLog(String message) {
  if (!shareP2pDownloadDiagEnabled) return;
  debugPrint('[ShareP2P][download] $message');
}
