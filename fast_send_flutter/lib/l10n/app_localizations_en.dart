// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FastSend';

  @override
  String get home => 'Home';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get settings => 'Settings';

  @override
  String get cloud => 'Cloud';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get storage => 'Storage';

  @override
  String get desktopIntegration => 'Desktop Integration';

  @override
  String get appearance => 'Appearance';

  @override
  String get about => 'About';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get connect => 'Connect';

  @override
  String get deviceId => 'Device ID';

  @override
  String get editDeviceName => 'Edit Device Name';

  @override
  String get storagePath => 'Storage Path';

  @override
  String get notSet => 'Not Set';

  @override
  String get launchAtStartup => 'Launch at Startup';

  @override
  String get minimizeToTray => 'Minimize to Tray';

  @override
  String get minimizeToTrayDesc => 'Hide window to system tray when closed';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get followSystem => 'Follow System';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get language => 'Language';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get inputDeviceName => 'Device Name';

  @override
  String get sendFile => 'Send File';

  @override
  String get selectFile => 'Select File';

  @override
  String get selectFileToSend => 'Select a file to send';

  @override
  String get reselect => 'Reselect';

  @override
  String get startSend => 'Start Send';

  @override
  String get connecting => 'Connecting...';

  @override
  String get waitingForReceiver => 'Waiting for receiver...';

  @override
  String get waitingForSender => 'Waiting for sender...';

  @override
  String get pickupCode => 'Pickup Code';

  @override
  String get copied => 'Copied';

  @override
  String get sending => 'Sending...';

  @override
  String get sendComplete => 'Send Complete!';

  @override
  String get sendNewFile => 'Send New File';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get receiveFile => 'Receive File';

  @override
  String get inputPickupCode => 'Input Pickup Code';

  @override
  String get inputPickupCodeHint => 'Enter pickup code to receive';

  @override
  String get startReceive => 'Start Receive';

  @override
  String get receiving => 'Receiving...';

  @override
  String get receiveComplete => 'Receive Complete!';

  @override
  String get saveFile => 'Save File';

  @override
  String get receiveNewFile => 'Receive New File';

  @override
  String fileSaved(String path) {
    return 'File saved to: $path';
  }

  @override
  String get unknownError => 'Unknown Error';
}
