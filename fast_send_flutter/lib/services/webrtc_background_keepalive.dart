import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'logger_service.dart';
import 'webrtc_background_keepalive_callback.dart';

/// 为局域网 WebRTC（仅 DataChannel 传文件）在后台尽量保活：不配置语音/麦克风。
/// Android：前台服务类型 [ForegroundServiceTypes.mediaPlayback] + 通知权限。
/// iOS：[flutter_foreground_task] 的受限后台任务（与云端实时音视频方案不同，效果有限）。
class WebRtcBackgroundKeepalive {
  WebRtcBackgroundKeepalive._();

  static bool _pluginInitialized = false;

  static bool get isSupportedMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static void initForegroundTaskPlugin() {
    if (!isSupportedMobile) return;
    if (_pluginInitialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'etedrop_webrtc_keepalive',
        channelName: '传输保活',
        channelDescription: '保持局域网 WebRTC 数据传输',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _pluginInitialized = true;
  }

  static Future<bool> _ensureRuntimePermissions() async {
    if (!Platform.isAndroid) return true;
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    if (notif != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    final again = await FlutterForegroundTask.checkNotificationPermission();
    if (again != NotificationPermission.granted) {
      logger.w('WebRTC keepalive: notification permission denied');
      return false;
    }
    return true;
  }

  /// 启动保活（需先 [initForegroundTaskPlugin]。）
  static Future<bool> activate({
    required String notificationTitle,
    required String notificationText,
  }) async {
    if (!isSupportedMobile) return true;
    initForegroundTaskPlugin();
    final ok = await _ensureRuntimePermissions();
    if (!ok) return false;
    if (Platform.isAndroid) {
      final result = await FlutterForegroundTask.startService(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        callback: webrtcBackgroundKeepaliveStartCallback,
        serviceTypes: const [ForegroundServiceTypes.mediaPlayback],
      );
      if (result is ServiceRequestFailure) {
        logger.e('WebRTC keepalive foreground service: ${result.error}');
        return false;
      }
    } else {
      final result = await FlutterForegroundTask.startService(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        callback: webrtcBackgroundKeepaliveStartCallback,
      );
      if (result is ServiceRequestFailure) {
        logger.e('WebRTC keepalive iOS task: ${result.error}');
        return false;
      }
    }
    return true;
  }

  static Future<void> deactivate() async {
    if (!isSupportedMobile) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// 回到前台时调用（无音频会话时可作占位；预留与系统策略变更对齐）。
  static Future<void> refreshAudioSessionIfActive() async {}
}
