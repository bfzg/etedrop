// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'EteDrop';

  @override
  String get home => '首页';

  @override
  String get send => '发送';

  @override
  String get receive => '接收';

  @override
  String get settings => '设置';

  @override
  String get cloud => '网盘';

  @override
  String get nearby => '附近';

  @override
  String get messages => '消息';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get storage => '存储';

  @override
  String get desktopIntegration => '桌面集成';

  @override
  String get appearance => '外观';

  @override
  String get about => '关于';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkForUpdatesDesc => '下载并安装最新版本';

  @override
  String get updateCheckFailed => '检查更新失败';

  @override
  String get updateAvailableTitle => '发现新版本';

  @override
  String updateAvailableBody(String current, String latest) {
    return '当前版本：$current\n最新版本：$latest';
  }

  @override
  String updateAlreadyLatest(String version) {
    return '已是最新版本（v$version）';
  }

  @override
  String get updateNow => '立即更新';

  @override
  String get later => '暂不更新';

  @override
  String get openLinkFailed => '打开链接失败';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '未连接';

  @override
  String get connect => '连接';

  @override
  String get deviceId => '设备 ID';

  @override
  String get editDeviceName => '修改设备名称';

  @override
  String get storagePath => '存储目录';

  @override
  String get notSet => '未设置';

  @override
  String get launchAtStartup => '开机自启';

  @override
  String get minimizeToTray => '关闭时最小化到托盘';

  @override
  String get minimizeToTrayDesc => '点击窗口关闭按钮时隐藏到系统托盘';

  @override
  String get darkMode => '深色模式';

  @override
  String get followSystem => '跟随系统';

  @override
  String get lightMode => '浅色模式';

  @override
  String get language => '语言';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get selectTheme => '选择主题';

  @override
  String get inputDeviceName => '设备名称';

  @override
  String get sendFile => '发送文件';

  @override
  String get selectFile => '选择文件';

  @override
  String get selectFileToSend => '选择要发送的文件';

  @override
  String get reselect => '重新选择';

  @override
  String get startSend => '开始发送';

  @override
  String get connecting => '正在连接...';

  @override
  String get waitingForReceiver => '等待接收方...';

  @override
  String get waitingForSender => '等待发送方...';

  @override
  String get pickupCode => '取件码';

  @override
  String get copied => '已复制';

  @override
  String get sending => '正在发送...';

  @override
  String get sendComplete => '发送完成！';

  @override
  String get sendNewFile => '发送新文件';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get receiveFile => '接收文件';

  @override
  String get inputPickupCode => '输入取件码';

  @override
  String get inputPickupCodeHint => '请输入取件码接收文件';

  @override
  String get startReceive => '开始接收';

  @override
  String get receiving => '正在接收...';

  @override
  String get receiveComplete => '接收完成！';

  @override
  String get saveFile => '保存文件';

  @override
  String get receiveNewFile => '接收新文件';

  @override
  String fileSaved(String path) {
    return '文件已保存到: $path';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String get langChineseSimplified => '简体中文';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get langKorean => '한국어';

  @override
  String get langSpanish => 'Español';

  @override
  String get nearbyDevices => '附近的设备';

  @override
  String selectedCount(int count) {
    return '已选 $count';
  }

  @override
  String get findingNearbyUsers => '正在查找用户...';

  @override
  String get lookingForNearbyDevices => '正在寻找附近的设备...';

  @override
  String get offline => '离线';

  @override
  String get weakSignal => '信号弱';

  @override
  String get youLabel => '你';

  @override
  String get emptyFolder => '空文件夹';

  @override
  String get shareAction => '分享';

  @override
  String get deleteAction => '删除';

  @override
  String get columnName => '名称';

  @override
  String get columnModified => '修改时间';

  @override
  String get columnSize => '大小';

  @override
  String get columnActions => '操作';

  @override
  String get shareTooltip => '分享';

  @override
  String get deleteTooltip => '删除';

  @override
  String get storagePreparingTitle => '正在准备存储目录';

  @override
  String get storagePreparingSubtitle => '手机端将自动使用应用专用目录保存文件';

  @override
  String get storageNotSetTitle => '尚未设置存储目录';

  @override
  String get storageNotSetSubtitle => '请选择一个文件夹作为网盘存储目录';

  @override
  String get chooseStorageFolder => '选择存储目录';

  @override
  String get loadFailed => '加载失败';

  @override
  String get openSystemSettingsForAccess => '打开系统设置授权';

  @override
  String get changeStorageDirectory => '更换存储目录';

  @override
  String get confirmDelete => '确认删除';

  @override
  String deleteEntryConfirm(String name, String suffix) {
    return '确定要删除 \"$name\" 吗？$suffix';
  }

  @override
  String get deleteFolderSuffix => '\n文件夹内所有内容将被删除。';

  @override
  String get newFolderTooltip => '新建文件夹';

  @override
  String get uploadFileTooltip => '上传文件';

  @override
  String get refreshTooltip => '刷新';

  @override
  String get cloudDirectoryLabel => '网盘目录';

  @override
  String get downloadDirectoryLabel => '下载目录';

  @override
  String clipboardImageSaveFailed(String error) {
    return '保存剪贴板图片失败: $error';
  }

  @override
  String get enterTextOrAddFiles => '请输入文字或添加至少一个文件';

  @override
  String get selectOnlineReceiversFirst => '请先在上方选择在线的接收设备';

  @override
  String sendFailed(String error) {
    return '发送失败: $error';
  }

  @override
  String get inputHintDesktop => '输入文字，⌘V 粘贴截图，或拖入文件…';

  @override
  String get inputHintMobile => '输入文字，或选择文件…';

  @override
  String get addFilesTooltip => '添加文件';

  @override
  String get sendButtonLabel => '发送';

  @override
  String get sendingButton => '发送中…';

  @override
  String get removeTooltip => '移除';

  @override
  String get shareScreenTitle => '分享';

  @override
  String get selectAtLeastOneReceiver => '请先在上方选择至少一个接收设备';

  @override
  String get shareInviteSentSnack => '已发送分享邀请，对方在消息里接受后开始传输';

  @override
  String get expireNever => '永不过期';

  @override
  String get expireOneHour => '1 小时';

  @override
  String get expireOneDay => '24 小时';

  @override
  String get expireSevenDays => '7 天';

  @override
  String get expireThirtyDays => '30 天';

  @override
  String get shareLinkCopied => '已复制分享链接';

  @override
  String createShareFailed(String error) {
    return '创建分享失败: $error';
  }

  @override
  String get cancelShareTitle => '取消分享';

  @override
  String get cancelShareBody => '确定取消分享？他人将无法再通过当前链接下载该文件。';

  @override
  String get backButton => '返回';

  @override
  String get cancelShareButton => '取消分享';

  @override
  String get shareCancelled => '已取消分享';

  @override
  String cancelShareFailed(String error) {
    return '取消分享失败: $error';
  }

  @override
  String shareLoadingTitle(String name) {
    return '分享「$name」';
  }

  @override
  String get closeButton => '关闭';

  @override
  String get createShareDialogTitle => '创建分享';

  @override
  String fileColon(String name) {
    return '文件: $name';
  }

  @override
  String get setPassword => '设置密码';

  @override
  String get enterPassword => '输入密码';

  @override
  String get shareCreatedTitle => '分享已创建';

  @override
  String get shareExistingDescription => '该文件已处于分享状态，可直接复制下方分享码或链接。';

  @override
  String get connectForShareLink => '请先连接设备（连接服务端）后，在「我的分享」中可查看分享链接。';

  @override
  String get passwordProtected => '已设置访问密码';

  @override
  String expiresAt(String when) {
    return '过期时间: $when';
  }

  @override
  String get doneButton => '完成';

  @override
  String get createShareAction => '创建分享';

  @override
  String get copyShareLinkTooltip => '复制分享链接';

  @override
  String get pickCloudStorageTitle => '选择网盘存储目录';

  @override
  String get pickDownloadDirTitle => '选择下载目录';

  @override
  String get messagePageTitle => '消息';

  @override
  String get clearMessagesTooltip => '清空';

  @override
  String get noMessagesYet => '暂无消息';

  @override
  String get noMessagesSubtitle => '当有设备向你发送文件时，会在这里显示';

  @override
  String get waitAcceptInMessage => '等待对方在消息内接受（2 分钟内有效）';

  @override
  String get retrySend => '重试发送';

  @override
  String get reject => '拒绝';

  @override
  String get receiveAction => '接收';

  @override
  String notifySenderFailed(String error) {
    return '无法通知发送方: $error';
  }

  @override
  String get fileNotFoundMaybeMoved => '找不到本地文件，可能已移动或删除';

  @override
  String get revealInFolderNotSupported => '当前平台无法在文件夹中定位文件';

  @override
  String get shareRestarted => '已重新发起分享';

  @override
  String get localFileGoneCannotRetry => '本地文件已不存在或已移动，无法重试';

  @override
  String retryFailed(String error) {
    return '重试失败: $error';
  }

  @override
  String get statusPending => '待处理';

  @override
  String get statusAccepted => '已接受';

  @override
  String get statusReceiving => '接收中';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusRejected => '已拒绝';

  @override
  String get statusFailed => '失败';

  @override
  String get statusExpired => '已过期';

  @override
  String get meLabel => '我';

  @override
  String get sendingBadge => '发送';

  @override
  String messageSendToRecipients(String names) {
    return '发给 $names';
  }

  @override
  String messageOutgoingHeaderLine(String names) {
    return '我发给 $names';
  }

  @override
  String recipientNDevices(int count) {
    return '$count 台设备';
  }

  @override
  String recipientTwo(String name1, String name2) {
    return '$name1、$name2';
  }

  @override
  String recipientMany(String name1, String name2, int total) {
    return '$name1、$name2 等 $total 台';
  }

  @override
  String sendingPercent(String percent) {
    return '发送中 $percent%';
  }

  @override
  String receivingPercent(String percent) {
    return '接收中 $percent%';
  }

  @override
  String approxSpeed(String speed) {
    return '约 $speed';
  }

  @override
  String totalSizeLine(String size) {
    return '合计 $size';
  }

  @override
  String get shareRecordTitle => '分享记录';

  @override
  String get transferCompleted => '已完成';

  @override
  String get transferInProgress => '传输中';

  @override
  String get transferEnded => '已结束';

  @override
  String timeRemaining(String mm, String ss) {
    return '剩余 $mm:$ss';
  }

  @override
  String get receiverLabel => '接收方';

  @override
  String get shareAllReceivedHint => '对方已成功接收本次分享的全部文件。';

  @override
  String get shareTransferringHint => '正在向对方设备传输文件，请保持本应用在前台或勿断网。';

  @override
  String get shareWaitAcceptHint => '对端需在消息里「接收」后才会开始传输；无人接受 2 分钟后自动取消。';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get copyAction => '复制';

  @override
  String get closeAction => '关闭';

  @override
  String get cancelSharingAction => '取消分享';

  @override
  String processingPercent(String percent) {
    return '正在处理... $percent%';
  }

  @override
  String get chooseAvatar => '选择头像';

  @override
  String get newFolderDialogTitle => '新建文件夹';

  @override
  String get folderNameHint => '文件夹名称';

  @override
  String get createFolderButton => '创建';

  @override
  String get folderNameEmpty => '请输入文件夹名称';

  @override
  String get folderNameInvalidChars => '文件夹名称不能包含 / 或 \\';

  @override
  String createFolderFailed(String error) {
    return '创建失败: $error';
  }

  @override
  String get rootDirectory => '根目录';

  @override
  String get notificationIncomingTitle => '收到新的文件请求';

  @override
  String notificationIncomingBody(String sender, String file) {
    return '$sender 正在发送：$file';
  }

  @override
  String get notificationCompleteTitle => '文件接收完成';

  @override
  String notificationCompleteBody(String file, String sender) {
    return '$file（来自 $sender）';
  }

  @override
  String trayOpenApp(String appName) {
    return '打开 $appName';
  }

  @override
  String get trayQuit => '退出';

  @override
  String get showInFolder => '在文件夹中显示';

  @override
  String get signalingConnectFailed => '连接信令服务器失败';

  @override
  String get signalingWaitTimeout => '等待超时';

  @override
  String get webSocketError => 'WebSocket 错误';

  @override
  String get invalidPickupCode => '取件码无效';
}
