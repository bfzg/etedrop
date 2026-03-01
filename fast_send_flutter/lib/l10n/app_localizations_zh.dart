// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '极速快传';

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
}
