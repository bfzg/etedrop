// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 文件服务单例 Provider
///
/// keepAlive：避免 autoDispose 在首屏仅被 `ref.read`（如 LanManager 初始化）后释放，
/// 与网盘列表异步扫描竞态，表现为长时间加载后误报无权限；设置里重选同一路径会新建实例因而「立刻好」。

@ProviderFor(FileServiceNotifier)
final fileServiceProvider = FileServiceNotifierProvider._();

/// 文件服务单例 Provider
///
/// keepAlive：避免 autoDispose 在首屏仅被 `ref.read`（如 LanManager 初始化）后释放，
/// 与网盘列表异步扫描竞态，表现为长时间加载后误报无权限；设置里重选同一路径会新建实例因而「立刻好」。
final class FileServiceNotifierProvider
    extends $NotifierProvider<FileServiceNotifier, FileService> {
  /// 文件服务单例 Provider
  ///
  /// keepAlive：避免 autoDispose 在首屏仅被 `ref.read`（如 LanManager 初始化）后释放，
  /// 与网盘列表异步扫描竞态，表现为长时间加载后误报无权限；设置里重选同一路径会新建实例因而「立刻好」。
  FileServiceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileServiceNotifierHash();

  @$internal
  @override
  FileServiceNotifier create() => FileServiceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileService>(value),
    );
  }
}

String _$fileServiceNotifierHash() =>
    r'4f4c741e58e351c23a8737a57a7d1ddfd435a5e1';

/// 文件服务单例 Provider
///
/// keepAlive：避免 autoDispose 在首屏仅被 `ref.read`（如 LanManager 初始化）后释放，
/// 与网盘列表异步扫描竞态，表现为长时间加载后误报无权限；设置里重选同一路径会新建实例因而「立刻好」。

abstract class _$FileServiceNotifier extends $Notifier<FileService> {
  FileService build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FileService, FileService>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FileService, FileService>,
              FileService,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 下载目录（用于接收文件保存位置）

@ProviderFor(DownloadDir)
final downloadDirProvider = DownloadDirProvider._();

/// 下载目录（用于接收文件保存位置）
final class DownloadDirProvider
    extends $AsyncNotifierProvider<DownloadDir, String> {
  /// 下载目录（用于接收文件保存位置）
  DownloadDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadDirProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadDirHash();

  @$internal
  @override
  DownloadDir create() => DownloadDir();
}

String _$downloadDirHash() => r'09ad6849b7ae038f30577ded36435847a621e63d';

/// 下载目录（用于接收文件保存位置）

abstract class _$DownloadDir extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 当前浏览路径状态

@ProviderFor(CurrentPath)
final currentPathProvider = CurrentPathProvider._();

/// 当前浏览路径状态
final class CurrentPathProvider extends $NotifierProvider<CurrentPath, String> {
  /// 当前浏览路径状态
  CurrentPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPathHash();

  @$internal
  @override
  CurrentPath create() => CurrentPath();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentPathHash() => r'3b7f0d919ef7ddccc34f4808505891b8524fb4e4';

/// 当前浏览路径状态

abstract class _$CurrentPath extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 文件列表状态

@ProviderFor(CloudFileList)
final cloudFileListProvider = CloudFileListProvider._();

/// 文件列表状态
final class CloudFileListProvider
    extends $AsyncNotifierProvider<CloudFileList, List<FsEntry>> {
  /// 文件列表状态
  CloudFileListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudFileListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudFileListHash();

  @$internal
  @override
  CloudFileList create() => CloudFileList();
}

String _$cloudFileListHash() => r'ab98104703ce492c01d51e7d9b2c229dfb184006';

/// 文件列表状态

abstract class _$CloudFileList extends $AsyncNotifier<List<FsEntry>> {
  FutureOr<List<FsEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<FsEntry>>, List<FsEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FsEntry>>, List<FsEntry>>,
              AsyncValue<List<FsEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 存储目录是否已设置

@ProviderFor(hasStorageDir)
final hasStorageDirProvider = HasStorageDirProvider._();

/// 存储目录是否已设置

final class HasStorageDirProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 存储目录是否已设置
  HasStorageDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasStorageDirProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasStorageDirHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasStorageDir(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasStorageDirHash() => r'0252ca0383bc625f7e246bbbc02918c38f62c4ab';

/// 获取存储目录路径

@ProviderFor(storageDirPath)
final storageDirPathProvider = StorageDirPathProvider._();

/// 获取存储目录路径

final class StorageDirPathProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 获取存储目录路径
  StorageDirPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageDirPathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageDirPathHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return storageDirPath(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$storageDirPathHash() => r'65f7c771f6a1df7f1aaaacb7ba179f4655537b2f';

/// 面包屑路径段

@ProviderFor(breadcrumbSegments)
final breadcrumbSegmentsProvider = BreadcrumbSegmentsProvider._();

/// 面包屑路径段

final class BreadcrumbSegmentsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// 面包屑路径段
  BreadcrumbSegmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'breadcrumbSegmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$breadcrumbSegmentsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return breadcrumbSegments(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$breadcrumbSegmentsHash() =>
    r'bdccb811b22f7bd2ecbed10ed0526608bc6c1fbe';
