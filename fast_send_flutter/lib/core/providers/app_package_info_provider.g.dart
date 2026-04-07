// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_package_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用版本与构建号，来自 [PackageInfo.fromPlatform]（与 [pubspec.yaml] 的 `version:` 一致）。

@ProviderFor(appPackageInfo)
final appPackageInfoProvider = AppPackageInfoProvider._();

/// 应用版本与构建号，来自 [PackageInfo.fromPlatform]（与 [pubspec.yaml] 的 `version:` 一致）。

final class AppPackageInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PackageInfo>,
          PackageInfo,
          FutureOr<PackageInfo>
        >
    with $FutureModifier<PackageInfo>, $FutureProvider<PackageInfo> {
  /// 应用版本与构建号，来自 [PackageInfo.fromPlatform]（与 [pubspec.yaml] 的 `version:` 一致）。
  AppPackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPackageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPackageInfoHash();

  @$internal
  @override
  $FutureProviderElement<PackageInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PackageInfo> create(Ref ref) {
    return appPackageInfo(ref);
  }
}

String _$appPackageInfoHash() => r'ff6c6abdeef608ccec50db28e92febef838b1a5d';
