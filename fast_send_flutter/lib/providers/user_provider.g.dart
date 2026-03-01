// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserState)
final userStateProvider = UserStateProvider._();

final class UserStateProvider
    extends $AsyncNotifierProvider<UserState, LoginResponse?> {
  UserStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStateHash();

  @$internal
  @override
  UserState create() => UserState();
}

String _$userStateHash() => r'4881d2853ca7fa52f386b55c0cfc83124e7a91f7';

abstract class _$UserState extends $AsyncNotifier<LoginResponse?> {
  FutureOr<LoginResponse?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LoginResponse?>, LoginResponse?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LoginResponse?>, LoginResponse?>,
              AsyncValue<LoginResponse?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
