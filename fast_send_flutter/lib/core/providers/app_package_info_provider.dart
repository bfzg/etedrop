import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_package_info_provider.g.dart';

/// 应用版本与构建号，来自 [PackageInfo.fromPlatform]（与 [pubspec.yaml] 的 `version:` 一致）。
@Riverpod(keepAlive: true)
Future<PackageInfo> appPackageInfo(Ref ref) async {
  return PackageInfo.fromPlatform();
}
