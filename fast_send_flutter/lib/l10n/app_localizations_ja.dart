// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Eddy';

  @override
  String get home => 'ホーム';

  @override
  String get send => '送信';

  @override
  String get receive => '受信';

  @override
  String get settings => '設定';

  @override
  String get cloud => 'クラウド';

  @override
  String get nearby => '近く';

  @override
  String get messages => 'メッセージ';

  @override
  String get deviceInfo => 'デバイス情報';

  @override
  String get storage => 'ストレージ';

  @override
  String get desktopIntegration => 'デスクトップ連携';

  @override
  String get appearance => '外観';

  @override
  String get about => 'について';

  @override
  String get connected => '接続済み';

  @override
  String get disconnected => '未接続';

  @override
  String get connect => '接続';

  @override
  String get deviceId => 'デバイス ID';

  @override
  String get editDeviceName => 'デバイス名を編集';

  @override
  String get storagePath => '保存場所';

  @override
  String get notSet => '未設定';

  @override
  String get launchAtStartup => '起動時に実行';

  @override
  String get minimizeToTray => 'トレイに格納';

  @override
  String get minimizeToTrayDesc => '閉じるとウィンドウをトレイに隠す';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get followSystem => 'システムに合わせる';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get language => '言語';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => 'OK';

  @override
  String get selectTheme => 'テーマを選択';

  @override
  String get inputDeviceName => 'デバイス名';

  @override
  String get sendFile => 'ファイルを送信';

  @override
  String get selectFile => 'ファイルを選択';

  @override
  String get selectFileToSend => '送信するファイルを選択';

  @override
  String get reselect => '選び直す';

  @override
  String get startSend => '送信開始';

  @override
  String get connecting => '接続中...';

  @override
  String get waitingForReceiver => '受信側を待っています...';

  @override
  String get waitingForSender => '送信側を待っています...';

  @override
  String get pickupCode => '受け取りコード';

  @override
  String get copied => 'コピーしました';

  @override
  String get sending => '送信中...';

  @override
  String get sendComplete => '送信完了！';

  @override
  String get sendNewFile => '別のファイルを送信';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get receiveFile => 'ファイルを受信';

  @override
  String get inputPickupCode => '受け取りコードを入力';

  @override
  String get inputPickupCodeHint => '受け取りコードを入力してファイルを受信';

  @override
  String get startReceive => '受信開始';

  @override
  String get receiving => '受信中...';

  @override
  String get receiveComplete => '受信完了！';

  @override
  String get saveFile => 'ファイルを保存';

  @override
  String get receiveNewFile => '別のファイルを受信';

  @override
  String fileSaved(String path) {
    return 'ファイルを保存しました: $path';
  }

  @override
  String get unknownError => '不明なエラー';

  @override
  String get langChineseSimplified => '中国語（簡体字）';

  @override
  String get langEnglish => '英語';

  @override
  String get langJapanese => '日本語';

  @override
  String get langKorean => '韓国語';

  @override
  String get langSpanish => 'スペイン語';

  @override
  String get nearbyDevices => '近くのデバイス';

  @override
  String selectedCount(int count) {
    return '選択 $count';
  }

  @override
  String get findingNearbyUsers => 'ユーザーを検索中...';

  @override
  String get lookingForNearbyDevices => '近くのデバイスを探しています...';

  @override
  String get offline => 'オフライン';

  @override
  String get weakSignal => '電波が弱い';

  @override
  String get youLabel => '自分';

  @override
  String get emptyFolder => '空のフォルダ';

  @override
  String get shareAction => '共有';

  @override
  String get deleteAction => '削除';

  @override
  String get columnName => '名前';

  @override
  String get columnModified => '更新日時';

  @override
  String get columnSize => 'サイズ';

  @override
  String get columnActions => '操作';

  @override
  String get shareTooltip => '共有';

  @override
  String get deleteTooltip => '削除';

  @override
  String get storagePreparingTitle => 'ストレージを準備中';

  @override
  String get storagePreparingSubtitle => 'この端末のアプリ専用フォルダに保存されます。';

  @override
  String get storageNotSetTitle => '保存フォルダが未設定です';

  @override
  String get storageNotSetSubtitle => 'クラウド用のフォルダを選んでください。';

  @override
  String get chooseStorageFolder => 'フォルダを選択';

  @override
  String get loadFailed => '読み込みに失敗しました';

  @override
  String get openSystemSettingsForAccess => 'システム設定でアクセスを許可';

  @override
  String get changeStorageDirectory => '保存フォルダを変更';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String deleteEntryConfirm(String name, String suffix) {
    return '「$name」を削除しますか？$suffix';
  }

  @override
  String get deleteFolderSuffix => '\nフォルダ内のすべての内容が削除されます。';

  @override
  String get newFolderTooltip => '新規フォルダ';

  @override
  String get uploadFileTooltip => 'ファイルをアップロード';

  @override
  String get refreshTooltip => '更新';

  @override
  String get cloudDirectoryLabel => 'クラウドフォルダ';

  @override
  String get downloadDirectoryLabel => 'ダウンロードフォルダ';

  @override
  String clipboardImageSaveFailed(String error) {
    return 'クリップボードの画像を保存できませんでした: $error';
  }

  @override
  String get enterTextOrAddFiles => 'テキストを入力するか、ファイルを1つ以上追加してください';

  @override
  String get selectOnlineReceiversFirst => '上でオンラインの受信デバイスを選んでください';

  @override
  String sendFailed(String error) {
    return '送信に失敗しました: $error';
  }

  @override
  String get inputHintDesktop => '文字を入力、⌘Vでスクショを貼り付け、またはファイルをドロップ…';

  @override
  String get inputHintMobile => '文字を入力するかファイルを選択…';

  @override
  String get addFilesTooltip => 'ファイルを追加';

  @override
  String get sendButtonLabel => '送信';

  @override
  String get sendingButton => '送信中…';

  @override
  String get removeTooltip => '削除';

  @override
  String get shareScreenTitle => '共有';

  @override
  String get selectAtLeastOneReceiver => '上で受信デバイスを1台以上選んでください';

  @override
  String get shareInviteSentSnack => '招待を送信しました。相手がメッセージで承認すると転送が始まります。';

  @override
  String get expireNever => '無期限';

  @override
  String get expireOneHour => '1時間';

  @override
  String get expireOneDay => '24時間';

  @override
  String get expireSevenDays => '7日';

  @override
  String get expireThirtyDays => '30日';

  @override
  String get shareLinkCopied => '共有リンクをコピーしました';

  @override
  String createShareFailed(String error) {
    return '共有を作成できませんでした: $error';
  }

  @override
  String get cancelShareTitle => '共有を停止';

  @override
  String get cancelShareBody => '共有を停止しますか？このリンクからはダウンロードできなくなります。';

  @override
  String get backButton => '戻る';

  @override
  String get cancelShareButton => '共有を停止';

  @override
  String get shareCancelled => '共有を停止しました';

  @override
  String cancelShareFailed(String error) {
    return '共有の停止に失敗しました: $error';
  }

  @override
  String shareLoadingTitle(String name) {
    return '「$name」を共有';
  }

  @override
  String get closeButton => '閉じる';

  @override
  String get createShareDialogTitle => '共有を作成';

  @override
  String fileColon(String name) {
    return 'ファイル: $name';
  }

  @override
  String get setPassword => 'パスワード保護';

  @override
  String get enterPassword => 'パスワードを入力';

  @override
  String get shareCreatedTitle => '共有を作成しました';

  @override
  String get shareExistingDescription =>
      'このファイルはすでに共有中です。下のコードまたはリンクをコピーしてください。';

  @override
  String get connectForShareLink => 'サーバーに接続すると「マイ共有」でリンクを確認できます。';

  @override
  String get passwordProtected => 'パスワードを設定済み';

  @override
  String expiresAt(String when) {
    return '有効期限: $when';
  }

  @override
  String get doneButton => '完了';

  @override
  String get createShareAction => '共有を作成';

  @override
  String get copyShareLinkTooltip => '共有リンクをコピー';

  @override
  String get pickCloudStorageTitle => 'クラウド保存フォルダを選択';

  @override
  String get pickDownloadDirTitle => 'ダウンロードフォルダを選択';

  @override
  String get messagePageTitle => 'メッセージ';

  @override
  String get clearMessagesTooltip => '消去';

  @override
  String get noMessagesYet => 'メッセージはありません';

  @override
  String get noMessagesSubtitle => '他のデバイスからファイルが送られるとここに表示されます。';

  @override
  String get waitAcceptInMessage => '相手がメッセージで承認するまで待機（2分間有効）';

  @override
  String get retrySend => '再送信';

  @override
  String get reject => '拒否';

  @override
  String get receiveAction => '受信';

  @override
  String notifySenderFailed(String error) {
    return '送信者に通知できませんでした: $error';
  }

  @override
  String get fileNotFoundMaybeMoved => 'ローカルファイルが見つかりません。移動または削除された可能性があります。';

  @override
  String get revealInFolderNotSupported => 'このプラットフォームではフォルダ内の表示に対応していません。';

  @override
  String get shareRestarted => '共有を再開しました';

  @override
  String get localFileGoneCannotRetry => 'ローカルファイルがないため再試行できません。';

  @override
  String retryFailed(String error) {
    return '再試行に失敗しました: $error';
  }

  @override
  String get statusPending => '保留中';

  @override
  String get statusAccepted => '承認済み';

  @override
  String get statusReceiving => '受信中';

  @override
  String get statusCompleted => '完了';

  @override
  String get statusRejected => '拒否';

  @override
  String get statusFailed => '失敗';

  @override
  String get statusExpired => '期限切れ';

  @override
  String get meLabel => '自分';

  @override
  String get sendingBadge => '送信';

  @override
  String messageSendToRecipients(String names) {
    return '$names へ送信';
  }

  @override
  String recipientNDevices(int count) {
    return '$count 台';
  }

  @override
  String recipientTwo(String name1, String name2) {
    return '$name1、$name2';
  }

  @override
  String recipientMany(String name1, String name2, int total) {
    return '$name1、$name2 ほか $total 台';
  }

  @override
  String sendingPercent(String percent) {
    return '送信中 $percent%';
  }

  @override
  String receivingPercent(String percent) {
    return '受信中 $percent%';
  }

  @override
  String approxSpeed(String speed) {
    return '約 $speed';
  }

  @override
  String totalSizeLine(String size) {
    return '合計 $size';
  }

  @override
  String get shareRecordTitle => '共有';

  @override
  String get transferCompleted => '完了';

  @override
  String get transferInProgress => '転送中';

  @override
  String get transferEnded => '終了';

  @override
  String timeRemaining(String mm, String ss) {
    return '残り $mm:$ss';
  }

  @override
  String get receiverLabel => '受信者';

  @override
  String get shareAllReceivedHint => '相手がこの共有のファイルをすべて受信しました。';

  @override
  String get shareTransferringHint => '相手へ転送中です。このアプリを開いたまま、接続を維持してください。';

  @override
  String get shareWaitAcceptHint =>
      '相手がメッセージで「受信」するまで転送は始まりません。2分以内に承認がないとキャンセルされます。';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get copyAction => 'コピー';

  @override
  String get closeAction => '閉じる';

  @override
  String get cancelSharingAction => '共有をキャンセル';

  @override
  String processingPercent(String percent) {
    return '処理中… $percent%';
  }

  @override
  String get chooseAvatar => 'アバターを選択';

  @override
  String get newFolderDialogTitle => '新しいフォルダ';

  @override
  String get folderNameHint => 'フォルダ名';

  @override
  String get createFolderButton => '作成';

  @override
  String get folderNameEmpty => 'フォルダ名を入力してください';

  @override
  String get folderNameInvalidChars => '名前に / または \\ は使えません';

  @override
  String createFolderFailed(String error) {
    return '作成に失敗しました: $error';
  }

  @override
  String get rootDirectory => 'ルート';

  @override
  String get notificationIncomingTitle => '新しいファイルリクエスト';

  @override
  String notificationIncomingBody(String sender, String file) {
    return '$sender が送信中: $file';
  }

  @override
  String get notificationCompleteTitle => '受信完了';

  @override
  String notificationCompleteBody(String file, String sender) {
    return '$file（送信: $sender）';
  }

  @override
  String trayOpenApp(String appName) {
    return '$appName を開く';
  }

  @override
  String get trayQuit => '終了';

  @override
  String get showInFolder => 'フォルダで表示';

  @override
  String get signalingConnectFailed => 'シグナリングサーバーに接続できませんでした';

  @override
  String get signalingWaitTimeout => 'タイムアウトしました';

  @override
  String get webSocketError => 'WebSocket エラー';

  @override
  String get invalidPickupCode => '受け取りコードが無効です';
}
