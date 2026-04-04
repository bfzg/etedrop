import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
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
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'EteDrop'**
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

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

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

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkForUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Download and install the latest version'**
  String get checkForUpdatesDesc;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get updateCheckFailed;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Current: {current}\nLatest: {latest}'**
  String updateAvailableBody(String current, String latest);

  /// No description provided for @updateAlreadyLatest.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date (v{version})'**
  String updateAlreadyLatest(String version);

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open link'**
  String get openLinkFailed;

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

  /// No description provided for @langChineseSimplified.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get langChineseSimplified;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get langJapanese;

  /// No description provided for @langKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get langKorean;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanish;

  /// No description provided for @nearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get nearbyDevices;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}'**
  String selectedCount(int count);

  /// No description provided for @findingNearbyUsers.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby users...'**
  String get findingNearbyUsers;

  /// No description provided for @lookingForNearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'Looking for nearby devices...'**
  String get lookingForNearbyDevices;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @weakSignal.
  ///
  /// In en, this message translates to:
  /// **'Weak signal'**
  String get weakSignal;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'Empty folder'**
  String get emptyFolder;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @columnName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get columnName;

  /// No description provided for @columnModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get columnModified;

  /// No description provided for @columnSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get columnSize;

  /// No description provided for @columnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get columnActions;

  /// No description provided for @shareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @storagePreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing storage'**
  String get storagePreparingTitle;

  /// No description provided for @storagePreparingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Files will be saved to the app directory on this device.'**
  String get storagePreparingSubtitle;

  /// No description provided for @storageNotSetTitle.
  ///
  /// In en, this message translates to:
  /// **'No storage folder yet'**
  String get storageNotSetTitle;

  /// No description provided for @storageNotSetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder to use as cloud storage.'**
  String get storageNotSetSubtitle;

  /// No description provided for @chooseStorageFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose storage folder'**
  String get chooseStorageFolder;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get loadFailed;

  /// No description provided for @openSystemSettingsForAccess.
  ///
  /// In en, this message translates to:
  /// **'Open System Settings for access'**
  String get openSystemSettingsForAccess;

  /// No description provided for @changeStorageDirectory.
  ///
  /// In en, this message translates to:
  /// **'Change storage folder'**
  String get changeStorageDirectory;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?{suffix}'**
  String deleteEntryConfirm(String name, String suffix);

  /// No description provided for @deleteFolderSuffix.
  ///
  /// In en, this message translates to:
  /// **'\nAll contents in this folder will be deleted.'**
  String get deleteFolderSuffix;

  /// No description provided for @newFolderTooltip.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolderTooltip;

  /// No description provided for @uploadFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Upload files'**
  String get uploadFileTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @cloudDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Cloud folder'**
  String get cloudDirectoryLabel;

  /// No description provided for @downloadDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Downloads folder'**
  String get downloadDirectoryLabel;

  /// No description provided for @clipboardImageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save clipboard image: {error}'**
  String clipboardImageSaveFailed(String error);

  /// No description provided for @enterTextOrAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Enter text or add at least one file'**
  String get enterTextOrAddFiles;

  /// No description provided for @selectOnlineReceiversFirst.
  ///
  /// In en, this message translates to:
  /// **'Select online receiver devices above first'**
  String get selectOnlineReceiversFirst;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String sendFailed(String error);

  /// No description provided for @inputHintDesktop.
  ///
  /// In en, this message translates to:
  /// **'Type text, ⌘V to paste screenshots, or drop files…'**
  String get inputHintDesktop;

  /// No description provided for @inputHintMobile.
  ///
  /// In en, this message translates to:
  /// **'Type text or choose files…'**
  String get inputHintMobile;

  /// No description provided for @addFilesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get addFilesTooltip;

  /// No description provided for @sendButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButtonLabel;

  /// No description provided for @sendingButton.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingButton;

  /// No description provided for @removeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTooltip;

  /// No description provided for @shareScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareScreenTitle;

  /// No description provided for @selectAtLeastOneReceiver.
  ///
  /// In en, this message translates to:
  /// **'Select at least one receiver device above'**
  String get selectAtLeastOneReceiver;

  /// No description provided for @shareInviteSentSnack.
  ///
  /// In en, this message translates to:
  /// **'Invite sent. Transfer starts after the recipient accepts in Messages.'**
  String get shareInviteSentSnack;

  /// No description provided for @expireNever.
  ///
  /// In en, this message translates to:
  /// **'Never expires'**
  String get expireNever;

  /// No description provided for @expireOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get expireOneHour;

  /// No description provided for @expireOneDay.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get expireOneDay;

  /// No description provided for @expireSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get expireSevenDays;

  /// No description provided for @expireThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get expireThirtyDays;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Share link copied'**
  String get shareLinkCopied;

  /// No description provided for @createShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create share: {error}'**
  String createShareFailed(String error);

  /// No description provided for @cancelShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get cancelShareTitle;

  /// No description provided for @cancelShareBody.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing this file? Others will no longer be able to download it with the current link.'**
  String get cancelShareBody;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @cancelShareButton.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get cancelShareButton;

  /// No description provided for @shareCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sharing stopped'**
  String get shareCancelled;

  /// No description provided for @cancelShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not stop sharing: {error}'**
  String cancelShareFailed(String error);

  /// No description provided for @shareLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Share \"{name}\"'**
  String shareLoadingTitle(String name);

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @createShareDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create share'**
  String get createShareDialogTitle;

  /// No description provided for @fileColon.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String fileColon(String name);

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Password protect'**
  String get setPassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @shareCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Share created'**
  String get shareCreatedTitle;

  /// No description provided for @shareExistingDescription.
  ///
  /// In en, this message translates to:
  /// **'This file is already being shared. Copy the code or link below.'**
  String get shareExistingDescription;

  /// No description provided for @connectForShareLink.
  ///
  /// In en, this message translates to:
  /// **'Connect to the server to see the share link in My Shares.'**
  String get connectForShareLink;

  /// No description provided for @passwordProtected.
  ///
  /// In en, this message translates to:
  /// **'Password enabled'**
  String get passwordProtected;

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires: {when}'**
  String expiresAt(String when);

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @createShareAction.
  ///
  /// In en, this message translates to:
  /// **'Create share'**
  String get createShareAction;

  /// No description provided for @copyShareLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy share link'**
  String get copyShareLinkTooltip;

  /// No description provided for @pickCloudStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose cloud storage folder'**
  String get pickCloudStorageTitle;

  /// No description provided for @pickDownloadDirTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose downloads folder'**
  String get pickDownloadDirTitle;

  /// No description provided for @messagePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagePageTitle;

  /// No description provided for @clearMessagesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearMessagesTooltip;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a device sends you files, they will appear here.'**
  String get noMessagesSubtitle;

  /// No description provided for @waitAcceptInMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the recipient to accept in Messages (valid for 2 minutes)'**
  String get waitAcceptInMessage;

  /// No description provided for @retrySend.
  ///
  /// In en, this message translates to:
  /// **'Retry send'**
  String get retrySend;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get reject;

  /// No description provided for @receiveAction.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveAction;

  /// No description provided for @notifySenderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not notify sender: {error}'**
  String notifySenderFailed(String error);

  /// No description provided for @fileNotFoundMaybeMoved.
  ///
  /// In en, this message translates to:
  /// **'Local file not found. It may have been moved or deleted.'**
  String get fileNotFoundMaybeMoved;

  /// No description provided for @revealInFolderNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This platform cannot reveal the file in a folder.'**
  String get revealInFolderNotSupported;

  /// No description provided for @shareRestarted.
  ///
  /// In en, this message translates to:
  /// **'Share restarted'**
  String get shareRestarted;

  /// No description provided for @localFileGoneCannotRetry.
  ///
  /// In en, this message translates to:
  /// **'Local file is missing or moved; cannot retry.'**
  String get localFileGoneCannotRetry;

  /// No description provided for @retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed: {error}'**
  String retryFailed(String error);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get statusReceiving;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusRejected;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @meLabel.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meLabel;

  /// No description provided for @sendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendingBadge;

  /// No description provided for @messageSendToRecipients.
  ///
  /// In en, this message translates to:
  /// **'To {names}'**
  String messageSendToRecipients(String names);

  /// No description provided for @messageOutgoingHeaderLine.
  ///
  /// In en, this message translates to:
  /// **'To {names}'**
  String messageOutgoingHeaderLine(String names);

  /// No description provided for @recipientNDevices.
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String recipientNDevices(int count);

  /// No description provided for @recipientTwo.
  ///
  /// In en, this message translates to:
  /// **'{name1}, {name2}'**
  String recipientTwo(String name1, String name2);

  /// No description provided for @recipientMany.
  ///
  /// In en, this message translates to:
  /// **'{name1}, {name2} ({total} devices)'**
  String recipientMany(String name1, String name2, int total);

  /// No description provided for @sendingPercent.
  ///
  /// In en, this message translates to:
  /// **'Sending {percent}%'**
  String sendingPercent(String percent);

  /// No description provided for @receivingPercent.
  ///
  /// In en, this message translates to:
  /// **'Receiving {percent}%'**
  String receivingPercent(String percent);

  /// No description provided for @approxSpeed.
  ///
  /// In en, this message translates to:
  /// **'~ {speed}'**
  String approxSpeed(String speed);

  /// No description provided for @totalSizeLine.
  ///
  /// In en, this message translates to:
  /// **'Total {size}'**
  String totalSizeLine(String size);

  /// No description provided for @shareRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareRecordTitle;

  /// No description provided for @transferCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transferCompleted;

  /// No description provided for @transferInProgress.
  ///
  /// In en, this message translates to:
  /// **'Transferring'**
  String get transferInProgress;

  /// No description provided for @transferEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get transferEnded;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{mm}:{ss} left'**
  String timeRemaining(String mm, String ss);

  /// No description provided for @receiverLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipients'**
  String get receiverLabel;

  /// No description provided for @shareAllReceivedHint.
  ///
  /// In en, this message translates to:
  /// **'The recipient received all files in this share.'**
  String get shareAllReceivedHint;

  /// No description provided for @shareTransferringHint.
  ///
  /// In en, this message translates to:
  /// **'Transferring to the recipient. Keep this app open and stay online.'**
  String get shareTransferringHint;

  /// No description provided for @shareWaitAcceptHint.
  ///
  /// In en, this message translates to:
  /// **'The recipient must tap Receive in Messages before transfer starts. Cancels if no one accepts within 2 minutes.'**
  String get shareWaitAcceptHint;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @cancelSharingAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel share'**
  String get cancelSharingAction;

  /// No description provided for @processingPercent.
  ///
  /// In en, this message translates to:
  /// **'Processing… {percent}%'**
  String processingPercent(String percent);

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar'**
  String get chooseAvatar;

  /// No description provided for @newFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolderDialogTitle;

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderNameHint;

  /// No description provided for @createFolderButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createFolderButton;

  /// No description provided for @folderNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a folder name'**
  String get folderNameEmpty;

  /// No description provided for @folderNameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Name cannot contain / or \\'**
  String get folderNameInvalidChars;

  /// No description provided for @createFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create folder: {error}'**
  String createFolderFailed(String error);

  /// No description provided for @rootDirectory.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get rootDirectory;

  /// No description provided for @notificationIncomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming file request'**
  String get notificationIncomingTitle;

  /// No description provided for @notificationIncomingBody.
  ///
  /// In en, this message translates to:
  /// **'{sender} is sending: {file}'**
  String notificationIncomingBody(String sender, String file);

  /// No description provided for @notificationCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive complete'**
  String get notificationCompleteTitle;

  /// No description provided for @notificationCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{file} (from {sender})'**
  String notificationCompleteBody(String file, String sender);

  /// No description provided for @trayOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open {appName}'**
  String trayOpenApp(String appName);

  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// No description provided for @signalingConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to signaling server'**
  String get signalingConnectFailed;

  /// No description provided for @signalingWaitTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get signalingWaitTimeout;

  /// No description provided for @webSocketError.
  ///
  /// In en, this message translates to:
  /// **'WebSocket connection error'**
  String get webSocketError;

  /// No description provided for @invalidPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid pickup code'**
  String get invalidPickupCode;
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
      <String>['en', 'es', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
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
