import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/l10n_utils.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  int _safeNotificationId(Object seed) {
    // flutter_local_notifications 要求 32-bit signed int
    final masked = seed.hashCode & 0x7fffffff;
    return masked == 0 ? 1 : masked;
  }

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'Eddy',
        appUserModelId: 'com.fasteddy.app',
        guid: '0f1e6f52-2b6d-4dcb-b7ab-2bc5e54c9b61',
      ),
    );

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> showIncomingTransfer({
    required String senderName,
    required String fileName,
  }) async {
    await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'transfer_channel',
        'File Transfer',
        channelDescription: 'Incoming file transfer notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      linux: LinuxNotificationDetails(defaultActionName: 'Open'),
      windows: WindowsNotificationDetails(),
    );

    final id = _safeNotificationId(
      '$senderName|$fileName|${DateTime.now().millisecondsSinceEpoch}',
    );
    final l10n = loadAppLocalizationsSync();
    await _plugin.show(
      id: id,
      title: l10n.notificationIncomingTitle,
      body: l10n.notificationIncomingBody(senderName, fileName),
      notificationDetails: details,
    );
  }

  Future<void> showTransferCompleted({
    required String senderName,
    required String fileName,
  }) async {
    await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'transfer_channel',
        'File Transfer',
        channelDescription: 'Incoming file transfer notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(defaultActionName: 'Open'),
      windows: WindowsNotificationDetails(),
    );

    final id = _safeNotificationId('done|$senderName|$fileName');
    final l10n = loadAppLocalizationsSync();
    await _plugin.show(
      id: id,
      title: l10n.notificationCompleteTitle,
      body: l10n.notificationCompleteBody(fileName, senderName),
      notificationDetails: details,
    );
  }
}
