// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'EteDrop';

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
  String get nearby => 'Nearby';

  @override
  String get messages => 'Msgs';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get storage => 'Storage';

  @override
  String get desktopIntegration => 'Desktop Integration';

  @override
  String get appearance => 'Appearance';

  @override
  String get networkLine => 'Server route';

  @override
  String get serverLineAuto => 'Auto';

  @override
  String get serverLineAutoDesc => 'Automatically select the nearest node.';

  @override
  String get serverLineGlobal => 'Global';

  @override
  String get serverLineGlobalDesc =>
      'api.etedrop.com — recommended outside mainland.';

  @override
  String get serverLineMainland => 'Mainland';

  @override
  String get serverLineMainlandDesc =>
      'api-cn.etedrop.com — better routing for mainland China.';

  @override
  String get about => 'About';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkForUpdatesDesc => 'Download and install the latest version';

  @override
  String get updateCheckFailed => 'Failed to check for updates';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateAvailableBody(String current, String latest) {
    return 'Current: $current\nLatest: $latest';
  }

  @override
  String updateAlreadyLatest(String version) {
    return 'You\'re up to date (v$version)';
  }

  @override
  String get updateNow => 'Update';

  @override
  String get later => 'Later';

  @override
  String get openLinkFailed => 'Failed to open link';

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

  @override
  String get langChineseSimplified => 'Chinese (Simplified)';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => 'Japanese';

  @override
  String get langKorean => 'Korean';

  @override
  String get langSpanish => 'Spanish';

  @override
  String get nearbyDevices => 'Nearby devices';

  @override
  String selectedCount(int count) {
    return 'Selected $count';
  }

  @override
  String get findingNearbyUsers => 'Finding nearby users...';

  @override
  String get lookingForNearbyDevices => 'Looking for nearby devices...';

  @override
  String get offline => 'Offline';

  @override
  String get weakSignal => 'Weak signal';

  @override
  String get youLabel => 'You';

  @override
  String get emptyFolder => 'Empty folder';

  @override
  String get shareAction => 'Share';

  @override
  String get deleteAction => 'Delete';

  @override
  String get columnName => 'Name';

  @override
  String get columnModified => 'Modified';

  @override
  String get columnSize => 'Size';

  @override
  String get columnActions => 'Actions';

  @override
  String get shareTooltip => 'Share';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get storagePreparingTitle => 'Preparing storage';

  @override
  String get storagePreparingSubtitle =>
      'Files will be saved to the app directory on this device.';

  @override
  String get storageNotSetTitle => 'No storage folder yet';

  @override
  String get storageNotSetSubtitle =>
      'Choose a folder to use as cloud storage.';

  @override
  String get chooseStorageFolder => 'Choose storage folder';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get openSystemSettingsForAccess => 'Open System Settings for access';

  @override
  String get changeStorageDirectory => 'Change storage folder';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String deleteEntryConfirm(String name, String suffix) {
    return 'Delete \"$name\"?$suffix';
  }

  @override
  String get deleteFolderSuffix =>
      '\nAll contents in this folder will be deleted.';

  @override
  String get newFolderTooltip => 'New folder';

  @override
  String get uploadFileTooltip => 'Upload files';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get cloudDirectoryLabel => 'Cloud folder';

  @override
  String get downloadDirectoryLabel => 'Downloads folder';

  @override
  String clipboardImageSaveFailed(String error) {
    return 'Could not save clipboard image: $error';
  }

  @override
  String get enterTextOrAddFiles => 'Enter text or add at least one file';

  @override
  String get selectOnlineReceiversFirst =>
      'Select online receiver devices above first';

  @override
  String sendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get inputHintDesktop =>
      'Type text, ⌘V to paste screenshots, or drop files…';

  @override
  String get inputHintMobile => 'Type text or choose files…';

  @override
  String get addFilesTooltip => 'Add files';

  @override
  String get sendButtonLabel => 'Send';

  @override
  String get sendingButton => 'Sending…';

  @override
  String get removeTooltip => 'Remove';

  @override
  String get shareScreenTitle => 'Share';

  @override
  String get selectAtLeastOneReceiver =>
      'Select at least one receiver device above';

  @override
  String get shareInviteSentSnack =>
      'Invite sent. Transfer starts after the recipient accepts in Messages.';

  @override
  String get expireNever => 'Never expires';

  @override
  String get expireOneHour => '1 hour';

  @override
  String get expireOneDay => '24 hours';

  @override
  String get expireSevenDays => '7 days';

  @override
  String get expireThirtyDays => '30 days';

  @override
  String get shareLinkCopied => 'Share link copied';

  @override
  String createShareFailed(String error) {
    return 'Could not create share: $error';
  }

  @override
  String get cancelShareTitle => 'Stop sharing';

  @override
  String get cancelShareBody =>
      'Stop sharing this file? Others will no longer be able to download it with the current link.';

  @override
  String get backButton => 'Back';

  @override
  String get cancelShareButton => 'Stop sharing';

  @override
  String get shareCancelled => 'Sharing stopped';

  @override
  String cancelShareFailed(String error) {
    return 'Could not stop sharing: $error';
  }

  @override
  String shareLoadingTitle(String name) {
    return 'Share \"$name\"';
  }

  @override
  String get closeButton => 'Close';

  @override
  String get createShareDialogTitle => 'Create share';

  @override
  String fileColon(String name) {
    return 'File: $name';
  }

  @override
  String get setPassword => 'Password protect';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get shareCreatedTitle => 'Share created';

  @override
  String get shareExistingDescription =>
      'This file is already being shared. Copy the code or link below.';

  @override
  String get connectForShareLink =>
      'Connect to the server to see the share link in My Shares.';

  @override
  String get passwordProtected => 'Password enabled';

  @override
  String expiresAt(String when) {
    return 'Expires: $when';
  }

  @override
  String get doneButton => 'Done';

  @override
  String get createShareAction => 'Create share';

  @override
  String get copyShareLinkTooltip => 'Copy share link';

  @override
  String get pickCloudStorageTitle => 'Choose cloud storage folder';

  @override
  String get pickDownloadDirTitle => 'Choose downloads folder';

  @override
  String get messagePageTitle => 'Messages';

  @override
  String get clearMessagesTooltip => 'Clear';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMessagesSubtitle =>
      'When a device sends you files, they will appear here.';

  @override
  String get waitAcceptInMessage =>
      'Waiting for the recipient to accept in Messages (valid for 2 minutes)';

  @override
  String get retrySend => 'Retry send';

  @override
  String get reject => 'Decline';

  @override
  String get receiveAction => 'Receive';

  @override
  String notifySenderFailed(String error) {
    return 'Could not notify sender: $error';
  }

  @override
  String get fileNotFoundMaybeMoved =>
      'Local file not found. It may have been moved or deleted.';

  @override
  String get revealInFolderNotSupported =>
      'This platform cannot reveal the file in a folder.';

  @override
  String get shareRestarted => 'Share restarted';

  @override
  String get localFileGoneCannotRetry =>
      'Local file is missing or moved; cannot retry.';

  @override
  String retryFailed(String error) {
    return 'Retry failed: $error';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusReceiving => 'Receiving';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusRejected => 'Declined';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusExpired => 'Expired';

  @override
  String get meLabel => 'Me';

  @override
  String get sendingBadge => 'Send';

  @override
  String messageSendToRecipients(String names) {
    return 'To $names';
  }

  @override
  String messageOutgoingHeaderLine(String names) {
    return 'To $names';
  }

  @override
  String recipientNDevices(int count) {
    return '$count devices';
  }

  @override
  String recipientTwo(String name1, String name2) {
    return '$name1, $name2';
  }

  @override
  String recipientMany(String name1, String name2, int total) {
    return '$name1, $name2 ($total devices)';
  }

  @override
  String sendingPercent(String percent) {
    return 'Sending $percent%';
  }

  @override
  String receivingPercent(String percent) {
    return 'Receiving $percent%';
  }

  @override
  String approxSpeed(String speed) {
    return '~ $speed';
  }

  @override
  String totalSizeLine(String size) {
    return 'Total $size';
  }

  @override
  String get shareRecordTitle => 'Share';

  @override
  String get transferCompleted => 'Completed';

  @override
  String get transferInProgress => 'Transferring';

  @override
  String get transferEnded => 'Ended';

  @override
  String timeRemaining(String mm, String ss) {
    return '$mm:$ss left';
  }

  @override
  String get receiverLabel => 'Recipients';

  @override
  String get shareAllReceivedHint =>
      'The recipient received all files in this share.';

  @override
  String get shareTransferringHint =>
      'Transferring to the recipient. Keep this app open and stay online.';

  @override
  String get shareWaitAcceptHint =>
      'The recipient must tap Receive in Messages before transfer starts. Cancels if no one accepts within 2 minutes.';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get copyAction => 'Copy';

  @override
  String get closeAction => 'Close';

  @override
  String get cancelSharingAction => 'Cancel share';

  @override
  String processingPercent(String percent) {
    return 'Processing… $percent%';
  }

  @override
  String get chooseAvatar => 'Choose avatar';

  @override
  String get newFolderDialogTitle => 'New folder';

  @override
  String get folderNameHint => 'Folder name';

  @override
  String get createFolderButton => 'Create';

  @override
  String get folderNameEmpty => 'Please enter a folder name';

  @override
  String get folderNameInvalidChars => 'Name cannot contain / or \\';

  @override
  String createFolderFailed(String error) {
    return 'Could not create folder: $error';
  }

  @override
  String get rootDirectory => 'Root';

  @override
  String get notificationIncomingTitle => 'Incoming file request';

  @override
  String notificationIncomingBody(String sender, String file) {
    return '$sender is sending: $file';
  }

  @override
  String get notificationCompleteTitle => 'Receive complete';

  @override
  String notificationCompleteBody(String file, String sender) {
    return '$file (from $sender)';
  }

  @override
  String trayOpenApp(String appName) {
    return 'Open $appName';
  }

  @override
  String get trayQuit => 'Quit';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get signalingConnectFailed => 'Could not connect to signaling server';

  @override
  String get signalingWaitTimeout => 'Timed out';

  @override
  String get webSocketError => 'WebSocket connection error';

  @override
  String get invalidPickupCode => 'Invalid pickup code';

  @override
  String get transferReceiveSection => 'Nearby transfer';

  @override
  String get transferAutoReceiveTitle => 'Auto receive';

  @override
  String get transferAutoReceiveSubtitle =>
      'When on, LAN share offers begin without tapping Receive in Messages. Default is off.';

  @override
  String get transferAutoReceivingHint =>
      'Auto-accept is on — connecting and receiving in the background.';

  @override
  String get webrtcBackgroundKeepaliveSection => 'Background';

  @override
  String get webrtcBackgroundKeepaliveTitle =>
      'Keep transfer alive in background';

  @override
  String get webrtcBackgroundKeepaliveSubtitle =>
      'When on, tries to keep the LAN WebRTC data connection in background (file transfer only, no microphone). Android shows a low-priority foreground notification. iOS uses limited background refresh via the foreground-task plugin. Still subject to OS limits.';

  @override
  String get webrtcBackgroundFgNotificationTitle => 'Keeping transfer active';

  @override
  String get webrtcBackgroundFgNotificationBody => 'Tap to return to the app';

  @override
  String get webrtcBackgroundKeepaliveEnableFailed =>
      'Could not enable background keep-alive. Allow notification access, then try again.';
}
