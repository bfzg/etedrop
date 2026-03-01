// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 文件服务单例 Provider

@ProviderFor(FileServiceNotifier)
final fileServiceProvider = FileServiceNotifierProvider._();

/// 文件服务单例 Provider
final class FileServiceNotifierProvider
    extends $NotifierProvider<FileServiceNotifier, FileService> {
  /// 文件服务单例 Provider
  FileServiceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileServiceProvider',
        isAutoDispose: true,
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
    r'cc831252bccf0e5b62ad0933f281342257858736';

/// 文件服务单例 Provider

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

String _$cloudFileListHash() => r'd80b3906356bf6e5a061e3d91c5e1ad7d3c20b79';

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
