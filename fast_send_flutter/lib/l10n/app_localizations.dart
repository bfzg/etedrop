import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FastSend'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloud;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @desktopIntegration.
  ///
  /// In en, this message translates to:
  /// **'Desktop Integration'**
  String get desktopIntegration;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @editDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Edit Device Name'**
  String get editDeviceName;

  /// No description provided for @storagePath.
  ///
  /// In en, this message translates to:
  /// **'Storage Path'**
  String get storagePath;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @launchAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Launch at Startup'**
  String get launchAtStartup;

  /// No description provided for @minimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get minimizeToTray;

  /// No description provided for @minimizeToTrayDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide window to system tray when closed'**
  String get minimizeToTrayDesc;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @inputDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get inputDeviceName;

  /// No description provided for @sendFile.
  ///
  /// In en, this message translates to:
  /// **'Send File'**
  String get sendFile;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @selectFileToSend.
  ///
  /// In en, this message translates to:
  /// **'Select a file to send'**
  String get selectFileToSend;

  /// No description provided for @reselect.
  ///
  /// In en, this message translates to:
  /// **'Reselect'**
  String get reselect;

  /// No description provided for @startSend.
  ///
  /// In en, this message translates to:
  /// **'Start Send'**
  String get startSend;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @waitingForReceiver.
  ///
  /// In en, this message translates to:
  /// **'Waiting for receiver...'**
  String get waitingForReceiver;

  /// No description provided for @waitingForSender.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sender...'**
  String get waitingForSender;

  /// No description provided for @pickupCode.
  ///
  /// In en, this message translates to:
  /// **'Pickup Code'**
  String get pickupCode;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @sendComplete.
  ///
  /// In en, this message translates to:
  /// **'Send Complete!'**
  String get sendComplete;

  /// No description provided for @sendNewFile.
  ///
  /// In en, this message translates to:
  /// **'Send New File'**
  String get sendNewFile;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @receiveFile.
  ///
  /// In en, this message translates to:
  /// **'Receive File'**
  String get receiveFile;

  /// No description provided for @inputPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Input Pickup Code'**
  String get inputPickupCode;

  /// No description provided for @inputPickupCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter pickup code to receive'**
  String get inputPickupCodeHint;

  /// No description provided for @startReceive.
  ///
  /// In en, this message translates to:
  /// **'Start Receive'**
  String get startReceive;

  /// No description provided for @receiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving...'**
  String get receiving;

  /// No description provided for @receiveComplete.
  ///
  /// In en, this message translates to:
  /// **'Receive Complete!'**
  String get receiveComplete;

  /// No description provided for @saveFile.
  ///
  /// In en, this message translates to:
  /// **'Save File'**
  String get saveFile;

  /// No description provided for @receiveNewFile.
  ///
  /// In en, this message translates to:
  /// **'Receive New File'**
  String get receiveNewFile;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved to: {path}'**
  String fileSaved(String path);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown Error'**
  String get unknownError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
