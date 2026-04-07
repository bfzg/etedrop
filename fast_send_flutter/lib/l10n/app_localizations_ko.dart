// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'EteDrop';

  @override
  String get home => '홈';

  @override
  String get send => '보내기';

  @override
  String get receive => '받기';

  @override
  String get settings => '설정';

  @override
  String get cloud => '클라우드';

  @override
  String get nearby => '주변';

  @override
  String get messages => '메시지';

  @override
  String get deviceInfo => '기기 정보';

  @override
  String get storage => '저장소';

  @override
  String get desktopIntegration => '데스크톱 연동';

  @override
  String get appearance => '모양';

  @override
  String get networkLine => '서버 경로';

  @override
  String get serverLineAuto => '자동';

  @override
  String get serverLineAutoDesc => '중국어(홍콩·대만·마카오 제외)는 대륙 노드, 그 외는 글로벌.';

  @override
  String get serverLineGlobal => '글로벌';

  @override
  String get serverLineGlobalDesc => 'api.etedrop.com';

  @override
  String get serverLineMainland => '중국 본토';

  @override
  String get serverLineMainlandDesc => 'api-cn.etedrop.com';

  @override
  String get about => '정보';

  @override
  String get checkForUpdates => '업데이트 확인';

  @override
  String get checkForUpdatesDesc => '최신 버전을 다운로드하여 설치';

  @override
  String get updateCheckFailed => '업데이트 확인에 실패했습니다';

  @override
  String get updateAvailableTitle => '업데이트가 있습니다';

  @override
  String updateAvailableBody(String current, String latest) {
    return '현재: $current\n최신: $latest';
  }

  @override
  String updateAlreadyLatest(String version) {
    return '최신 버전입니다 (v$version)';
  }

  @override
  String get updateNow => '업데이트';

  @override
  String get later => '나중에';

  @override
  String get openLinkFailed => '링크를 열 수 없습니다';

  @override
  String get connected => '연결됨';

  @override
  String get disconnected => '연결 안 됨';

  @override
  String get connect => '연결';

  @override
  String get deviceId => '기기 ID';

  @override
  String get editDeviceName => '기기 이름 편집';

  @override
  String get storagePath => '저장 경로';

  @override
  String get notSet => '설정 안 됨';

  @override
  String get launchAtStartup => '시작 시 실행';

  @override
  String get minimizeToTray => '트레이로 최소화';

  @override
  String get minimizeToTrayDesc => '닫을 때 창을 트레이로 숨깁니다';

  @override
  String get darkMode => '다크 모드';

  @override
  String get followSystem => '시스템 따르기';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get language => '언어';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get selectTheme => '테마 선택';

  @override
  String get inputDeviceName => '기기 이름';

  @override
  String get sendFile => '파일 보내기';

  @override
  String get selectFile => '파일 선택';

  @override
  String get selectFileToSend => '보낼 파일 선택';

  @override
  String get reselect => '다시 선택';

  @override
  String get startSend => '보내기 시작';

  @override
  String get connecting => '연결 중...';

  @override
  String get waitingForReceiver => '받는 쪽을 기다리는 중...';

  @override
  String get waitingForSender => '보내는 쪽을 기다리는 중...';

  @override
  String get pickupCode => '픽업 코드';

  @override
  String get copied => '복사됨';

  @override
  String get sending => '보내는 중...';

  @override
  String get sendComplete => '보내기 완료!';

  @override
  String get sendNewFile => '새 파일 보내기';

  @override
  String get error => '오류';

  @override
  String get retry => '다시 시도';

  @override
  String get receiveFile => '파일 받기';

  @override
  String get inputPickupCode => '픽업 코드 입력';

  @override
  String get inputPickupCodeHint => '픽업 코드를 입력하여 파일을 받으세요';

  @override
  String get startReceive => '받기 시작';

  @override
  String get receiving => '받는 중...';

  @override
  String get receiveComplete => '받기 완료!';

  @override
  String get saveFile => '파일 저장';

  @override
  String get receiveNewFile => '새 파일 받기';

  @override
  String fileSaved(String path) {
    return '파일이 저장되었습니다: $path';
  }

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get langChineseSimplified => '중국어(간체)';

  @override
  String get langEnglish => 'English';

  @override
  String get langJapanese => '日本語';

  @override
  String get langKorean => '한국어';

  @override
  String get langSpanish => 'Español';

  @override
  String get nearbyDevices => '주변 기기';

  @override
  String selectedCount(int count) {
    return '선택 $count개';
  }

  @override
  String get findingNearbyUsers => '사용자 검색 중...';

  @override
  String get lookingForNearbyDevices => '주변 기기를 찾는 중...';

  @override
  String get offline => '오프라인';

  @override
  String get weakSignal => '약한 신호';

  @override
  String get youLabel => '나';

  @override
  String get emptyFolder => '빈 폴더';

  @override
  String get shareAction => '공유';

  @override
  String get deleteAction => '삭제';

  @override
  String get columnName => '이름';

  @override
  String get columnModified => '수정됨';

  @override
  String get columnSize => '크기';

  @override
  String get columnActions => '작업';

  @override
  String get shareTooltip => '공유';

  @override
  String get deleteTooltip => '삭제';

  @override
  String get storagePreparingTitle => '저장소 준비 중';

  @override
  String get storagePreparingSubtitle => '이 기기의 앱 전용 폴더에 저장됩니다.';

  @override
  String get storageNotSetTitle => '저장 폴더가 없습니다';

  @override
  String get storageNotSetSubtitle => '클라우드로 사용할 폴더를 선택하세요.';

  @override
  String get chooseStorageFolder => '폴더 선택';

  @override
  String get loadFailed => '불러오기 실패';

  @override
  String get openSystemSettingsForAccess => '시스템 설정에서 액세스 허용';

  @override
  String get changeStorageDirectory => '저장 폴더 변경';

  @override
  String get confirmDelete => '삭제 확인';

  @override
  String deleteEntryConfirm(String name, String suffix) {
    return '\"$name\"을(를) 삭제할까요?$suffix';
  }

  @override
  String get deleteFolderSuffix => '\n폴더 안의 모든 내용이 삭제됩니다.';

  @override
  String get newFolderTooltip => '새 폴더';

  @override
  String get uploadFileTooltip => '파일 업로드';

  @override
  String get refreshTooltip => '새로 고침';

  @override
  String get cloudDirectoryLabel => '클라우드 폴더';

  @override
  String get downloadDirectoryLabel => '다운로드 폴더';

  @override
  String clipboardImageSaveFailed(String error) {
    return '클립보드 이미지를 저장하지 못했습니다: $error';
  }

  @override
  String get enterTextOrAddFiles => '텍스트를 입력하거나 파일을 하나 이상 추가하세요';

  @override
  String get selectOnlineReceiversFirst => '위에서 온라인 수신 기기를 먼저 선택하세요';

  @override
  String sendFailed(String error) {
    return '보내기 실패: $error';
  }

  @override
  String get inputHintDesktop => '텍스트 입력, ⌘V로 스크린샷 붙여넣기 또는 파일 끌어다 놓기…';

  @override
  String get inputHintMobile => '텍스트를 입력하거나 파일을 선택…';

  @override
  String get addFilesTooltip => '파일 추가';

  @override
  String get sendButtonLabel => '보내기';

  @override
  String get sendingButton => '보내는 중…';

  @override
  String get removeTooltip => '제거';

  @override
  String get shareScreenTitle => '공유';

  @override
  String get selectAtLeastOneReceiver => '위에서 수신 기기를 하나 이상 선택하세요';

  @override
  String get shareInviteSentSnack => '초대를 보냈습니다. 상대가 메시지에서 수락하면 전송이 시작됩니다.';

  @override
  String get expireNever => '만료 없음';

  @override
  String get expireOneHour => '1시간';

  @override
  String get expireOneDay => '24시간';

  @override
  String get expireSevenDays => '7일';

  @override
  String get expireThirtyDays => '30일';

  @override
  String get shareLinkCopied => '공유 링크가 복사되었습니다';

  @override
  String createShareFailed(String error) {
    return '공유를 만들 수 없습니다: $error';
  }

  @override
  String get cancelShareTitle => '공유 중지';

  @override
  String get cancelShareBody => '공유를 중지할까요? 이 링크로는 더 이상 다운로드할 수 없습니다.';

  @override
  String get backButton => '뒤로';

  @override
  String get cancelShareButton => '공유 중지';

  @override
  String get shareCancelled => '공유가 중지되었습니다';

  @override
  String cancelShareFailed(String error) {
    return '공유 중지 실패: $error';
  }

  @override
  String shareLoadingTitle(String name) {
    return '\"$name\" 공유';
  }

  @override
  String get closeButton => '닫기';

  @override
  String get createShareDialogTitle => '공유 만들기';

  @override
  String fileColon(String name) {
    return '파일: $name';
  }

  @override
  String get setPassword => '암호 보호';

  @override
  String get enterPassword => '암호 입력';

  @override
  String get shareCreatedTitle => '공유가 생성되었습니다';

  @override
  String get shareExistingDescription => '이 파일은 이미 공유 중입니다. 아래 코드나 링크를 복사하세요.';

  @override
  String get connectForShareLink => '서버에 연결한 뒤 「내 공유」에서 링크를 확인할 수 있습니다.';

  @override
  String get passwordProtected => '암호가 설정됨';

  @override
  String expiresAt(String when) {
    return '만료: $when';
  }

  @override
  String get doneButton => '완료';

  @override
  String get createShareAction => '공유 만들기';

  @override
  String get copyShareLinkTooltip => '공유 링크 복사';

  @override
  String get pickCloudStorageTitle => '클라우드 저장 폴더 선택';

  @override
  String get pickDownloadDirTitle => '다운로드 폴더 선택';

  @override
  String get messagePageTitle => '메시지';

  @override
  String get clearMessagesTooltip => '비우기';

  @override
  String get noMessagesYet => '메시지가 없습니다';

  @override
  String get noMessagesSubtitle => '다른 기기에서 파일을 보내면 여기에 표시됩니다.';

  @override
  String get waitAcceptInMessage => '상대가 메시지에서 수락할 때까지 대기(2분 유효)';

  @override
  String get retrySend => '다시 보내기';

  @override
  String get reject => '거절';

  @override
  String get receiveAction => '받기';

  @override
  String notifySenderFailed(String error) {
    return '보낸 사람에게 알릴 수 없습니다: $error';
  }

  @override
  String get fileNotFoundMaybeMoved => '로컬 파일을 찾을 수 없습니다. 이동되었거나 삭제되었을 수 있습니다.';

  @override
  String get revealInFolderNotSupported => '이 플랫폼에서는 폴더에서 표시할 수 없습니다.';

  @override
  String get shareRestarted => '공유를 다시 시작했습니다';

  @override
  String get localFileGoneCannotRetry => '로컬 파일이 없어 다시 시도할 수 없습니다.';

  @override
  String retryFailed(String error) {
    return '다시 시도 실패: $error';
  }

  @override
  String get statusPending => '대기 중';

  @override
  String get statusAccepted => '수락됨';

  @override
  String get statusReceiving => '받는 중';

  @override
  String get statusCompleted => '완료';

  @override
  String get statusRejected => '거절됨';

  @override
  String get statusFailed => '실패';

  @override
  String get statusExpired => '만료됨';

  @override
  String get meLabel => '나';

  @override
  String get sendingBadge => '보내기';

  @override
  String messageSendToRecipients(String names) {
    return '$names(으)로 보내기';
  }

  @override
  String messageOutgoingHeaderLine(String names) {
    return '나 → $names(으)로 보내기';
  }

  @override
  String recipientNDevices(int count) {
    return '기기 $count대';
  }

  @override
  String recipientTwo(String name1, String name2) {
    return '$name1, $name2';
  }

  @override
  String recipientMany(String name1, String name2, int total) {
    return '$name1, $name2 등 $total대';
  }

  @override
  String sendingPercent(String percent) {
    return '보내는 중 $percent%';
  }

  @override
  String receivingPercent(String percent) {
    return '받는 중 $percent%';
  }

  @override
  String approxSpeed(String speed) {
    return '약 $speed';
  }

  @override
  String totalSizeLine(String size) {
    return '합계 $size';
  }

  @override
  String get shareRecordTitle => '공유';

  @override
  String get transferCompleted => '완료';

  @override
  String get transferInProgress => '전송 중';

  @override
  String get transferEnded => '종료됨';

  @override
  String timeRemaining(String mm, String ss) {
    return '남음 $mm:$ss';
  }

  @override
  String get receiverLabel => '받는 사람';

  @override
  String get shareAllReceivedHint => '상대가 이번 공유의 모든 파일을 받았습니다.';

  @override
  String get shareTransferringHint => '상대 기기로 전송 중입니다. 앱을 켜 두고 연결을 유지하세요.';

  @override
  String get shareWaitAcceptHint =>
      '상대가 메시지에서 「받기」를 눌러야 전송이 시작됩니다. 2분 안에 수락이 없으면 취소됩니다.';

  @override
  String get copiedToClipboard => '클립보드에 복사했습니다';

  @override
  String get copyAction => '복사';

  @override
  String get closeAction => '닫기';

  @override
  String get cancelSharingAction => '공유 취소';

  @override
  String processingPercent(String percent) {
    return '처리 중… $percent%';
  }

  @override
  String get chooseAvatar => '아바타 선택';

  @override
  String get newFolderDialogTitle => '새 폴더';

  @override
  String get folderNameHint => '폴더 이름';

  @override
  String get createFolderButton => '만들기';

  @override
  String get folderNameEmpty => '폴더 이름을 입력하세요';

  @override
  String get folderNameInvalidChars => '이름에 / 또는 \\ 를 사용할 수 없습니다';

  @override
  String createFolderFailed(String error) {
    return '만들기 실패: $error';
  }

  @override
  String get rootDirectory => '루트';

  @override
  String get notificationIncomingTitle => '새 파일 요청';

  @override
  String notificationIncomingBody(String sender, String file) {
    return '$sender 님이 보내는 중: $file';
  }

  @override
  String get notificationCompleteTitle => '받기 완료';

  @override
  String notificationCompleteBody(String file, String sender) {
    return '$file($sender에서)';
  }

  @override
  String trayOpenApp(String appName) {
    return '$appName 열기';
  }

  @override
  String get trayQuit => '종료';

  @override
  String get showInFolder => '폴더에서 표시';

  @override
  String get signalingConnectFailed => '시그널링 서버에 연결할 수 없습니다';

  @override
  String get signalingWaitTimeout => '시간 초과';

  @override
  String get webSocketError => 'WebSocket 오류';

  @override
  String get invalidPickupCode => '픽업 코드가 올바르지 않습니다';

  @override
  String get transferReceiveSection => '전송';

  @override
  String get transferAutoReceiveTitle => '공유 자동 수락';

  @override
  String get transferAutoReceiveSubtitle =>
      '켜면 LAN 공유가 메시지에서 수신을 누르지 않고 시작합니다. 기본값은 꺼짐.';

  @override
  String get transferAutoReceivingHint =>
      '자동 수락이 켜져 있습니다. 연결 후 백그라운드에서 수신 중입니다.';

  @override
  String get webrtcBackgroundKeepaliveSection => 'Background';

  @override
  String get webrtcBackgroundKeepaliveTitle =>
      'Keep transfer alive in background';

  @override
  String get webrtcBackgroundKeepaliveSubtitle =>
      'When on, the app tries to keep the LAN WebRTC session while in background. Android shows a notification and may request the microphone for foreground service types. iOS uses audio/voIP-related background modes. System limits still apply.';

  @override
  String get webrtcBackgroundFgNotificationTitle => 'Keeping transfer active';

  @override
  String get webrtcBackgroundFgNotificationBody => 'Tap to return to the app';

  @override
  String get webrtcBackgroundKeepaliveEnableFailed =>
      'Could not enable background keep-alive. Allow notification and microphone access, then try again.';
}
