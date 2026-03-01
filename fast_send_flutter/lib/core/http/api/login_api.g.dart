// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loginApi)
final loginApiProvider = LoginApiProvider._();

final class LoginApiProvider
    extends $FunctionalProvider<LoginApi, LoginApi, LoginApi>
    with $Provider<LoginApi> {
  LoginApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginApiHash();

  @$internal
  @override
  $ProviderElement<LoginApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoginApi create(Ref ref) {
    return loginApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoginApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoginApi>(value),
    );
  }
}

String _$loginApiHash() => r'57f8401a7b9068c3d245fc5be659be8aa0c0dc8b';
