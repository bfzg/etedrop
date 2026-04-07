import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/local_storage_service.dart';
import '../../../services/webrtc_background_keepalive.dart';

part 'webrtc_keepalive_prefs_provider.g.dart';

@Riverpod(keepAlive: true)
class WebrtcKeepalivePreference extends _$WebrtcKeepalivePreference {
  @override
  bool build() {
    return LocalStorageService.instance
            .get<bool>(StorageKeys.webrtcBackgroundKeepalive) ??
        false;
  }

  Future<bool> setEnabled(
    bool value, {
    required String fgNotificationTitle,
    required String fgNotificationBody,
  }) async {
    if (!WebRtcBackgroundKeepalive.isSupportedMobile) {
      return false;
    }
    if (value) {
      final ok = await WebRtcBackgroundKeepalive.activate(
        notificationTitle: fgNotificationTitle,
        notificationText: fgNotificationBody,
      );
      if (!ok) return false;
    } else {
      await WebRtcBackgroundKeepalive.deactivate();
    }
    state = value;
    await LocalStorageService.instance.set<bool>(
      StorageKeys.webrtcBackgroundKeepalive,
      value,
    );
    return true;
  }
}
