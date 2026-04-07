import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import 'logger_service.dart';
import 'webrtc_background_keepalive_callback.dart';

/// 为局域网 WebRTC 在后台尽量保活：配置语音通话类音频会话，Android 再启前台服务。
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
        channelDescription: '保持局域网 WebRTC/传输连接',
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
    if (Platform.isAndroid) {
      final notif = await FlutterForegroundTask.checkNotificationPermission();
      if (notif != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      final again = await FlutterForegroundTask.checkNotificationPermission();
      if (again != NotificationPermission.granted) {
        logger.w('WebRTC keepalive: notification permission denied');
        return false;
      }
    }
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      logger.w('WebRTC keepalive: microphone permission denied');
      return false;
    }
    return true;
  }

  static Future<void> configureAudioSession() async {
    if (!isSupportedMobile) return;
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
                AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
  }

  static Future<void> resetAudioSession() async {
    if (!isSupportedMobile) return;
    final session = await AudioSession.instance;
    await session.setActive(false);
    await session.configure(const AudioSessionConfiguration.music());
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
    await configureAudioSession();
    if (Platform.isAndroid) {
      final result = await FlutterForegroundTask.startService(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        callback: webrtcBackgroundKeepaliveStartCallback,
        serviceTypes: const [
          ForegroundServiceTypes.mediaPlayback,
          ForegroundServiceTypes.microphone,
        ],
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
    await resetAudioSession();
  }

  /// 从挂起恢复后调用，重新绑定音频会话（系统可能已回收）。
  static Future<void> refreshAudioSessionIfActive() async {
    if (!isSupportedMobile) return;
    await configureAudioSession();
  }
}
